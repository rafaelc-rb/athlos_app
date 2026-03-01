import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/errors/result.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/enums/experience_level.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../../training/domain/repositories/equipment_repository.dart';
import '../../domain/entities/chiron_message.dart';
import '../../domain/repositories/chiron_repository.dart';

class ChironRepositoryImpl implements ChironRepository {
  final String _apiKey;
  final UserProfileRepository _profileRepo;
  final EquipmentRepository _equipmentRepo;

  static const _maxMessagesPerMinute = 10;
  final _timestamps = <DateTime>[];

  static const _systemPrompt = '''
Você é o Quíron (Chiron), um assistente de treino com IA no aplicativo Athlos.
Quíron é inspirado no centauro da mitologia grega, mentor de heróis como Aquiles e Hércules.

## Diretrizes gerais
- Responda sempre em português do Brasil
- Seja conciso mas informativo
- Foque em treino, exercícios, nutrição básica e recuperação
- Use os dados do utilizador para personalizar as respostas
- Nunca dê conselhos médicos — recomende procurar um profissional quando apropriado
- Mantenha um tom motivacional mas profissional
- Use formatação Markdown quando apropriado (listas, negrito, etc.)

## Campos em falta
Verifica os campos do perfil do utilizador no contexto fornecido. Se algum campo crítico estiver vazio ou ausente (injuries, experienceLevel, trainingFrequency), pergunta ao utilizador de forma natural durante a conversa e usa as funções disponíveis para guardar. Não faças um interrogatório — integra as perguntas na conversa de forma natural.

Campos críticos: injuries (lesões), experienceLevel (nível de experiência), trainingFrequency (frequência de treino).
Campos complementares (bio): enriquece ao longo de conversas, sem pressionar.

## Equipamentos
Não te limites aos equipamentos registados. Sugere exercícios livremente e pergunta ao utilizador se tem o equipamento necessário. Se confirmar, usa registerEquipment para guardar. Se negar, sugere alternativa com outro equipamento ou sem equipamento.

## Bio
Quando aprenderes algo relevante sobre o histórico do utilizador que ainda não esteja no bio (tempo de treino, desportos anteriores, contexto pessoal), usa updateBio para ACRESCENTAR ao bio existente. Nunca apagues o que já existe — concatena com um separador "; ".

## Lesões
Se o utilizador mencionar lesões ou limitações que não estejam registadas, usa updateInjuries para ACRESCENTAR à lista existente. Nunca apagues — concatena com "; ".

## Análise de progresso
Analisa o histórico de execuções para sugerir quando trocar de treino, progressões, e descanso. Considera a data de criação dos treinos e a frequência de execução. Compara pesos e reps entre sessões para identificar estagnação ou progressão.
''';

  static final _toolDeclarations = [
    Tool(functionDeclarations: [
      FunctionDeclaration(
        'updateBio',
        'Acrescenta informação ao campo bio do perfil do utilizador. '
            'Concatena ao bio existente, nunca sobrescreve.',
        Schema.object(properties: {
          'bio': Schema.string(
            description: 'Texto a acrescentar ao bio existente',
          ),
        }, requiredProperties: [
          'bio'
        ]),
      ),
      FunctionDeclaration(
        'updateInjuries',
        'Acrescenta lesão/limitação ao campo injuries do perfil. '
            'Concatena ao texto existente, nunca sobrescreve.',
        Schema.object(properties: {
          'injuries': Schema.string(
            description: 'Texto da lesão a acrescentar',
          ),
        }, requiredProperties: [
          'injuries'
        ]),
      ),
      FunctionDeclaration(
        'updateExperienceLevel',
        'Atualiza o nível de experiência do utilizador.',
        Schema.object(properties: {
          'level': Schema.enumString(
            enumValues: ['beginner', 'intermediate', 'advanced'],
            description: 'Nível de experiência',
          ),
        }, requiredProperties: [
          'level'
        ]),
      ),
      FunctionDeclaration(
        'updateTrainingFrequency',
        'Atualiza a frequência de treino semanal do utilizador.',
        Schema.object(properties: {
          'daysPerWeek': Schema.integer(
            description: 'Número de dias por semana (1-7)',
          ),
        }, requiredProperties: [
          'daysPerWeek'
        ]),
      ),
      FunctionDeclaration(
        'registerEquipment',
        'Regista um equipamento que o utilizador confirmou ter disponível.',
        Schema.object(properties: {
          'equipmentName': Schema.string(
            description: 'Nome do equipamento a registar',
          ),
        }, requiredProperties: [
          'equipmentName'
        ]),
      ),
      FunctionDeclaration(
        'removeEquipment',
        'Remove um equipamento que o utilizador disse já não ter.',
        Schema.object(properties: {
          'equipmentName': Schema.string(
            description: 'Nome do equipamento a remover',
          ),
        }, requiredProperties: [
          'equipmentName'
        ]),
      ),
    ]),
  ];

  ChironRepositoryImpl({
    required String apiKey,
    required UserProfileRepository profileRepo,
    required EquipmentRepository equipmentRepo,
  })  : _apiKey = apiKey,
        _profileRepo = profileRepo,
        _equipmentRepo = equipmentRepo;

  @override
  Stream<String> sendMessage({
    required String userMessage,
    required List<ChironMessage> history,
    required String userContext,
  }) async* {
    _enforceRateLimit();

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system('$_systemPrompt\n\n$userContext'),
      tools: _toolDeclarations,
    );

    final chatHistory = history.map((msg) {
      final role = msg.role == ChironRole.user ? 'user' : 'model';
      return Content(role, [TextPart(msg.content)]);
    }).toList();

    final chat = model.startChat(history: chatHistory);
    var response = await chat.sendMessage(Content.text(userMessage));

    // Function calling loop: handle tool calls until we get pure text
    while (response.functionCalls.isNotEmpty) {
      final functionResponses = <FunctionResponse>[];

      for (final call in response.functionCalls) {
        final result = await _handleFunctionCall(call);
        functionResponses.add(
          FunctionResponse(call.name, result),
        );
      }

      response = await chat.sendMessage(
        Content.functionResponses(functionResponses),
      );
    }

    final text = response.text;
    if (text != null && text.isNotEmpty) {
      yield text;
    }
  }

  Future<Map<String, Object?>> _handleFunctionCall(FunctionCall call) async {
    switch (call.name) {
      case 'updateBio':
        return _handleUpdateBio(call.args['bio'] as String);
      case 'updateInjuries':
        return _handleUpdateInjuries(call.args['injuries'] as String);
      case 'updateExperienceLevel':
        return _handleUpdateExperienceLevel(call.args['level'] as String);
      case 'updateTrainingFrequency':
        final days = call.args['daysPerWeek'];
        return _handleUpdateTrainingFrequency(
          days is int ? days : int.parse(days.toString()),
        );
      case 'registerEquipment':
        return _handleRegisterEquipment(
            call.args['equipmentName'] as String);
      case 'removeEquipment':
        return _handleRemoveEquipment(
            call.args['equipmentName'] as String);
      default:
        return {'success': false, 'error': 'Unknown function: ${call.name}'};
    }
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
