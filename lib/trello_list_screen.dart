import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secrets.dart';
import 'trello_service.dart';

class TrelloListScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  const TrelloListScreen({Key? key, required this.boardId, required this.boardName}) : super(key: key);

  @override
  State<TrelloListScreen> createState() => _TrelloListScreenState();
}

class _TrelloListScreenState extends State<TrelloListScreen> {
  late Future<List<dynamic>> listsFuture;
  final TrelloService trelloService = TrelloService();
  final TextEditingController _listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  void _fetchLists() {
    setState(() {
      listsFuture = trelloService.getLists(widget.boardId);
    });
  }

  Future<void> _createList() async {
    // Show a dialog to get the list name
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new list"),
          content: TextField(
            controller: _listNameController,
            decoration: const InputDecoration(hintText: "Enter list name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _listNameController.clear(); // Clear the text field
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                await trelloService.createList(widget.boardId, _listNameController.text.trim());
                _fetchLists(); // Refresh the list
                _listNameController.clear(); // Clear the text field
                if (context.mounted) Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
  Future<void> _deleteList(String listId) async {
    try {
      await trelloService.deleteList(listId);
      _fetchLists();
    } catch (e) {
      print("Error deleting list: $e");
    }
  }

   Future<void> _showUpdateListDialog(String listId) async {
    _listNameController.text = ""; // Clear the text field
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update list name"),
          content: TextField(
            controller: _listNameController,
            decoration: const InputDecoration(hintText: "Enter new list name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _listNameController.clear(); // Clear the text field
              },
            ),
            TextButton(
              child: const Text("Update"),
              onPressed: () async {
                await trelloService.updateList(listId, _listNameController.text);
               _fetchLists(); // Refetch the list after update
                _listNameController.clear(); // Clear the text field
                 if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.boardName)),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchLists();
        },
        child: Column(
          children: [
            ElevatedButton(onPressed: _createList, child: const Text("Create new list")),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
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
                        final list = snapshot.data![index];
                        return Card(
                          child: ListTile(
                            title: Text(list['name']),
                             trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showUpdateListDialog(list['id']);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteList(list['id']);
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text('No data found'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
