import 'package:flutter/material.dart';
import 'trello_service.dart';

class LabelModal extends StatefulWidget {
  final String cardId;
  final TrelloService trelloService;
  final String listId;
  final String boardId;

  const LabelModal({Key? key, required this.cardId, required this.trelloService, required this.listId, required this.boardId}) : super(key: key);

  @override
  State<LabelModal> createState() => _LabelModalState();
}

class _LabelModalState extends State<LabelModal> {
  late Future<List<dynamic>> _boardLabelsFuture;
  late List<dynamic> _cardLabels = [];
  final TextEditingController _labelNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _boardLabelsFuture = widget.trelloService.getBoardLabels(widget.boardId);
    _fetchCardLabels();
  }

  @override
  void dispose() {
    _labelNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchCardLabels() async {
    List<dynamic> cards = await widget.trelloService.getCards(widget.listId);
    String id = widget.cardId;
    for (int i = 0; i < cards.length; i++) {
      if (cards[i]['id'] == id) {
        setState(() {
          _cardLabels = cards[i]['idLabels'];
        });
      }
    }
  }

  Future<void> _createLabel() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new label"),
          content: TextField(
            controller: _labelNameController,
            decoration: const InputDecoration(hintText: "Enter label name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _labelNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                final labelName = _labelNameController.text.trim();
                if (labelName.isNotEmpty) { // Check if the name is not empty
                  await widget.trelloService.createLabel(widget.boardId, labelName, "green");
                  setState(() {
                    _boardLabelsFuture = widget.trelloService.getBoardLabels(widget.boardId);
                  });
                  _labelNameController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  // Handle the case where the name is empty (e.g., show an error message)
                  if(context.mounted) Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Label name cannot be empty.'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
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
                  const Text("Labels", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              ElevatedButton(onPressed: _createLabel, child: const Text("Create new label")),
              const SizedBox(height: 20),
              const Text("All labels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              FutureBuilder<List<dynamic>>(
                future: _boardLabelsFuture,
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
                          final label = snapshot.data![index];
                          bool isAdded = _cardLabels.contains(label['id']);
                          return ListTile(
                              title: Text(label['name'] ?? "No name"),
                              trailing: IconButton(
                                icon: Icon(isAdded ? Icons.remove_circle_outline : Icons.add_circle_outline),
                                onPressed: () {
                                  if (isAdded) {
                                    widget.trelloService.removeLabelFromCard(widget.cardId, label['id']);
                                  } else {
                                    widget.trelloService.addLabelToCard(widget.cardId, label['id']);
                                  }
                                  setState(() {
                                    _fetchCardLabels();
                                  });
                                },
                              ));
                        });
                  } else {
                    return const ListTile(
                      title: Text("No label on this board."),
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
