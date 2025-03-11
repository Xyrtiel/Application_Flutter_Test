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
  bool _isEditingDescription = false;
  late Future<List<dynamic>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.card['desc'] ?? "");
    _activitiesFuture = widget.trelloService.getCardActivities(widget.card['id']);
  }

  @override
  void dispose() {
    _descriptionController?.dispose();
    super.dispose();
  }

  void _toggleEditDescription() {
    setState(() {
      _isEditingDescription = !_isEditingDescription;
      if (!_isEditingDescription) {
        widget.trelloService.updateCard(widget.card['id'], widget.card['name'], _descriptionController?.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    _isEditingDescription
                        ? TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(hintText: "Add a more detailed description..."),
                          )
                        : GestureDetector(
                            onTap: _toggleEditDescription,
                            child: Text(_descriptionController!.text.isEmpty ? "Add a more detailed description..." : _descriptionController!.text),
                          ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_isEditingDescription)
                          TextButton(
                            onPressed: _toggleEditDescription,
                            child: const Text('Cancel'),
                          ),
                        if (_isEditingDescription)
                          ElevatedButton(
                            onPressed: _toggleEditDescription,
                            child: const Text('Sauvegarder'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    FutureBuilder<List<dynamic>>(
                      future: _activitiesFuture,
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
                                final activity = snapshot.data![index];
                                return ListTile(
                                  title: Text(activity['type'] ?? "No type"),
                                  subtitle: Text(activity['date'] ?? "No date"),
                                );
                              });
                        } else {
                          return const ListTile(
                            title: Text("No activity yet."),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.person_add), tooltip: "Membres"),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.label_outline), tooltip: "Etiquette"),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.checklist), tooltip: "Checklist"),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.date_range), tooltip: "Dates"),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file), tooltip: "Pièce Jointe"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
