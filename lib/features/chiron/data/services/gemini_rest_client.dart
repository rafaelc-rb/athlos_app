import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiApiException implements Exception {
  GeminiApiException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  bool get isRetryable =>
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  bool get isQuotaOrRateLimit {
    final normalized = message.toLowerCase();
    return statusCode == 429 ||
        normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('resource_exhausted');
  }

  @override
  String toString() {
    if (statusCode != null) return 'Gemini API error ($statusCode): $message';
    return 'Gemini API error: $message';
  }
}

/// REST client for Gemini generateContent API with support for
/// [thoughtSignature] so thinking models (2.5, 3) work with function calling.
class GeminiRestClient {
  GeminiRestClient({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Sends a single generateContent request. Returns the parsed JSON response.
  /// Throws on HTTP error or API error block.
  Future<Map<String, dynamic>> generateContent({
    required String modelId,
    required List<Map<String, dynamic>> contents,
    required String systemInstruction,
    required List<Map<String, dynamic>> toolDeclarations,
    int? maxOutputTokens,
    double? temperature,
  }) async {
    final uri = Uri.parse('$_baseUrl/$modelId:generateContent').replace(
      queryParameters: {'key': _apiKey},
    );
    final body = <String, dynamic>{
      'contents': contents,
      'systemInstruction': _systemInstructionContent(systemInstruction),
    };
    if (toolDeclarations.isNotEmpty) {
      body['tools'] = [
        {'functionDeclarations': toolDeclarations}
      ];
    }

    final generationConfig = <String, dynamic>{};
    if (maxOutputTokens != null) {
      generationConfig['maxOutputTokens'] = maxOutputTokens;
    }
    if (temperature != null) {
      generationConfig['temperature'] = temperature;
    }
    if (generationConfig.isNotEmpty) {
      body['generationConfig'] = generationConfig;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw GeminiApiException(message: 'generateContent timeout'),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>?;
    if (response.statusCode != 200) {
      final message = json?['error']?['message'] ?? response.body;
      throw GeminiApiException(
        statusCode: response.statusCode,
        message: message.toString(),
      );
    }

    if (json == null) throw GeminiApiException(message: 'Empty response');
    return json;
  }

  Map<String, dynamic> _systemInstructionContent(String text) {
    return {
      'parts': [
        {'text': text}
      ]
    };
  }
}

/// Result of parsing one generateContent response.
class GeminiResponseParse {
  GeminiResponseParse({
    this.text,
    List<GeminiFunctionCall>? functionCalls,
    this.thoughtSignature,
    List<Map<String, dynamic>>? modelParts,
  })  : functionCalls = functionCalls ?? [],
        modelParts = modelParts ?? [];

  final String? text;
  final List<GeminiFunctionCall> functionCalls;
  final String? thoughtSignature;
  /// Raw parts from the model turn (to append to contents when sending back).
  final List<Map<String, dynamic>> modelParts;
}

class GeminiFunctionCall {
  GeminiFunctionCall({required this.name, required this.args});
  final String name;
  final Map<String, dynamic> args;
}

/// Parses generateContent response JSON into text, function calls, and
/// thought signature. Extracts [modelParts] so they can be echoed back.
GeminiResponseParse parseGenerateContentResponse(Map<String, dynamic> json) {
  final candidates = json['candidates'] as List<dynamic>?;
  if (candidates == null || candidates.isEmpty) {
    return GeminiResponseParse(text: '');
  }

  final candidate = candidates[0] as Map<String, dynamic>?;
  final content = candidate?['content'] as Map<String, dynamic>?;
  final parts = content?['parts'] as List<dynamic>?;
  if (parts == null || parts.isEmpty) {
    return GeminiResponseParse(text: '');
  }

  final buffer = StringBuffer();
  final functionCalls = <GeminiFunctionCall>[];
  String? thoughtSignature;
  final modelParts = <Map<String, dynamic>>[];

  final thoughtBuffer = StringBuffer();

  for (final p in parts) {
    if (p is! Map<String, dynamic>) continue;
    modelParts.add(Map<String, dynamic>.from(p));

    if (p.containsKey('text')) {
      final t = p['text'] as String?;
      if (t != null && t.isNotEmpty) {
        final isThought = p['thought'] == true;
        if (isThought) {
          thoughtBuffer.write(t);
        } else {
          buffer.write(t);
        }
      }
    }
    if (p.containsKey('functionCall')) {
      final fc = p['functionCall'] as Map<String, dynamic>?;
      if (fc != null) {
        final name = fc['name'] as String?;
        final args = fc['args'] as Map<String, dynamic>?;
        if (name != null) {
          functionCalls.add(GeminiFunctionCall(
            name: name,
            args: args ?? {},
          ));
        }
      }
      // thoughtSignature can be on the same part as functionCall (Gemini 3).
      final ts = p['thoughtSignature'] as String?;
      if (ts != null && ts.isNotEmpty) thoughtSignature ??= ts;
    }
    if (p.containsKey('thoughtSignature') && thoughtSignature == null) {
      final ts = p['thoughtSignature'] as String?;
      if (ts != null && ts.isNotEmpty) thoughtSignature = ts;
    }
  }

  // If no regular text but we have thought text (thinking models), use it as reply
  String? outText = buffer.isEmpty ? null : buffer.toString();
  if (outText == null && thoughtBuffer.isNotEmpty) {
    outText = thoughtBuffer.toString();
  }

  return GeminiResponseParse(
    text: outText,
    functionCalls: functionCalls,
    thoughtSignature: thoughtSignature,
    modelParts: modelParts,
  );
}

/// Builds the "user" content part to send after executing function calls:
/// thoughtSignature first (if present), then one functionResponse per call.
List<Map<String, dynamic>> buildFunctionResponseParts({
  String? thoughtSignature,
  required List<MapEntry<String, Map<String, Object?>>> nameToResponse,
}) {
  final parts = <Map<String, dynamic>>[];
  if (thoughtSignature != null && thoughtSignature.isNotEmpty) {
    parts.add({'thoughtSignature': thoughtSignature});
  }
  for (final e in nameToResponse) {
    parts.add({
      'functionResponse': {
        'name': e.key,
        'response': e.value,
      }
    });
  }
  return parts;
}

/// Tool declarations for Chiron in the format expected by the REST API
/// (OpenAPI-style parameters). Kept in sync with repository handlers.
///
/// Tool descriptions carry detailed behavioral rules so the system prompt
/// stays compact while the model still knows how to use each tool.
List<Map<String, dynamic>> getChironToolDeclarations() {
  return [
    {
      'name': 'updateBio',
      'description':
          'Append information to the user bio. '
              'Always concatenate — never overwrite existing bio. '
              'Use when user shares background, preferences, or goals.',
      'parameters': _schema(
        properties: {
          'bio': _propString('Text to append to existing bio'),
        },
        required: ['bio'],
      ),
    },
    {
      'name': 'setInjuries',
      'description':
          'Set the full injuries/limitations text, replacing any previous value. '
              'Read existing injuries from context first, then write the '
              'complete updated text (add new, remove recovered, keep current). '
              'Pass empty string to clear all injuries.',
      'parameters': _schema(
        properties: {
          'injuries': _propString(
            'Complete injuries text (replaces existing). '
            'Empty string to clear.',
          ),
        },
        required: ['injuries'],
      ),
    },
    {
      'name': 'updateExperienceLevel',
      'description':
          'Set user experience level. Ask naturally if missing from context.',
      'parameters': _schema(
        properties: {
          'level': _propEnum(
            ['beginner', 'intermediate', 'advanced'],
            'Experience level',
          ),
        },
        required: ['level'],
      ),
    },
    {
      'name': 'updateGender',
      'description':
          'Set user gender. Influences workout planning: '
              'female → prioritize legs/glutes, proportional volume; '
              'male → classic splits (push/pull/legs). '
              'Ask naturally if missing.',
      'parameters': _schema(
        properties: {
          'gender': _propEnum(
            ['male', 'female'],
            'Gender: male or female',
          ),
        },
        required: ['gender'],
      ),
    },
    {
      'name': 'updateTrainingFrequency',
      'description':
          'Set weekly training frequency (1-7 days). '
              'Ask naturally if missing from context.',
      'parameters': _schema(
        properties: {
          'daysPerWeek': _propInteger('Days per week (1-7)'),
        },
        required: ['daysPerWeek'],
      ),
    },
    {
      'name': 'updateTrainsAtGym',
      'description':
          'Set whether the user trains at a gym. '
              'If true, assume standard gym equipment when building workouts. '
              'Ask naturally if missing from context.',
      'parameters': _schema(
        properties: {
          'trainsAtGym': {
            'type': 'boolean',
            'description': 'true if user trains at a gym, false for home',
          },
        },
        required: ['trainsAtGym'],
      ),
    },
    {
      'name': 'updateAvailableMinutes',
      'description':
          'Set how many minutes the user has per workout session. '
              'Used to size workouts appropriately. '
              'Ask naturally if missing from context.',
      'parameters': _schema(
        properties: {
          'minutes': _propInteger('Minutes available per session (e.g. 45, 60, 90)'),
        },
        required: ['minutes'],
      ),
    },
    {
      'name': 'registerEquipment',
      'description':
          'Register equipment the user has at home. '
              'Only relevant for home gym users. '
              'If "Trains at gym: Yes" in profile, skip — assume '
              'standard gym equipment is available.',
      'parameters': _schema(
        properties: {
          'equipmentName': _propString('Equipment name to register'),
        },
        required: ['equipmentName'],
      ),
    },
    {
      'name': 'removeEquipment',
      'description':
          'Remove equipment the user no longer has.',
      'parameters': _schema(
        properties: {
          'equipmentName': _propString('Equipment name to remove'),
        },
        required: ['equipmentName'],
      ),
    },
    {
      'name': 'createWorkout',
      'description':
          'Create a new workout with ordered exercises from the catalog. '
              'Use exercise names from the Catalog section in context. '
              'Does NOT update the cycle — you MUST call setCycle after '
              'with all active workouts, then getTrainingState to verify. '
              'To modify an existing workout, use updateWorkout instead.',
      'parameters': _schema(
        properties: {
          'name': _propString('Workout name'),
          'description': _propString(
            'Optional workout description',
            nullable: true,
          ),
          'exercises': {
            'type': 'array',
            'description': 'Ordered exercise list',
            'items': _schema(
              properties: {
                'exerciseName': _propString(
                  'Exercise name from the Catalog section in context',
                ),
                'sets': _propInteger('Number of sets'),
                'reps': _propInteger(
                  'Reps per set (for cardio use 0 and fill durationSeconds)',
                  nullable: true,
                ),
                'restSeconds': _propInteger(
                  'Rest between sets in seconds',
                  nullable: true,
                ),
                'durationSeconds': _propInteger(
                  'Duration per set in seconds (cardio/timed exercises)',
                  nullable: true,
                ),
                'notes': _propString(
                  'Execution cues or variations',
                  nullable: true,
                ),
              },
              required: ['exerciseName', 'sets'],
            ),
          },
        },
        required: ['name', 'exercises'],
      ),
    },
    {
      'name': 'updateWorkout',
      'description':
          'Update an existing workout: rename, change description, '
              'and/or replace the full exercise list. '
              'Use workout ID from Active Workouts in context (id=X). '
              'When changing exercises, send the COMPLETE new list — '
              'it replaces all existing exercises.',
      'parameters': _schema(
        properties: {
          'workoutId': _propInteger('Workout ID to update (from context)'),
          'name': _propString('New workout name', nullable: true),
          'description': _propString('New description', nullable: true),
          'exercises': {
            'type': 'array',
            'nullable': true,
            'description':
                'New full exercise list (replaces existing). '
                'Omit to keep current exercises.',
            'items': _schema(
              properties: {
                'exerciseName': _propString(
                  'Exercise name from the Catalog section in context',
                ),
                'sets': _propInteger('Number of sets'),
                'reps': _propInteger('Reps per set', nullable: true),
                'restSeconds': _propInteger(
                  'Rest between sets in seconds',
                  nullable: true,
                ),
                'durationSeconds': _propInteger(
                  'Duration per set in seconds',
                  nullable: true,
                ),
                'notes': _propString('Execution cues', nullable: true),
              },
              required: ['exerciseName', 'sets'],
            ),
          },
        },
        required: ['workoutId'],
      ),
    },
    {
      'name': 'archiveWorkout',
      'description':
          'Archive a workout — removes from active list but keeps history. '
              'Use workout ID from Active Workouts in context (id=X). '
              'Does NOT update the cycle — you MUST call setCycle after '
              'without this workout, then getTrainingState to verify.',
      'parameters': _schema(
        properties: {
          'workoutId': _propInteger('Workout ID to archive (from context)'),
        },
        required: ['workoutId'],
      ),
    },
    {
      'name': 'setCycle',
      'description':
          'Define the workout cycle (routine order). '
              'Call after creating/archiving workouts. '
              'Each step is { type: "workout", workoutId: N } or '
              '{ type: "rest" }. Include only active workout IDs. '
              'Replaces the full cycle. Always call getTrainingState after.',
      'parameters': _schema(
        properties: {
          'steps': {
            'type': 'array',
            'description': 'Ordered cycle steps',
            'items': _schema(
              properties: {
                'type': _propEnum(
                  ['workout', 'rest'],
                  'Step type: workout or rest',
                ),
                'workoutId': _propInteger(
                  'Workout ID (required when type=workout)',
                  nullable: true,
                ),
              },
              required: ['type'],
            ),
          },
        },
        required: ['steps'],
      ),
    },
    {
      'name': 'getTrainingState',
      'description':
          'Read current state: active workouts and cycle order. '
              'Call at the end of any workout/cycle change to verify '
              'everything was applied correctly. Compare with intended '
              'result and report discrepancies to the user.',
      'parameters': _schema(
        properties: {},
        required: [],
      ),
    },
    {
      'name': 'requestExtendedHistory',
      'description':
          'Load extended workout/execution history for long-term '
              'trend analysis, evolution, or cross-session comparisons. '
              'Call before answering when the available context seems '
              'too short for the question asked.',
      'parameters': _schema(
        properties: {},
        required: [],
      ),
    },
  ];
}

Map<String, dynamic> _schema({
  required Map<String, dynamic> properties,
  required List<String> required,
}) {
  return {
    'type': 'object',
    'properties': properties,
    'required': required,
  };
}

Map<String, dynamic> _propString(String description, {bool? nullable}) {
  final m = <String, dynamic>{'type': 'string', 'description': description};
  if (nullable == true) m['nullable'] = true;
  return m;
}

Map<String, dynamic> _propInteger(String description, {bool? nullable}) {
  final m = <String, dynamic>{'type': 'integer', 'description': description};
  if (nullable == true) m['nullable'] = true;
  return m;
}

Map<String, dynamic> _propEnum(List<String> values, String description) {
  return {
    'type': 'string',
    'description': description,
    'enum': values,
  };
}
