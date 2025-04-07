import 'package:flutter/material.dart';
import 'trello_service.dart';

class MemberModal extends StatefulWidget {
  final String cardId;
  final TrelloService trelloService;
  final String boardId; // Add boardId parameter

  const MemberModal({Key? key, required this.cardId, required this.trelloService, required this.boardId}) : super(key: key);

  @override
  State<MemberModal> createState() => _MemberModalState();
}

class _MemberModalState extends State<MemberModal> {
  late Future<List<dynamic>> _cardMembersFuture;
  late Future<List<dynamic>> _boardMembersFuture;

  @override
  void initState() {
    super.initState();
    _cardMembersFuture = widget.trelloService.getCardMembers(widget.cardId);
    _boardMembersFuture = widget.trelloService.getBoardMembers(widget.boardId); // Use the dynamic boardId
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Members", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Card Members", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FutureBuilder<List<dynamic>>(
                future: _cardMembersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final member = snapshot.data![index];
                          return ListTile(
                              title: Text(member['fullName'] ?? "No name"),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  widget.trelloService.removeMemberFromCard(widget.cardId, member['id']);
                                  setState(() {
                                    _cardMembersFuture = widget.trelloService.getCardMembers(widget.cardId);
                                  });
                                },
                              ));
                        });
                  } else {
                    return const ListTile(
                      title: Text("No member on this card."),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text("All Members", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FutureBuilder<List<dynamic>>(
                future: _boardMembersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final member = snapshot.data![index];
                          return ListTile(
                              title: Text(member['fullName'] ?? "No name"),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  widget.trelloService.addMemberToCard(widget.cardId, member['id']);
                                  setState(() {
                                    _cardMembersFuture = widget.trelloService.getCardMembers(widget.cardId);
                                  });
                                },
                              ));
                        });
                  } else {
                    return const ListTile(
                      title: Text("No member on this board."),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
