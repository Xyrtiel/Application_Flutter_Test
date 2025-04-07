import 'package:flutter/material.dart';
import 'trello_service.dart';

class ChecklistModal extends StatefulWidget {
  final String cardId;
  final TrelloService trelloService;

  const ChecklistModal({Key? key, required this.cardId, required this.trelloService}) : super(key: key);

  @override
  State<ChecklistModal> createState() => _ChecklistModalState();
}

class _ChecklistModalState extends State<ChecklistModal> {
  late Future<List<dynamic>> _checklistsFuture;
  final TextEditingController _checklistNameController = TextEditingController();
   final TextEditingController _checklistItemNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChecklists();
  }

  @override
  void dispose() {
    _checklistNameController.dispose();
    _checklistItemNameController.dispose();
    super.dispose();
  }

  void _fetchChecklists() {
    setState(() {
      _checklistsFuture = widget.trelloService.getChecklists(widget.cardId);
    });
  }

  Future<void> _createChecklist() async {
     await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new checklist"),
          content: TextField(
            controller: _checklistNameController,
            decoration: const InputDecoration(hintText: "Enter checklist name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _checklistNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () async {
                final checklistName = _checklistNameController.text.trim();
                if (checklistName.isNotEmpty) {
                  await widget.trelloService.createChecklist(widget.cardId, checklistName);
                  _fetchChecklists();
                  _checklistNameController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                  if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Checklist name cannot be empty.'),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addChecklistItem(String checklistId) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add new item to checklist"),
          content: TextField(
            controller: _checklistItemNameController,
            decoration: const InputDecoration(hintText: "Enter item name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                _checklistItemNameController.clear();
              },
            ),
            TextButton(
              child: const Text("Add"),
              onPressed: () async {
                 final checklistItemName = _checklistItemNameController.text.trim();
                if (checklistItemName.isNotEmpty) {
                  await widget.trelloService.addChecklistItem(checklistId, checklistItemName);
                  _fetchChecklists();
                  _checklistItemNameController.clear();
                  if (context.mounted) Navigator.of(context).pop();
                } else {
                   if (context.mounted) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Checklist item name cannot be empty.'),
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
                  const Text("Checklists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              ElevatedButton(onPressed: _createChecklist, child: const Text("Create new checklist")),
               FutureBuilder<List<dynamic>>(
                future: _checklistsFuture,
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
                          final checklist = snapshot.data![index];
                           return ExpansionTile(
                                title: Text(checklist['name'] ?? "No Name"),
                                children: [
                                    ElevatedButton(
                                      onPressed: () => _addChecklistItem(checklist['id']),
                                      child: const Text("Add new item"),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: checklist['checkItems'].length,
                                      itemBuilder: (context, itemIndex) {
                                        final item = checklist['checkItems'][itemIndex];
                                        return ListTile(
                                           title: Text(item['name'] ?? "No name"),
                                          leading: Checkbox(
                                            value: item['state'] == "complete",
                                            onChanged: (bool? newValue) async {
                                                await widget.trelloService.updateChecklistItem(checklist['id'], item['id'], checked: newValue);
                                                _fetchChecklists();
                                            },
                                          ),
                                           trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () async {
                                                await widget.trelloService.deleteChecklistItem(checklist['id'], item['id']);
                                                 _fetchChecklists();
                                              },
                                            ),
                                        );
                                      },
                                    ),
                                  IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        await widget.trelloService.deleteChecklist(checklist['id']);
                                         _fetchChecklists();
                                      },
                                    ),
                                ],
                            );
                        });
                  } else {
                    return const ListTile(
                      title: Text("No checklist on this board."),
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
