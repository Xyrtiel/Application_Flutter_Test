import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class TrelloService {
  final String baseUrl = "https://api.trello.com/1";

  final String apiKey = Secrets.trelloApiKey;
  final String token = Secrets.trelloToken;

  Future<List<dynamic>> getBoards() async {
    final url = Uri.parse("$baseUrl/members/me/boards?key=$apiKey&token=$token");

    final response = await http.get(url);

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error getting boards");
    }
  }
}
