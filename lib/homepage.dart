import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'trello_service.dart';
import 'login.dart';
import 'trello_list_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TrelloService trelloService = TrelloService();
  late Future<List<dynamic>> boardsFuture;

  @override
  void initState() {
    super.initState();
    boardsFuture = trelloService.getBoards();
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
    return Scaffold(
      appBar: AppBar(title: const Text("My Trello Boards")),
      body: Column(
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
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(snapshot.data![index]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("ID: ${snapshot.data![index]['id']}"),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrelloListScreen(
                                  boardId: snapshot.data![index]['id'],
                                  boardName: snapshot.data![index]['name'],
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
      floatingActionButton: FloatingActionButton(
        onPressed: signOut,
        child: const Icon(Icons.logout),
      ),
    );
  }
}
