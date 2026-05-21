import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final int n = exam.criteria.length;
    
    if (exam.customRubric != null && exam.customRubric!.isNotEmpty) {
      rubricsPrompt = '''
You are an expert academic grader. Grade this student's submission strictly based on the following custom grading rubric provided by the teacher (extracted from a Word Document):
"""
${exam.customRubric}
"""
Please analyze the submission and assign scores to $n primary components as outlined in this rubric. Distribute the scores across the criteria.
''';
    } else {
      rubricsPrompt = 'You are an expert academic grader. Grade this student\'s submission based on these $n criteria:\n';
      for (int i = 0; i < n; i++) {
        rubricsPrompt += '${i + 1}. ${exam.criteria[i].name} (Maximum score: ${exam.criteria[i].maxScore10} points on a 10-point scale)\n';
      }
    }

    final jsonFields = {};
    for (int i = 1; i <= n; i++) {
      jsonFields['"score$i"'] = '<number (0 to ${exam.criteria[i - 1].maxScore10})>';
      jsonFields['"comment$i"'] = '<nhận xét tiếng Việt súc tích cho tiêu chí $i>';
    }

    final prompt = '''
$rubricsPrompt

Although the original rubric might be out of 100 points, you MUST evaluate and return the scores scaled to a 10-point scale.
Here are the criteria and their max scores on a 10-point scale:
${exam.criteria.asMap().entries.map((e) => '- ${e.value.name}: Max ${e.value.maxScore10} points').join('\n')}

For each criterion, assign a score and provide a specific, concise explanation/comment in Vietnamese explaining why the student got this score.
Also, provide an overall brief summary of the entire submission in the "comment" field.

Submission content:
${sub.content}

Return ONLY valid JSON (no markdown block, just the json object):
{
  ${jsonFields.entries.map((e) => '${e.key}: ${e.value}').join(',\n  ')},
  "comment": "<Nhận xét tổng quan súc tích bằng tiếng Việt>"
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
      final resultText = data['candidates'][0]['content']['parts'][0]['text'] as String;
      
      // Robust JSON Extraction
      Map<String, dynamic> resultJson;
      try {
        resultJson = jsonDecode(resultText.trim());
      } catch (_) {
        // Fallback: search for first '{' and last '}' to extract JSON block
        final regExp = RegExp(r'\{[\s\S]*\}');
        final match = regExp.firstMatch(resultText);
        if (match != null) {
          resultJson = jsonDecode(match.group(0)!);
        } else {
          throw Exception("AI output format error. Could not extract JSON: $resultText");
        }
      }
      
      final List<double> newAiScores = [];
      final List<String> newAiComments = [];
      for (int i = 1; i <= n; i++) {
        final scoreVal = resultJson['score$i'];
        newAiScores.add((scoreVal as num?)?.toDouble() ?? 0.0);
        
        final commentVal = resultJson['comment$i'] ?? "";
        newAiComments.add(commentVal.toString());
      }
      sub.aiScores = newAiScores;
      sub.aiComments = newAiComments;
      sub.aiComment = resultJson['comment']?.toString() ?? "";
      sub.hasAiGraded = true;
    } else {
      debugPrint("========== Gemini API Error ==========");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("=====================================");
      throw Exception("Gemini Error: ${response.statusCode} - ${response.body}");
    }
  }
}
