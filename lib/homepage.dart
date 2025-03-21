import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trello_service.dart';
import 'login.dart';
import 'trello_list_screen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TrelloService trelloService = TrelloService();
  late Future<List<dynamic>> boardsFuture;
  final TextEditingController _boardNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBoards();
  }

  @override
  void dispose() {
    _boardNameController.dispose();
    super.dispose();
  }

  void _fetchBoards() {
    setState(() {
      boardsFuture = trelloService.getBoards();
    });
  }

  Future<void> _createBoard() async {
    // Show a dialog to get the board name
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new board"),
          content: TextField(
            controller: _boardNameController,
            decoration: const InputDecoration(hintText: "Enter board name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _boardNameController.clear(); // Clear the text field
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                final boardName = _boardNameController.text.trim();
                if (boardName.isNotEmpty) {
                  await trelloService.createBoard(boardName, null);
                  _fetchBoards(); // Refresh the list
                  _boardNameController.clear(); // Clear the text field
                  if (context.mounted) Navigator.of(context).pop(); // Close the dialog
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Board name cannot be empty.'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBoard(String boardId) async {
    try {
      await trelloService.deleteBoard(boardId);
      _fetchBoards();
    } catch (e) {
      print("Error deleting board: $e");
    }
  }

  Future<void> _showUpdateBoardDialog(String boardId, String currentName) async {
    _boardNameController.text = currentName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update board name"),
          content: TextField(
            controller: _boardNameController,
            decoration: const InputDecoration(hintText: "Enter new board name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _boardNameController.clear(); // Clear the text field
              },
            ),
            TextButton(
              child: const Text("Update"),
              onPressed: () async {
                final boardName = _boardNameController.text.trim();
                if (boardName.isNotEmpty) {
                  await trelloService.updateBoard(boardId, boardName);
                  _fetchBoards(); // Refresh the list after update
                  _boardNameController.clear(); // Clear the text field
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Board name cannot be empty.'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Trello Boards"),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchBoards();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                user != null
                    ? (user?.isAnonymous ?? false
                        ? 'Anonymous user connected'
                        : 'Email: ${user?.email ?? "Not available"}')
                    : 'No user connected',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(onPressed: _createBoard, child: const Text("Create new board")),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: boardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Error getting boards: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                    );
                  } else if (snapshot.hasData) {
                    final boards = snapshot.data!;
                    return ListView.builder(
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(board['name'] ?? "No Name"),
                            subtitle: Text("ID: ${board['id']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showUpdateBoardDialog(board['id'], board['name']);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteBoard(board['id']);
                                  },
                                ),
                                const Icon(Icons.arrow_forward_ios),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrelloListScreen(
                                    boardId: board['id'],
                                    boardName: board['name'],
                                  ),
                                ),
                              );
                            },
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
      floatingActionButton: FloatingActionButton(
        onPressed: signOut,
        child: const Icon(Icons.logout),
      ),
    );
  }
}
