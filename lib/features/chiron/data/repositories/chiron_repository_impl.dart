import 'dart:async';

import '../../../../core/errors/result.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/enums/experience_level.dart';
import '../../../profile/domain/enums/gender.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../../training/domain/entities/cycle_step.dart';
import '../../../training/domain/entities/workout.dart' as domain_workout;
import '../../../training/domain/entities/workout_exercise.dart' as domain_we;
import '../../../training/domain/repositories/cycle_repository.dart';
import '../../../training/domain/repositories/equipment_repository.dart';
import '../../../training/domain/repositories/exercise_repository.dart';
import '../../../training/domain/repositories/workout_repository.dart';
import '../../domain/entities/chiron_message.dart';
import '../../domain/repositories/chiron_repository.dart';
import '../services/gemini_models_loader.dart';
import '../services/gemini_rest_client.dart';

/// Fallback when the API list is unavailable. Use only "-latest" aliases
/// so Google can change the underlying version without app updates.
const List<String> _geminiModelIdsFallback = [
  'gemini-flash-latest',
  'gemini-1.5-flash-latest',
  'gemini-1.5-flash-8b-latest',
];

class ChironRepositoryImpl implements ChironRepository {
  ChironRepositoryImpl({
    required String apiKey,
    required UserProfileRepository profileRepo,
    required EquipmentRepository equipmentRepo,
    required WorkoutRepository workoutRepo,
    required ExerciseRepository exerciseRepo,
    required CycleRepository cycleRepo,
    GeminiModelsLoader? modelsLoader,
  })  : _profileRepo = profileRepo,
        _equipmentRepo = equipmentRepo,
        _workoutRepo = workoutRepo,
        _exerciseRepo = exerciseRepo,
        _cycleRepo = cycleRepo,
        _modelsLoader = modelsLoader ?? GeminiModelsLoader(apiKey: apiKey),
        _restClient = GeminiRestClient(apiKey: apiKey);

  final UserProfileRepository _profileRepo;
  final GeminiRestClient _restClient;
  final EquipmentRepository _equipmentRepo;
  final WorkoutRepository _workoutRepo;
  final ExerciseRepository _exerciseRepo;
  final CycleRepository _cycleRepo;
  final GeminiModelsLoader _modelsLoader;

  static const _maxMessagesPerMinute = 10;
  /// Max conversation turns (user+assistant pairs) sent to the API to save tokens.
  static const int _maxHistoryTurns = 12;
  final _timestamps = <DateTime>[];

  static const _systemPrompt = r'''Tu és o Quíron (Chiron), assistente de treino com IA no Athlos. Persona: centauro mentor, conciso e motivacional.

Regras:
- Respostas em português do Brasil. Foco em treino, exercícios, nutrição básica e recuperação. Sem conselhos médicos — recomendar profissional quando apropriado. Markdown quando útil.

Perfil em falta: Se gender, injuries, experienceLevel ou trainingFrequency estiverem vazios no contexto, pergunta de forma natural e usa as funções para guardar. Não interrogatório. Bio: enriquece ao longo da conversa com updateBio (concatenar, nunca apagar).

Gênero e treino: female — prioridade pernas/glúteos e volume proporcional; male — splits clássicos (push/pull/legs etc.). Estética (athletic/bulky/robust) adapta conforme gênero.

Equipamentos: Ao montar treino, usa só equipamentos registados. Se precisares de um não listado, pergunta "Tem [X]?"; se sim, registerEquipment e inclui; se não, sugere alternativa. Lesões: updateInjuries para acrescentar (concatenar "; ").

Progresso: Usa o histórico de execuções para sugerir troca de treino, progressões e descanso. Compara pesos/reps entre sessões.

Treinos — nunca excluir: Não tens função para excluir treinos. Só podes criar (createWorkout) e arquivar (archiveWorkout). Para substituir um plano: cria o novo treino e depois arquiva o(s) antigo(s) com archiveWorkout(workoutId). O contexto lista treinos ativos com id=X; usa esse id ao arquivar.

Ciclo (rotina): Após criar novos treinos e arquivar os antigos, deves definir o ciclo com setCycle(steps). steps é uma lista ordenada: cada item é { type: "workout", workoutId: N } ou { type: "rest" }. Inclui só workoutIds de treinos ativos (os que acabaste de criar ou que ficaram). Exemplo: [ { type: "workout", workoutId: 5 }, { type: "rest" }, { type: "workout", workoutId: 6 } ]. Isto persiste a rotina e evita versões antigas ficarem ativas.

Revisão final: Depois de aplicar todas as alterações (criar, arquivar, setCycle), chama getTrainingState(). Compara o retorno (activeWorkouts e cycleSteps) com o que pretendias. Se estiver correto, confirma ao utilizador que tudo foi aplicado. Se algo estiver diferente (ex.: treino antigo ainda ativo, ciclo desatualizado), informa o que falhou e sugere verificar no módulo Treino.

Tempo disponível: Se o contexto indicar "Tempo disponível por treino: X min", monta treinos que cabem nesse tempo (estimativa: séries × (reps ou duração) + descansos). Não sugiras treinos que excedam esse tempo.

Dois cenários:
1) Utilizador sem treinos ativos: foca em montar o primeiro plano. createWorkout com name e exercises (exerciseName, sets, reps, restSeconds). Depois setCycle com o(s) treino(s) criado(s). Por fim getTrainingState e confirma ao utilizador.
2) Utilizador com treinos ativos: analisa o plano atual, as sessões e progressões. Diz se faz sentido continuar, acrescentar, substituir ou modificar treino/ciclo. Se sugerires substituir: createWorkout para o novo, archiveWorkout para o(s) antigo(s), setCycle com a nova ordem (só treinos ativos + descansos), getTrainingState e revisa se está tudo certo.

Uso de funções: createWorkout e archiveWorkout conforme acima; setCycle após alterar treinos; getTrainingState no final para revisar. updateBio, updateInjuries, updateExperienceLevel, updateGender, updateTrainingFrequency quando tiveres informação concreta; agrupa se possível. registerEquipment/removeEquipment quando o utilizador confirmar.
''';

