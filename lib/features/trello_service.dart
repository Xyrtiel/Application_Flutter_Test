import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/secrets.dart';

// Custom Exception class for more specific error handling
class TrelloApiException implements Exception {
  final int statusCode;
  final String message;
  final String? responseBody;

  TrelloApiException(this.statusCode, this.message, {this.responseBody});

  @override
  String toString() {
    return 'TrelloApiException: $statusCode - $message ${responseBody != null ? "\nResponse: $responseBody" : ""}';
  }
}

class TrelloService {
  final String baseUrl = "https://api.trello.com/1";
  final String apiKey = Secrets.trelloApiKey;
  final String token = Secrets.trelloToken;

  // --- Boards ---

  Future<List<dynamic>> getBoards() async {
    final url =
        Uri.parse("$baseUrl/members/me/boards?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createBoard(
      String name, String? idBoardSource) async {
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
    final url =
        Uri.parse("$baseUrl/boards/$boardId/lists?key=$apiKey&token=$token");
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
    final url = Uri.parse(
        "$baseUrl/lists/$listId/closed?key=$apiKey&token=$token&value=true");
    await _makePutRequest(url, {});
  }

  Future<void> deleteList(String listId) async {
    // Closing a list before deleting (Might not be necessary - see note)
    try {
      await closeList(listId);
    } catch (e) {
      print("Warning: Could not close list $listId before deleting: $e");
    }
    final url = Uri.parse("$baseUrl/lists/$listId?key=$apiKey&token=$token");
    return await _makeDeleteRequest(url);
  }

  // --- Cards ---

  Future<List<dynamic>> getCards(String listId) async {
    final url = Uri.parse(
        "$baseUrl/lists/$listId/cards?key=$apiKey&token=$token&fields=all");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createCard(String listId, String name) async {
    final url = Uri.parse("$baseUrl/cards?key=$apiKey&token=$token");
    final body = {"name": name, "idList": listId};
    return await _makePostRequest(url, body);
  }

  Future<void> updateCard(String cardId, String newName, [String? desc]) async {
    final url = Uri.parse("$baseUrl/cards/$cardId?key=$apiKey&token=$token");
    final Map<String, dynamic> body = {"name": newName};
    if (desc != null) body['desc'] = desc;
    await _makePutRequest(url, body);
  }

  Future<void> deleteCard(String cardId) async {
    final url = Uri.parse("$baseUrl/cards/$cardId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  Future<void> closeCard(String cardId) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId?key=$apiKey&token=$token");
    await _makePutRequest(url, {'closed': true});
  }

  // --- Card Activities ---

  Future<List<dynamic>> getCardActivities(String cardId) async {
    final url =
        Uri.parse("$baseUrl/cards/$cardId/actions?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  // --- Members ---

  Future<List<dynamic>> getCardMembers(String cardId) async {
    final url =
        Uri.parse("$baseUrl/cards/$cardId/members?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<List<dynamic>> getBoardMembers(String boardId) async {
    final url =
        Uri.parse("$baseUrl/boards/$boardId/members?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<void> addMemberToCard(String cardId, String memberId) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId/idMembers?key=$apiKey&token=$token&value=$memberId");
    try {
      await _makePostRequest(url, {});
      print("Successfully added member $memberId to card $cardId.");
    } on TrelloApiException catch (e) {
      if (e.statusCode == 400 &&
          e.responseBody != null &&
          e.responseBody!.toLowerCase().contains("member is already on the card")) {
        print("Info: Member $memberId is already on card $cardId. No action needed.");
      } else {
        print("Error adding member $memberId to card $cardId: $e");
        rethrow;
      }
    } catch (e) {
      print("Unexpected error adding member $memberId to card $cardId: $e");
      rethrow;
    }
  }

  Future<void> removeMemberFromCard(String cardId, String memberId) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId/idMembers/$memberId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  // --- Labels ---

  Future<List<dynamic>> getBoardLabels(String boardId) async {
    final url =
        Uri.parse("$baseUrl/boards/$boardId/labels?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<void> addLabelToCard(String cardId, String labelId) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId/idLabels?key=$apiKey&token=$token&value=$labelId");
    try {
      await _makePostRequest(url, {});
    } on TrelloApiException catch (e) {
      if (e.statusCode == 400 &&
          e.responseBody != null &&
          e.responseBody!.toLowerCase().contains("label is already on the card")) {
        print("Info: Label $labelId is already on card $cardId.");
      } else {
        print("Error adding label $labelId to card $cardId: $e");
        rethrow;
      }
    } catch (e) {
      print("Unexpected error adding label $labelId to card $cardId: $e");
      rethrow;
    }
  }

  Future<void> removeLabelFromCard(String cardId, String labelId) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId/idLabels/$labelId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  Future<Map<String, dynamic>> createLabel(String boardId, String name, String color) async {
    final url = Uri.parse("$baseUrl/labels?key=$apiKey&token=$token");
    final body = {
      "idBoard": boardId,
      "name": name,
      "color": color
    };
    return await _makePostRequest(url, body);
  }

  // --- Checklist ---

  Future<List<dynamic>> getChecklists(String cardId) async {
    final url =
        Uri.parse("$baseUrl/cards/$cardId/checklists?key=$apiKey&token=$token");
    return await _makeRequest(url);
  }

  Future<Map<String, dynamic>> createChecklist(
      String cardId, String name) async {
    final url = Uri.parse("$baseUrl/checklists?key=$apiKey&token=$token");
    final body = {"name": name, "idCard": cardId};
    return await _makePostRequest(url, body);
  }

  Future<Map<String, dynamic>> addChecklistItem(String checklistId, String name,
      {bool checked = false}) async {
    final url = Uri.parse(
        "$baseUrl/checklists/$checklistId/checkItems?key=$apiKey&token=$token");
    final body = {"name": name, "checked": checked};
    return await _makePostRequest(url, body);
  }

  Future<void> updateChecklistItem(String cardId, String checkItemId,
      {String? name, bool? state}) async {
    final url = Uri.parse(
        "$baseUrl/cards/$cardId/checkItem/$checkItemId?key=$apiKey&token=$token");

    final Map<String, dynamic> body = {};
    if (name != null) {
      body['name'] = name;
    }
    if (state != null) {
      body['state'] = state ? 'complete' : 'incomplete';
    }

    if (body.isEmpty) {
      print("Warning: updateChecklistItem called with no changes specified.");
      return;
    }

    await _makePutRequest(url, body);
  }

  Future<void> deleteChecklistItem(
      String checklistId, String checkItemId) async {
    final url = Uri.parse(
        "$baseUrl/checklists/$checklistId/checkItems/$checkItemId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  Future<void> deleteChecklist(String checklistId) async {
    final url =
        Uri.parse("$baseUrl/checklists/$checklistId?key=$apiKey&token=$token");
    await _makeDeleteRequest(url);
  }

  // --- General Request Methods ---

  Future<dynamic> _makeRequest(Uri url) async {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw TrelloApiException(response.statusCode, "Failed to parse JSON response", responseBody: response.body);
      }
    } else {
      throw TrelloApiException(response.statusCode, "Error making GET request", responseBody: response.body);
    }
  }

  Future<dynamic> _makePostRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        if (response.body.isEmpty) return {};
        throw TrelloApiException(response.statusCode, "Failed to parse JSON response", responseBody: response.body);
      }
    } else {
      throw TrelloApiException(response.statusCode, "Error making POST request", responseBody: response.body);
    }
  }

  Future<dynamic> _makePutRequest(Uri url, Map<String, dynamic> body) async {
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        if (response.body.isEmpty) return {};
        throw TrelloApiException(response.statusCode, "Failed to parse JSON response", responseBody: response.body);
      }
    } else if (response.statusCode == 204) {
      return {};
    } else {
      throw TrelloApiException(response.statusCode, "Error making PUT request", responseBody: response.body);
    }
  }

  Future<void> _makeDeleteRequest(Uri url) async {
    final response = await http.delete(url);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw TrelloApiException(response.statusCode, "Error making DELETE request", responseBody: response.body);
    }
  }

  // --- Calendar ---

  Future<Map<String, dynamic>> createCardWithDetails(
      String listId,
      String name,
      DateTime? startDate,
      DateTime? dueDate,
      String? description) async {
    String? formattedStartDate = startDate?.toIso8601String();
    String? formattedDueDate = dueDate?.toIso8601String();

    final url = Uri.parse('$baseUrl/cards?key=$apiKey&token=$token');

    final Map<String, dynamic> body = {
      'idList': listId,
      'name': name,
      if (formattedStartDate != null) 'start': formattedStartDate,
      if (formattedDueDate != null) 'due': formattedDueDate,
      if (description != null) 'desc': description,
    };

    return await _makePostRequest(url, body);
  }

  Future<void> updateCardDetails(String cardId,
      {DateTime? startDate, DateTime? dueDate, String? description, bool? dueComplete}) async {

    final url = Uri.parse('$baseUrl/cards/$cardId?key=$apiKey&token=$token');
    final Map<String, dynamic> body = {};

    if (startDate != null) body['start'] = startDate.toIso8601String();
    if (dueDate != null) body['due'] = dueDate.toIso8601String();
    if (description != null) body['desc'] = description;
    if (dueComplete != null) body['dueComplete'] = dueComplete;

    if (body.isNotEmpty) {
        await _makePutRequest(url, body);
    } else {
        print("Warning: updateCardDetails called with no details to update.");
    }
  }
}
