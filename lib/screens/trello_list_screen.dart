import 'package:flutter/material.dart';
import '../features/trello_service.dart';
import '../features/card_details_modal.dart';
import 'calendar_page.dart';

class TrelloListScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  const TrelloListScreen(
      {Key? key, required this.boardId, required this.boardName})
      : super(key: key);

  @override
  State<TrelloListScreen> createState() => _TrelloListScreenState();
}

class _TrelloListScreenState extends State<TrelloListScreen> {
  late Future<List<dynamic>> listsFuture;
  final TrelloService trelloService =
      TrelloService(); // Corrected: TrelloService
  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final Map<String, bool> _cardCompletionStatus = {};
  final GlobalKey _updateCardDialogKey = GlobalKey();
  final TextEditingController _cardNameControllerForDialog =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    _cardNameController.dispose();
    _cardNameControllerForDialog.dispose();
    super.dispose();
  }

  void _fetchLists() {
    setState(() {
      listsFuture = trelloService.getLists(widget.boardId);
      _cardCompletionStatus.clear();
    });
  }

  Future<void> _createList() async {
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
                Navigator.of(context).pop();
                _listNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                final listName = _listNameController.text.trim();
                if (listName.isNotEmpty) {
                  await trelloService.createList(widget.boardId, listName);
                  _fetchLists();
                  _listNameController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('List name cannot be empty.'),
                  ));
                }
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

  Future<void> _showUpdateListDialog(String listId, String currentName) async {
    _listNameController.text = currentName;
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
                _listNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Update"),
              onPressed: () async {
                final listName = _listNameController.text.trim();
                if (listName.isNotEmpty) {
                  await trelloService.updateList(listId, listName);
                  _fetchLists();
                  _listNameController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('List name cannot be empty.'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCard(String listId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new card"),
          content: TextField(
            controller: _cardNameController,
            decoration: const InputDecoration(hintText: "Enter card name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _cardNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                await trelloService.createCard(
                    listId, _cardNameController.text.trim());
                _fetchLists();
                _cardNameController.clear();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpdateCardDialog(String cardId, String currentName) async {
    _cardNameControllerForDialog.text = currentName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          key: _updateCardDialogKey,
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Update Card Name"),
              content: TextField(
                controller: _cardNameControllerForDialog,
                decoration:
                    const InputDecoration(hintText: "Enter new card name"),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Update"),
                  onPressed: () async {
                    await _updateCard(
                        cardId, _cardNameControllerForDialog.text);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateCard(String cardId, String newName) async {
    try {
      await trelloService.updateCard(cardId, newName);
      _fetchLists();
    } catch (e) {
      print("Error updating card: $e");
    }
  }

  Future<void> _deleteCard(String cardId) async {
    try {
      await trelloService.deleteCard(cardId);
      _fetchLists();
    } catch (e) {
      print("Error deleting card: $e");
    }
  }

  Future<void> _toggleCardCompletion(String cardId) async {
    setState(() {
      _cardCompletionStatus[cardId] = !(_cardCompletionStatus[cardId] ?? false);
    });
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageCalendrier(
          // Corrected: PageCalendrier
          trelloService: trelloService,
          idTableau: widget.boardId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
        backgroundColor: Colors.blue,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _navigateToCalendar,
          ),
        ],
      ),
      backgroundColor: Colors.grey[200],
      body: RefreshIndicator(
        color: Colors.blue,
        onRefresh: () async {
          _fetchLists();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  onPressed: _createList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Create new list")),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: listsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)));
                  } else if (snapshot.hasData) {
                    final lists = snapshot.data!;
                    return ListView.builder(
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final list = lists[index];
                        return FutureBuilder<List<dynamic>>(
                          future: trelloService.getCards(list['id']),
                          builder: (context, cardSnapshot) {
                            List<Widget> cardWidgets = [];
                            if (cardSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              cardWidgets = [const CircularProgressIndicator()];
                            } else if (cardSnapshot.hasError) {
                              cardWidgets = [
                                Text('Error: ${cardSnapshot.error}')
                              ];
                            } else if (cardSnapshot.hasData) {
                              final cards = cardSnapshot.data;
                              if (cards != null && cards.isNotEmpty) {
                                cardWidgets = cards.map((card) {
                                  final isClosed =
                                      _cardCompletionStatus[card['id']] ??
                                          false;
                                  return ListTile(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        builder: (context) => CardDetailsModal(
                                          card: card,
                                          trelloService: trelloService,
                                          listId: list[
                                              'id'], // Pass the listId here
                                          boardId: widget
                                              .boardId, // Pass the boardId here
                                        ),
                                      );
                                    },
                                    title: Text(
                                      card['name'] ??
                                          "No name", // Add null check here
                                      style: TextStyle(
                                        decoration: isClosed
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: isClosed
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(isClosed
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank),
                                          onPressed: () {
                                            _toggleCardCompletion(card['id']);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.blue[700],
                                          onPressed: () {
                                            _showUpdateCardDialog(
                                                card['id'], card['name']);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          color: Colors.red[700],
                                          onPressed: () {
                                            _deleteCard(card['id']);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              } else {
                                cardWidgets = [const Text("No card found")];
                              }
                            } else {
                              cardWidgets = [const Text("No data found")];
                            }

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                              child: ExpansionTile(
                                title: Text(list['name'] ??
                                    "No name"), // Add null check here
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(children: cardWidgets),
                                  ),
                                  ElevatedButton(
                                      onPressed: () => _createCard(list['id']),
                                      child: const Text("Create new card")),
                                ],
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      color: Colors.blue[700],
                                      onPressed: () {
                                        _showUpdateListDialog(
                                            list['id'], list['name']);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red[700],
                                      onPressed: () {
                                        _deleteList(list['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