  @override
  Stream<String> sendMessage({
    required String userMessage,
    required List<ChironMessage> history,
    required String userContext,
    ChironToolInvokedCallback? onToolInvoked,
  }) async* {
    _enforceRateLimit();

    final maxHistoryMessages = _maxHistoryTurns * 2;
    final trimmedHistory = history.length > maxHistoryMessages
        ? history.sublist(history.length - maxHistoryMessages)
        : history;

    final modelIds =
        await _modelsLoader.getModelIdsForChat() ?? _geminiModelIdsFallback;

    Object? lastError;
    for (final modelId in modelIds) {
      try {
        await for (final chunk in _sendWithGeminiModel(
          modelId: modelId,
          userMessage: userMessage,
          history: trimmedHistory,
          userContext: userContext,
          onToolInvoked: onToolInvoked,
        )) {
          yield chunk;
        }
        return;
      } catch (e) {
        lastError = e;
        if (!_isQuotaOrRateLimit(e)) rethrow;
      }
    }
    if (lastError != null) {
      if (lastError is Exception) throw lastError;
      throw Exception(lastError.toString());
    }
  }

  /// Returns true if the exception indicates quota or rate limit (try next model).
  static bool _isQuotaOrRateLimit(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('quota') ||
        s.contains('rate limit') ||
        s.contains('resource_exhausted');
  }

