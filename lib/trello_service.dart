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

  Future<List<dynamic>> getCards(String listId) async {
    final url = Uri.parse("$baseUrl/lists/$listId/cards?key=$apiKey&token=$token&fields=all&closed=true");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createCard(String listId, String name) async {
    final url = Uri.parse("$baseUrl/cards?key=$apiKey&token=$token");
    final body = {"name": name, "idList": listId};
    return await _makePostRequest(url, body);
  }

  Future<void> updateCard(String cardId, String newName, [String? desc]) async {
    final url = Uri.parse("$baseUrl/cards/$cardId?key=$apiKey&token=$token");
    final body = {"name": newName};
    if (desc != null) body['desc'] = desc; // Add description if provided
    await _makePutRequest(url, body);
  }

  Future<void> deleteCard(String cardId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  Future<void> closeCard(String cardId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId?key=$apiKey&token=$token&closed=true");
    await _makePutRequest(url, {});
  }

  // --- Card Activities---
  Future<List<dynamic>> getCardActivities(String cardId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId/actions?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  // --- Members ---
  Future<List<dynamic>> getCardMembers(String cardId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId/members?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<List<dynamic>> getBoardMembers(String boardId) async {
    final url = Uri.parse("$baseUrl/boards/$boardId/members?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<void> addMemberToCard(String cardId, String memberId) async {
     final url = Uri.parse("$baseUrl/cards/$cardId/idMembers?key=$apiKey&token=$token&value=$memberId");
    await _makePostRequest(url, {});
  }

  Future<void> removeMemberFromCard(String cardId, String memberId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId/idMembers/$memberId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  //--- Labels---
  Future<List<dynamic>> getBoardLabels(String boardId) async {
    final url = Uri.parse("$baseUrl/boards/$boardId/labels?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<void> addLabelToCard(String cardId, String labelId) async {
     final url = Uri.parse("$baseUrl/cards/$cardId/idLabels?key=$apiKey&token=$token&value=$labelId");
    await _makePostRequest(url, {});
  }

  Future<void> removeLabelFromCard(String cardId, String labelId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId/idLabels/$labelId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  Future<Map<String, dynamic>> createLabel(String boardId, String name, String color) async {
    final url = Uri.parse("$baseUrl/labels?key=$apiKey&token=$token");
    final body = {"idBoard": boardId, "name": name, "color": color};
    return await _makePostRequest(url, body);
  }

  // --- General Request Methods ---

  Future<List<dynamic>> _makeRequest(Uri url) async {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error making GET request: ${response.statusCode} - ${response.body}");
    }
  }

  Future<Map<String, dynamic>> _makePostRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.post(
      url,
       headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error making POST request: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> _makePutRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error making PUT request: ${response.statusCode} - ${response.body}");
    }
  }

  Future<void> _makeDeleteRequest(Uri url) async {
    final response = await http.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error making DELETE request: ${response.statusCode} - ${response.body}");
    }
  }
}
