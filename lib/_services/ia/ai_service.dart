import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String endpoint; // URL completa da Function

  AiService({required this.endpoint});

  Future<String> ask(String message) async {
    final uri = Uri.parse(endpoint);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['reply'] as String;
    } else {
      throw Exception('Erro ao chamar IA: ${response.body}');
    }
  }
}