  /// Sends the message using a single Gemini model via REST (supports
  /// thought_signature for thinking models). May throw on API errors.
  Stream<String> _sendWithGeminiModel({
    required String modelId,
    required String userMessage,
    required List<ChironMessage> history,
    required String userContext,
    ChironToolInvokedCallback? onToolInvoked,
  }) async* {
    final systemInstruction = '$_systemPrompt\n\n$userContext';
    final toolDeclarations = getChironToolDeclarations();

    var contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      final role = msg.role == ChironRole.user ? 'user' : 'model';
      contents.add({
        'role': role,
        'parts': [
          {'text': msg.content}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    var parse = GeminiResponseParse(text: '');
    var createWorkoutSucceededThisTurn = false;

    while (true) {
      final responseJson = await _restClient.generateContent(
        modelId: modelId,
        contents: contents,
        systemInstruction: systemInstruction,
        toolDeclarations: toolDeclarations,
      );

      parse = parseGenerateContentResponse(responseJson);

      if (parse.functionCalls.isEmpty) {
        break;
      }

      final nameToResponse = <MapEntry<String, Map<String, Object?>>>[];
      for (final call in parse.functionCalls) {
        final result = await _handleFunctionCallByName(call.name, call.args);
        if (call.name == 'createWorkout' && result['success'] == true) {
          createWorkoutSucceededThisTurn = true;
        }
        nameToResponse.add(MapEntry(call.name, result));
        final success = result['success'] == true;
        onToolInvoked?.call(
          call.name,
          success,
          result.map((k, v) => MapEntry(k.toString(), v)),
        );
      }

      contents = List<Map<String, dynamic>>.from(contents);
      contents.add({
        'role': 'model',
        'parts': parse.modelParts,
      });
      contents.add({
        'role': 'user',
        'parts': buildFunctionResponseParts(
          thoughtSignature: parse.thoughtSignature,
          nameToResponse: nameToResponse,
        ),
      });
    }

    final text = parse.text;
    if (text != null && text.isNotEmpty) {
      yield text;
    } else if (createWorkoutSucceededThisTurn) {
      yield 'Treino criado e salvo no seu perfil. Confira no módulo Treino.';
    }
  }

  Future<Map<String, Object?>> _handleFunctionCallByName(
    String name,
    Map<String, dynamic> args,
  ) async {
    switch (name) {
      case 'updateBio':
        return _handleUpdateBio(args['bio'] as String);
      case 'updateInjuries':
        return _handleUpdateInjuries(args['injuries'] as String);
      case 'updateExperienceLevel':
        return _handleUpdateExperienceLevel(args['level'] as String);
      case 'updateTrainingFrequency':
        final days = args['daysPerWeek'];
        return _handleUpdateTrainingFrequency(
          days is int ? days : int.parse(days.toString()),
        );
      case 'updateGender':
        return _handleUpdateGender(args['gender'] as String);
      case 'registerEquipment':
        return _handleRegisterEquipment(args['equipmentName'] as String);
      case 'removeEquipment':
        return _handleRemoveEquipment(args['equipmentName'] as String);
      case 'createWorkout':
        return _handleCreateWorkout(
          args['name']?.toString() ?? '',
          args['description']?.toString(),
          args['exercises'] is List ? args['exercises'] as List? : null,
        );
      case 'archiveWorkout':
        return _handleArchiveWorkout(
          args['workoutId'] != null
              ? (args['workoutId'] is int
                  ? args['workoutId'] as int
                  : int.tryParse(args['workoutId'].toString()))
              : null,
        );
      case 'setCycle':
        return _handleSetCycle(
          args['steps'] is List ? args['steps'] as List? : null,
        );
      case 'getTrainingState':
        return _handleGetTrainingState();
      default:
        return {'success': false, 'error': 'Unknown function: $name'};
    }
  }

  Future<Map<String, Object?>> _handleCreateWorkout(
    String name,
    String? description,
    List? exercisesList,
  ) async {
    if (name.trim().isEmpty) {
      return {'success': false, 'error': 'Nome do treino é obrigatório'};
    }
    if (exercisesList == null || exercisesList.isEmpty) {
      return {'success': false, 'error': 'O treino precisa de pelo menos um exercício'};
    }

    final workoutExercises = <domain_we.WorkoutExercise>[];
    for (var i = 0; i < exercisesList.length; i++) {
      final item = exercisesList[i];
      if (item is! Map) continue;
      final map = item;
      final exerciseName = map['exerciseName']?.toString().trim();
      if (exerciseName == null || exerciseName.isEmpty) continue;

      final sets = _parseInt(map['sets'], 3);
      final reps = map['reps'] != null ? _parseInt(map['reps'], 10) : null;
      final restSeconds = map['restSeconds'] != null
          ? _parseInt(map['restSeconds'], 90)
          : 90;
      final durationSeconds =
          map['durationSeconds'] != null ? _parseInt(map['durationSeconds'], 0) : null;
      final notes = map['notes']?.toString().trim();

      final exResult = await _exerciseRepo.findByName(exerciseName);
      if (!exResult.isSuccess) {
        return {
          'success': false,
          'error': 'Erro ao buscar exercício "$exerciseName"',
        };
      }
      final exercise = exResult.getOrThrow();
      if (exercise == null) {
        return {
          'success': false,
          'error': 'Exercício não encontrado no catálogo: "$exerciseName". '
              'Use o nome exato do exercício.',
        };
      }

      workoutExercises.add(
        domain_we.WorkoutExercise(
          workoutId: 0,
          exerciseId: exercise.id,
          order: i,
          sets: sets,
          reps: reps,
          rest: restSeconds,
          duration: durationSeconds,
          groupId: null,
          notes: (notes != null && notes.isNotEmpty) ? notes : null,
        ),
      );
    }

    if (workoutExercises.isEmpty) {
      return {'success': false, 'error': 'Nenhum exercício válido para criar o treino'};
    }

    final workout = domain_workout.Workout(
      id: 0,
      name: name.trim(),
      description: description?.trim().isEmpty ?? true ? null : description?.trim(),
      createdAt: DateTime.now(),
    );

    final result = await _workoutRepo.create(workout, workoutExercises);
    if (!result.isSuccess) {
      return {'success': false, 'error': 'Falha ao salvar o treino'};
    }

    final id = result.getOrThrow();
    final cycleResult = await _cycleRepo.appendWorkoutToCycle(id);
    if (!cycleResult.isSuccess) {
      return {
        'success': true,
        'workoutId': id,
        'workoutName': workout.name,
        'exerciseCount': workoutExercises.length,
        'warning': 'Treino criado mas falha ao adicionar ao ciclo',
      };
    }
    return {
      'success': true,
      'workoutId': id,
      'workoutName': workout.name,
      'exerciseCount': workoutExercises.length,
    };
  }

  Future<Map<String, Object?>> _handleArchiveWorkout(int? workoutId) async {
    if (workoutId == null || workoutId <= 0) {
      return {'success': false, 'error': 'workoutId inválido'};
    }
    final result = await _workoutRepo.archive(workoutId);
    if (!result.isSuccess) {
      return {'success': false, 'error': 'Falha ao arquivar o treino'};
    }
    final cycleResult = await _cycleRepo.removeWorkoutFromCycle(workoutId);
    if (!cycleResult.isSuccess) {
      return {
        'success': true,
        'workoutId': workoutId,
        'warning': 'Treino arquivado mas falha ao remover do ciclo',
      };
    }
    return {'success': true, 'workoutId': workoutId};
  }

  Future<Map<String, Object?>> _handleSetCycle(List? stepsList) async {
    if (stepsList == null || stepsList.isEmpty) {
      return {'success': false, 'error': 'steps é obrigatório e não pode ser vazio'};
    }
    final cycleSteps = <TrainingCycleStep>[];
    for (var i = 0; i < stepsList.length; i++) {
      final item = stepsList[i];
      if (item is! Map) continue;
      final map = item;
      final typeStr = map['type']?.toString().toLowerCase();
      if (typeStr == 'rest') {
        cycleSteps.add(TrainingCycleStep(
          id: 0,
          orderIndex: i,
          type: CycleStepType.rest,
          workoutId: null,
        ));
      } else if (typeStr == 'workout') {
        final workoutId = map['workoutId'] != null
            ? (map['workoutId'] is int
                ? map['workoutId'] as int
                : int.tryParse(map['workoutId'].toString()))
            : null;
        if (workoutId == null || workoutId <= 0) continue;
        cycleSteps.add(TrainingCycleStep(
          id: 0,
          orderIndex: i,
          type: CycleStepType.workout,
          workoutId: workoutId,
        ));
      }
    }
    if (cycleSteps.isEmpty) {
      return {'success': false, 'error': 'Nenhum passo válido (use type: workout com workoutId ou type: rest)'};
    }
    final result = await _cycleRepo.setSteps(cycleSteps);
    if (!result.isSuccess) {
      return {'success': false, 'error': 'Falha ao guardar o ciclo'};
    }
    return {
      'success': true,
      'stepCount': cycleSteps.length,
    };
  }

  Future<Map<String, Object?>> _handleGetTrainingState() async {
    final activeResult = await _workoutRepo.getActive();
    if (!activeResult.isSuccess) {
      return {'success': false, 'error': 'Falha ao obter treinos ativos'};
    }
    final active = activeResult.getOrThrow();
    final stepsResult = await _cycleRepo.getSteps();
    if (!stepsResult.isSuccess) {
      return {'success': false, 'error': 'Falha ao obter o ciclo'};
    }
    final steps = stepsResult.getOrThrow();
    final activeById = {for (final w in active) w.id: w};
    final activeWorkouts = active
        .map((w) => {'id': w.id, 'name': w.name})
        .toList();
    final cycleSteps = <Map<String, Object?>>[];
    for (final s in steps) {
      if (s.type == CycleStepType.rest) {
        cycleSteps.add({'type': 'rest'});
      } else if (s.workoutId != null) {
        final w = activeById[s.workoutId];
        cycleSteps.add({
          'type': 'workout',
          'workoutId': s.workoutId,
          'workoutName': w?.name ?? 'Treino #${s.workoutId}',
        });
      }
    }
    return {
      'success': true,
      'activeWorkouts': activeWorkouts,
      'cycleSteps': cycleSteps,
    };
  }

  int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    final parsed = int.tryParse(value.toString());
    return parsed ?? fallback;
  }

  Future<Map<String, Object?>> _handleUpdateBio(String newBio) async {
    final profile = await _getProfile();
    if (profile == null) return {'success': false, 'error': 'No profile'};

    final existing = profile.bio ?? '';
    final combined =
        existing.isEmpty ? newBio : '$existing; $newBio';

    final result = await _profileRepo.update(
      profile.copyWith(bio: () => combined),
    );
    return result.isSuccess
        ? {'success': true, 'bio': combined}
        : {'success': false, 'error': 'Failed to update bio'};
  }

  Future<Map<String, Object?>> _handleUpdateInjuries(
      String newInjuries) async {
    final profile = await _getProfile();
    if (profile == null) return {'success': false, 'error': 'No profile'};

    final existing = profile.injuries ?? '';
    final combined =
        existing.isEmpty ? newInjuries : '$existing; $newInjuries';

    final result = await _profileRepo.update(
      profile.copyWith(injuries: () => combined),
    );
    return result.isSuccess
        ? {'success': true, 'injuries': combined}
        : {'success': false, 'error': 'Failed to update injuries'};
  }

  Future<Map<String, Object?>> _handleUpdateExperienceLevel(
      String level) async {
    final profile = await _getProfile();
    if (profile == null) return {'success': false, 'error': 'No profile'};

    final parsed = ExperienceLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => ExperienceLevel.beginner,
    );

    final result = await _profileRepo.update(
      profile.copyWith(experienceLevel: () => parsed),
    );
    return result.isSuccess
        ? {'success': true, 'level': parsed.name}
        : {'success': false, 'error': 'Failed to update experience level'};
  }

  Future<Map<String, Object?>> _handleUpdateTrainingFrequency(
      int days) async {
    final profile = await _getProfile();
    if (profile == null) return {'success': false, 'error': 'No profile'};

    final clamped = days.clamp(1, 7);
    final result = await _profileRepo.update(
      profile.copyWith(trainingFrequency: () => clamped),
    );
    return result.isSuccess
        ? {'success': true, 'daysPerWeek': clamped}
        : {'success': false, 'error': 'Failed to update frequency'};
  }

  Future<Map<String, Object?>> _handleUpdateGender(String gender) async {
    final profile = await _getProfile();
    if (profile == null) return {'success': false, 'error': 'No profile'};

    final parsed = Gender.values
        .where((e) => e.name == gender)
        .firstOrNull;
    if (parsed == null) {
      return {'success': false, 'error': 'Invalid gender: $gender'};
    }
    final result = await _profileRepo.update(
      profile.copyWith(gender: () => parsed),
    );
    return result.isSuccess
        ? {'success': true, 'gender': parsed.name}
        : {'success': false, 'error': 'Failed to update gender'};
  }

  Future<Map<String, Object?>> _handleRegisterEquipment(
      String equipmentName) async {
    final result = await _equipmentRepo.addByName(equipmentName);
    return result.isSuccess
        ? {'success': true, 'equipment': equipmentName}
        : {'success': false, 'error': 'Failed to register equipment'};
  }

  Future<Map<String, Object?>> _handleRemoveEquipment(
      String equipmentName) async {
    final result = await _equipmentRepo.removeByName(equipmentName);
    return result.isSuccess
        ? {'success': true, 'removed': equipmentName}
        : {'success': false, 'error': 'Failed to remove equipment'};
  }

  Future<UserProfile?> _getProfile() async {
    final result = await _profileRepo.get();
    return result.isSuccess ? result.getOrThrow() : null;
  }

  void _enforceRateLimit() {
    final now = DateTime.now();
    _timestamps.removeWhere((t) => now.difference(t).inMinutes >= 1);

    if (_timestamps.length >= _maxMessagesPerMinute) {
      throw Exception('Rate limit exceeded');
    }

    _timestamps.add(now);
  }
}
