import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class TrelloListScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  const TrelloListScreen({super.key, required this.boardId, required this.boardName});

  @override
  State<TrelloListScreen> createState() => _TrelloListScreenState();
}

class _TrelloListScreenState extends State<TrelloListScreen> {
  late Future<List<dynamic>> listsFuture;

  @override
  void initState() {
    super.initState();
    listsFuture = fetchLists();
  }

  Future<List<dynamic>> fetchLists() async {
    try {
      final String apiKey = Secrets.trelloApiKey;
      final String token = Secrets.trelloToken;
      final url = Uri.parse("https://api.trello.com/1/boards/${widget.boardId}/lists?key=$apiKey&token=$token");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Error getting lists");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      body: FutureBuilder<List<dynamic>>(
        future: listsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(snapshot.data![index]['name']),
                    trailing: const Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data found'));
          }
        },
      ),
    );
  }
}
