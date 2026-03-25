import 'dart:async';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_notifier.dart';
import '../../../training/presentation/providers/training_analytics_provider.dart';
import '../../../training/presentation/providers/workout_notifier.dart';
import '../../data/repositories/chiron_providers.dart';
import '../../domain/entities/chiron_message.dart';
import 'chiron_chat_state.dart';

part 'chiron_notifier.g.dart';

const _chironDebugTrace = bool.fromEnvironment('CHIRON_DEBUG_TRACE');

@riverpod
class ChironNotifier extends _$ChironNotifier {
  @override
  ChironChatState build() => const ChironChatState();

  Future<void> send(String userMessage) async {
    if (userMessage.trim().isEmpty || state.isStreaming) return;

    _trace('send:start messageLength=${userMessage.trim().length}');

    final toolFeedback = <ChironToolFeedback>[];
    int? createdWorkoutId;

    final userMsg = ChironMessage(
      role: ChironRole.user,
      content: userMessage.trim(),
      createdAt: DateTime.now(),
    );

    final assistantMsg = ChironMessage(
      role: ChironRole.assistant,
      content: '',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isStreaming: true,
      lastResponseToolFeedback: [],
      clearCreatedWorkoutId: true,
    );

    try {
      final repository = ref.read(chironRepositoryProvider);
      final stream = repository.sendMessage(
        userMessage: userMessage.trim(),
        history: state.messages.where((m) => m.content.isNotEmpty).toList()
          ..removeLast(),
        onToolInvoked: (toolName, success, resultData) {
          _trace(
            'tool:$toolName success=$success hasResult=${resultData != null}',
          );
          toolFeedback.add(
            ChironToolFeedback(toolName: toolName, success: success),
          );
          if (toolName == 'createWorkout' &&
              success &&
              resultData != null &&
              resultData['workoutId'] != null) {
            final id = resultData['workoutId'];
            createdWorkoutId = id is int ? id : int.tryParse(id.toString());
          }
        },
      );

      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        final updated = List<ChironMessage>.from(state.messages);
        updated[updated.length - 1] = updated.last.copyWith(
          content: buffer.toString(),
        );
        state = state.copyWith(messages: updated);
      }

      if (buffer.isNotEmpty) {
        _applyAssistantMessageBlocks(buffer.toString());
      } else {
        _trace('send:emptyResponse workoutCreated=${createdWorkoutId != null}');
        final l10n = _resolveL10n();
        final fallback = createdWorkoutId != null
            ? l10n.chironWorkoutCreatedFallback
            : l10n.chironEmptyResponse;
        final updated = List<ChironMessage>.from(state.messages);
        updated[updated.length - 1] = updated.last.copyWith(content: fallback);
        state = state.copyWith(messages: updated);
      }
    } on Exception catch (e, stackTrace) {
      _trace('send:error $e');
      if (_chironDebugTrace) {
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[ChironDebugTrace] stackTrace',
        );
      }
      final updated = List<ChironMessage>.from(state.messages);
      final String errorText = _errorMessage(e, _resolveL10n());
      updated[updated.length - 1] = updated.last.copyWith(content: errorText);
      state = state.copyWith(messages: updated);
    } finally {
      _trace(
        'send:finish tools=${toolFeedback.length} workoutId=$createdWorkoutId',
      );
      state = state.copyWith(
        isStreaming: false,
        lastResponseToolFeedback: toolFeedback,
        lastCreatedWorkoutId: createdWorkoutId,
      );
      // Refresh profile and training data in case function calling updated them
      ref.invalidate(profileProvider);
      ref.invalidate(workoutListProvider);
      ref.invalidate(archivedWorkoutListProvider);
      ref.invalidate(cycleStepsProvider);
    }
  }

  void clear() => state = const ChironChatState();

  /// Call after navigating to the created workout so we don't navigate again.
  void clearCreatedWorkoutId() {
    state = state.copyWith(clearCreatedWorkoutId: true);
  }

  static AppLocalizations _resolveL10n() {
    final appLocale = PlatformDispatcher.instance.locale;
    final isSupported = AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == appLocale.languageCode,
    );
    final locale = isSupported ? appLocale : const Locale('pt');
    return lookupAppLocalizations(locale);
  }

  static String _errorMessage(Exception e, AppLocalizations l10n) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('rate limit') || msg.contains('quota')) {
      return l10n.chironErrorRateLimit;
    }
    if (msg.contains('503') || msg.contains('high demand')) {
      return l10n.chironErrorHighDemand;
    }
    return l10n.chironErrorGeneric;
  }

  static void _trace(String message) {
    if (!_chironDebugTrace) return;
    debugPrint('[ChironDebugTrace] $message');
  }

  void _applyAssistantMessageBlocks(String fullText) {
    final blocks = _splitAssistantReply(fullText);
    if (blocks.isEmpty) return;

    final updated = List<ChironMessage>.from(state.messages);
    if (updated.isEmpty || updated.last.role != ChironRole.assistant) return;
    updated.removeLast();

    final baseTime = DateTime.now();
    for (var i = 0; i < blocks.length; i++) {
      updated.add(
        ChironMessage(
          role: ChironRole.assistant,
          content: blocks[i],
          createdAt: baseTime.add(Duration(milliseconds: i)),
        ),
      );
    }
    state = state.copyWith(messages: updated);
  }

  static List<String> _splitAssistantReply(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return const [];

    final paragraphBlocks = normalized
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphBlocks.isEmpty) return const [];

    final output = <String>[];
    for (final block in paragraphBlocks) {
      final looksLikeList = block.startsWith('- ') || block.contains('\n- ');
      if (looksLikeList || block.length <= 200) {
        output.add(block);
        continue;
      }

      final sentences = block
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (sentences.isEmpty) {
        output.add(block);
        continue;
      }

      final chunk = StringBuffer();
      var sentenceCount = 0;
      for (final sentence in sentences) {
        final shouldFlush =
            chunk.isNotEmpty &&
            (chunk.length + sentence.length + 1 > 170 || sentenceCount >= 2);
        if (shouldFlush) {
          output.add(chunk.toString().trim());
          chunk.clear();
          sentenceCount = 0;
        }
        if (chunk.isNotEmpty) chunk.write(' ');
        chunk.write(sentence);
        sentenceCount++;
      }
      if (chunk.isNotEmpty) {
        output.add(chunk.toString().trim());
      }
    }
    return output;
  }
}
