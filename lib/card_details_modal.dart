import 'package:flutter/material.dart';
import 'trello_service.dart';

class CardDetailsModal extends StatefulWidget {
  final Map<String, dynamic> card;
  final TrelloService trelloService;

  const CardDetailsModal({Key? key, required this.card, required this.trelloService}) : super(key: key);

  @override
  State<CardDetailsModal> createState() => _CardDetailsModalState();
}

class _CardDetailsModalState extends State<CardDetailsModal> {
  TextEditingController? _descriptionController;
  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.card['desc'] ?? "");
  }

  @override
  void dispose() {
    _descriptionController?.dispose();
    super.dispose();
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
                  Text(widget.card['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(hintText: "Add a more detailed description..."),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await widget.trelloService.updateCard(widget.card['id'], widget.card['name'], _descriptionController?.text);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const ListTile(
                title: Text("No activity yet."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
