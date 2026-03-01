import '../entities/chiron_message.dart';

/// Callback when a tool is invoked during a response. [resultData] contains
/// the tool return (e.g. workoutId for createWorkout).
typedef ChironToolInvokedCallback = void Function(
  String toolName,
  bool success,
  Map<String, dynamic>? resultData,
);

abstract interface class ChironRepository {
  Stream<String> sendMessage({
    required String userMessage,
    required List<ChironMessage> history,
    required String userContext,
    ChironToolInvokedCallback? onToolInvoked,
  });
}
