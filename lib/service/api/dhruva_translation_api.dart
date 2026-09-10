import 'package:dio/dio.dart';

class TranslationTargetOutput {
  final String source;
  final String target;

  TranslationTargetOutput({
    required this.source,
    required this.target,
  });

  factory TranslationTargetOutput.fromJson(Map<String, dynamic> json) {
    return TranslationTargetOutput(
      source: json['source'] ?? '',
      target: json['target'] ?? '',
    );
  }
}

class TranslationApiResponse {
  final List<TranslationTargetOutput> output;

  TranslationApiResponse({required this.output});

  factory TranslationApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['output'] as List? ?? [];
    return TranslationApiResponse(
      output: list.map((e) => TranslationTargetOutput.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class DhruvaTranslationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 1500),
    receiveTimeout: const Duration(milliseconds: 1500),
  ));

  Future<TranslationApiResponse> translate({
    required String sourceLanguage,
    required String targetLanguage,
    required String input,
  }) async {
    try {
      // AI4Bharat / Bhashini NMT public inference endpoint
      final response = await _dio.post(
        'https://dhruva-api.bhashini.gov.in/services/inference/translation',
        data: {
          'pipelineTasks': [
            {
              'taskType': 'translation',
              'config': {
                'language': {
                  'sourceLanguage': sourceLanguage,
                  'targetLanguage': targetLanguage,
                }
              }
            }
          ],
          'inputData': {
            'input': [
              {'source': input}
            ]
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final pipelineResponse = response.data['pipelineResponse'];
        if (pipelineResponse is List && pipelineResponse.isNotEmpty) {
          final outputList = pipelineResponse.first['output'] as List?;
          if (outputList != null && outputList.isNotEmpty) {
            return TranslationApiResponse(
              output: outputList
                  .map((e) => TranslationTargetOutput(
                        source: e['source'] ?? input,
                        target: e['target'] ?? '',
                      ))
                  .toList(),
            );
          }
        }
      }
    } catch (_) {
      // Return empty response on network failure, letting hybrid fallback to offline dictionary
    }

    return TranslationApiResponse(output: []);
  }
}

class TranslationApi {
  final DhruvaTranslationService translationService = DhruvaTranslationService();
}
