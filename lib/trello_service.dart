import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class TrelloService {
  final String baseUrl = "https://api.trello.com/1";
  final String apiKey = Secrets.trelloApiKey;
  final String token = Secrets.trelloToken;

  // --- Boards ---

  Future<List<dynamic>> getBoards() async {
    final url = Uri.parse("$baseUrl/members/me/boards?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createBoard(String name, String? idBoardSource) async {
    final url = Uri.parse("$baseUrl/boards?key=$apiKey&token=$token");
    final body = {"name": name, "idBoardSource": idBoardSource};
    return await _makePostRequest(url, body);
  }

  Future<void> updateBoard(String boardId, String newName) async {
    final url = Uri.parse("$baseUrl/boards/$boardId?key=$apiKey&token=$token");
    final body = {"name": newName};
    await _makePutRequest(url, body);
  }

  Future<void> deleteBoard(String boardId) async {
    final url = Uri.parse("$baseUrl/boards/$boardId?key=$apiKey&token=$token");
    return await _makeDeleteRequest(url);
  }
  // --- Lists ---

  Future<List<dynamic>> getLists(String boardId) async {
    final url = Uri.parse("$baseUrl/boards/$boardId/lists?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createList(String boardId, String name) async {
    final url = Uri.parse("$baseUrl/lists?key=$apiKey&token=$token");
    final body = {"name": name, "idBoard": boardId};
    return await _makePostRequest(url, body);
  }

  Future<void> updateList(String listId, String newName) async {
    final url = Uri.parse("$baseUrl/lists/$listId?key=$apiKey&token=$token");
    final body = {"name": newName};
    await _makePutRequest(url, body);
  }
   Future<void> closeList(String listId) async {
    final url = Uri.parse("$baseUrl/lists/$listId/closed?key=$apiKey&token=$token&value=true");
     await _makePutRequest(url, {});
  }

  Future<void> deleteList(String listId) async {
    await closeList(listId); // Close the list before deleting
    final url = Uri.parse("$baseUrl/lists/$listId?key=$apiKey&token=$token");
    return await _makeDeleteRequest(url);
  }

  // --- Cards ---

  Future<Map<String, dynamic>> createCard(String listId, String name) async {
    final url = Uri.parse("$baseUrl/cards?key=$apiKey&token=$token");
    final body = {"name": name, "idList": listId};
    return await _makePostRequest(url, body);
  }

  // --- General Request Methods ---

  Future<List<dynamic>> _makeRequest(Uri url) async {
    final response = await http.get(url);
    print("GET - Status Code: ${response.statusCode}");
    print("GET - Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error making GET request");
    }
  }

  Future<Map<String, dynamic>> _makePostRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print("POST - Status Code: ${response.statusCode}");
    print("POST - Response Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error making POST request");
    }
  }
   Future<void> _makePutRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print("PUT - Status Code: ${response.statusCode}");
    print("PUT - Response Body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error making PUT request");
    }
  }

  Future<void> _makeDeleteRequest(Uri url) async {
    final response = await http.delete(url);

    print("DELETE - Status Code: ${response.statusCode}");
    print("DELETE - Response Body: ${response.body}");

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error making DELETE request");
    }
  }
}
