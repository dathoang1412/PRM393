import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/submission.dart';
import '../models/exam_type.dart';

class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref) ?? "";
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<void> gradeSubmission(Submission sub, ExamType exam, String apiKey) async {
    String rubricsPrompt = '';
    if (exam.customRubric != null && exam.customRubric!.isNotEmpty) {
      rubricsPrompt = '''
You are an expert academic grader. Grade this student's submission strictly based on the following custom grading rubric provided by the teacher (extracted from a Word Document):
"""
${exam.customRubric}
"""
Please analyze the submission and assign scores to 3 primary components as outlined in this rubric. If the rubric does not specify 3 distinct sections, group your analysis into three logical criteria and distribute the scores.
''';
    } else {
      rubricsPrompt = '''
You are an expert academic grader. Grade this student's submission based on these 3 criteria:
1. ${exam.criteria[0]}
2. ${exam.criteria[1]}
3. ${exam.criteria[2]}
''';
    }

    final prompt = '''
$rubricsPrompt

Submission content:
${sub.content}

Return ONLY valid JSON (no markdown block, just the json object):
{
  "score1": <number>,
  "score2": <number>,
  "score3": <number>,
  "comment": "<string detailed comment explaining your score based on the rubric>"
}
''';

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final resultText = data['candidates'][0]['content']['parts'][0]['text'];
      final resultJson = jsonDecode(resultText);
      
      sub.aiScore1 = (resultJson['score1'] as num).toDouble();
      sub.aiScore2 = (resultJson['score2'] as num).toDouble();
      sub.aiScore3 = (resultJson['score3'] as num).toDouble();
      sub.aiComment = resultJson['comment']?.toString() ?? "";
      sub.hasAiGraded = true;
    } else {
      print("========== Gemini API Error ==========");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=====================================");
      throw Exception("Gemini Error: ${response.statusCode} - ${response.body}");
    }
  }
}
