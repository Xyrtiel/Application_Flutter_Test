// lib/screens/homepage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/trello_service.dart';
import '../auth/login.dart'; // Cet import est correct si login.dart contient LoginScreen
import '../screens/trello_list_screen.dart';
import 'package:provider/provider.dart';
import '../config/theme_provider.dart';
import '../auth/auth_service.dart';

class Homepage extends StatefulWidget {
  final String? trelloMemberId;
  const Homepage({Key? key, this.trelloMemberId}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // ... (le reste du code de _HomepageState reste identique) ...
   final User? user = FirebaseAuth.instance.currentUser;
   final TrelloService trelloService = TrelloService();
   late Future<List<dynamic>> boardsFuture;
   final TextEditingController _boardNameController = TextEditingController();
   final AuthService _authService = AuthService();

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
                  Navigator.of(context).pop();
                  _boardNameController.clear();
                },
              ),
              TextButton(
                child: const Text("Create"),
                onPressed: () async {
                  final boardName = _boardNameController.text.trim();
                  if (boardName.isNotEmpty) {
                    await trelloService.createBoard(boardName, null);
                    _fetchBoards();
                    _boardNameController.clear();
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

    Future<void> _deleteBoard(String boardId) async {
      try {
        await trelloService.deleteBoard(boardId);
        _fetchBoards();
      } catch (e) {
        print("Error deleting board: $e");
      }
    }

    Future<void> _showUpdateBoardDialog(
        String boardId, String currentName) async {
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
                  _boardNameController.clear();
                },
              ),
              TextButton(
                child: const Text("Update"),
                onPressed: () async {
                  final boardName = _boardNameController.text.trim();
                  if (boardName.isNotEmpty) {
                    await trelloService.updateBoard(boardId, boardName);
                    _fetchBoards();
                    _boardNameController.clear();
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
        MaterialPageRoute(builder: (context) => const LoginScreen()), // <--- MODIFIÉ ICI
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
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
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
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
                onPressed: _createBoard, child: const Text("Create new board")),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: boardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("Error getting boards: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red)),
                    );
                  } else if (snapshot.hasData) {
                    final boards = snapshot.data!;
                    return ListView.builder(
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            title: Text(board['name'] ?? "No Name"),
                            subtitle: Text("ID: ${board['id']}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _showUpdateBoardDialog(
                                        board['id'], board['name']);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteBoard(board['id']);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () async {
                                    if (widget.trelloMemberId != null) {
                                      try {
                                        await trelloService.addMemberToCard(board['id'], widget.trelloMemberId!);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membre ajouté à la carte")));
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'ajout du membre : $e")));
                                      }
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur : TrelloMemberId est null")));
                                    }
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
