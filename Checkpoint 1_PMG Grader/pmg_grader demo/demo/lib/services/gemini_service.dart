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
    
    final criteriaList = exam.criteria.asMap().entries
        .map((e) => '${e.key + 1}. ${e.value.name} (Max: ${e.value.maxScore10} điểm)')
        .join('\n');

    if (exam.customRubric != null && exam.customRubric!.isNotEmpty) {
      rubricsPrompt = '''
Bạn là giảng viên chấm bài chuyên nghiệp. Hãy chấm bài nộp của sinh viên dựa CHẶT CHẼ theo thang điểm/rubric sau của giáo viên (trích xuất từ tài liệu Word):
"""
${exam.customRubric}
"""
Bài nộp được chia thành $n câu/tiêu chí chính:
$criteriaList

Với MỖI câu/tiêu chí, hãy:
1. Xác định các tiêu chí con (sub-criteria) trong rubric tương ứng với câu đó
2. Đánh giá sinh viên theo từng tiêu chí con đó
3. Ghi nhận xét ngắn gọn theo dạng: "• [tên tiêu chí con]: [đánh giá ngắn]" cho mỗi tiêu chí con
4. Cho điểm tổng của câu đó (thang 10)
''';
    } else {
      rubricsPrompt = 'Bạn là giảng viên chấm bài chuyên nghiệp. Chấm bài nộp theo $n tiêu chí sau:\n$criteriaList\n';
    }

    final jsonFields = {};
    for (int i = 1; i <= n; i++) {
      jsonFields['"score$i"'] = '<số thực (0 đến ${exam.criteria[i - 1].maxScore10})>';
      jsonFields['"comment$i"'] = '<nhận xét tiếng Việt: liệt kê đánh giá theo từng tiêu chí con, mỗi dòng bắt đầu bằng "• tên tiêu chí: nhận xét">';
    }

    final prompt = '''
$rubricsPrompt

Điểm PHẢI được quy đổi về thang 10 theo đúng tỷ lệ max score của mỗi câu:
$criteriaList

Bài nộp của sinh viên:
${sub.content}

Trả về ĐÚNG định dạng JSON hợp lệ (không có markdown, chỉ JSON thuần):
{
  ${jsonFields.entries.map((e) => '${e.key}: ${e.value}').join(',\n  ')},
  "comment": "<Nhận xét tổng quan ngắn gọn bằng tiếng Việt>"
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
