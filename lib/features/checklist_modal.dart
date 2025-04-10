import 'package:flutter/material.dart';
import 'trello_service.dart'; // Assuming TrelloApiException is defined here

class ChecklistModal extends StatefulWidget {
  final String cardId; // This is the CARD ID
  final TrelloService trelloService;

  const ChecklistModal({Key? key, required this.cardId, required this.trelloService}) : super(key: key);

  @override
  State<ChecklistModal> createState() => _ChecklistModalState();
}

class _ChecklistModalState extends State<ChecklistModal> {
  late Future<List<dynamic>> _checklistsFuture;
  final TextEditingController _checklistNameController = TextEditingController();
  final TextEditingController _checklistItemNameController = TextEditingController();
  bool _isUpdating = false; // Flag to prevent rapid updates

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

  // Fetches checklists and handles potential errors
  void _fetchChecklists() {
    setState(() {
      _checklistsFuture = widget.trelloService.getChecklists(widget.cardId)
          .catchError((error) {
            print("Error fetching checklists: $error");
            // Show error message to user if mounted
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading checklists: ${error is TrelloApiException ? error.message : error.toString()}"))
              );
            }
            // Return an empty list or rethrow to indicate failure
            return <dynamic>[]; // Return empty list on error to avoid breaking FutureBuilder
          });
    });
  }

  // Creates a new checklist
  Future<void> _createChecklist() async {
     // Prevent creating if already updating
     if (_isUpdating) return;
     setState(() => _isUpdating = true);

     await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create new checklist"),
          content: TextField(
            controller: _checklistNameController,
            decoration: const InputDecoration(hintText: "Enter checklist name"),
            autofocus: true,
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
                  try {
                    await widget.trelloService.createChecklist(widget.cardId, checklistName);
                    _checklistNameController.clear();
                    if (context.mounted) Navigator.of(context).pop(); // Close dialog first
                    _fetchChecklists(); // Then refresh
                  } on TrelloApiException catch (e) {
                     print("Error creating checklist: $e");
                     if (context.mounted) {
                       Navigator.of(context).pop(); // Close dialog on error too
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Error creating checklist: ${e.message}"))
                       );
                     }
                  } catch (e) {
                     print("Unexpected error creating checklist: $e");
                     if (context.mounted) {
                       Navigator.of(context).pop();
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("An unexpected error occurred."))
                       );
                     }
                  }
                } else {
                  // Keep dialog open but show message if name is empty
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Checklist name cannot be empty.'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
    // Reset updating flag when dialog closes or operation finishes
    if (mounted) setState(() => _isUpdating = false);
  }

  // Adds an item to a specific checklist
  Future<void> _addChecklistItem(String checklistId) async {
     if (_isUpdating) return;
     setState(() => _isUpdating = true);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add new item to checklist"),
          content: TextField(
            controller: _checklistItemNameController,
            decoration: const InputDecoration(hintText: "Enter item name"),
             autofocus: true,
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
                   try {
                      await widget.trelloService.addChecklistItem(checklistId, checklistItemName);
                      _checklistItemNameController.clear();
                      if (context.mounted) Navigator.of(context).pop(); // Close dialog first
                      _fetchChecklists(); // Then refresh
                   } on TrelloApiException catch (e) {
                     print("Error adding checklist item: $e");
                     if (context.mounted) {
                       Navigator.of(context).pop();
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Error adding item: ${e.message}"))
                       );
                     }
                   } catch (e) {
                     print("Unexpected error adding checklist item: $e");
                     if (context.mounted) {
                       Navigator.of(context).pop();
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("An unexpected error occurred."))
                       );
                     }
                   }
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Checklist item name cannot be empty.'),
                     duration: Duration(seconds: 2),
                  ));
                }
              },
            ),
          ],
        );
      },
    );
     if (mounted) setState(() => _isUpdating = false);
  }

  // Updates the state (complete/incomplete) of a checklist item
  Future<void> _updateItemState(String checkItemId, bool? newState) async {
    if (_isUpdating || newState == null) return; // Don't update if already updating or state is null
    setState(() => _isUpdating = true);

    try {
      // *** CORRECTION IS HERE ***
      // Use widget.cardId (1st arg), item['id'] (2nd arg), and state: newValue (named arg)
      await widget.trelloService.updateChecklistItem(
        widget.cardId, // Pass the CARD ID
        checkItemId,   // Pass the CHECK ITEM ID
        state: newState // Use the 'state' named parameter
      );
      _fetchChecklists(); // Refresh list on success
    } on TrelloApiException catch (e) {
      print("Error updating checklist item state: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating item: ${e.message}"))
        );
      }
      // Optionally revert UI change here if needed
    } catch (e) {
      print("Unexpected error updating checklist item state: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An unexpected error occurred."))
        );
      }
      // Optionally revert UI change here if needed
    } finally {
       // Ensure the flag is reset even if there's an error
       if (mounted) setState(() => _isUpdating = false);
    }
  }

  // Deletes a checklist item
  Future<void> _deleteChecklistItem(String checklistId, String checkItemId) async {
     if (_isUpdating) return;
     setState(() => _isUpdating = true);
     try {
        await widget.trelloService.deleteChecklistItem(checklistId, checkItemId);
        _fetchChecklists(); // Refresh list on success
     } on TrelloApiException catch (e) {
        print("Error deleting checklist item: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting item: ${e.message}"))
          );
        }
     } catch (e) {
        print("Unexpected error deleting checklist item: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("An unexpected error occurred."))
          );
        }
     } finally {
        if (mounted) setState(() => _isUpdating = false);
     }
  }

   // Deletes an entire checklist
  Future<void> _deleteChecklist(String checklistId) async {
     if (_isUpdating) return;

     // Optional: Confirmation dialog
     final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Checklist?'),
          content: const Text('Are you sure you want to delete this entire checklist and all its items?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ) ?? false; // Default to false if dialog dismissed

     if (!confirm) return;

     setState(() => _isUpdating = true);
     try {
        await widget.trelloService.deleteChecklist(checklistId);
        _fetchChecklists(); // Refresh list on success
     } on TrelloApiException catch (e) {
        print("Error deleting checklist: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting checklist: ${e.message}"))
          );
        }
     } catch (e) {
        print("Unexpected error deleting checklist: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("An unexpected error occurred."))
          );
        }
     } finally {
        if (mounted) setState(() => _isUpdating = false);
     }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10.0), // Add padding around the dialog
      child: ConstrainedBox( // Limit dialog height
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Max 80% of screen height
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make column height fit content
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_task),
                  label: const Text("Create new checklist"),
                  onPressed: _isUpdating ? null : _createChecklist, // Disable button while updating
                ),
              ),
              // Use Flexible + SingleChildScrollView for the list part
              Flexible(
                child: SingleChildScrollView(
                  child: FutureBuilder<List<dynamic>>(
                    future: _checklistsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ));
                      } else if (snapshot.hasError) {
                        // Error is handled in _fetchChecklists, show message if list is empty
                         if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const ListTile(
                              leading: Icon(Icons.error_outline, color: Colors.red),
                              title: Text("Could not load checklists."),
                            );
                         }
                         // If data exists despite error, show it (might be stale)
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                            shrinkWrap: true, // Important within SingleChildScrollView
                            physics: const NeverScrollableScrollPhysics(), // Disable inner scrolling
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final checklist = snapshot.data![index];
                              // Ensure checkItems is a List
                              final checkItems = (checklist['checkItems'] is List)
                                  ? checklist['checkItems'] as List<dynamic>
                                  : <dynamic>[];

                              return Card( // Wrap ExpansionTile in a Card
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ExpansionTile(
                                    title: Text(checklist['name'] ?? "Unnamed Checklist"),
                                    trailing: IconButton( // Add delete checklist button here
                                      icon: Icon(Icons.delete_outline, color: Colors.red.withOpacity(0.7)),
                                      tooltip: "Delete Checklist",
                                      onPressed: _isUpdating ? null : () => _deleteChecklist(checklist['id']),
                                    ),
                                    children: [
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                                          child: ElevatedButton.icon(
                                            icon: const Icon(Icons.add),
                                            label: const Text("Add new item"),
                                            onPressed: _isUpdating ? null : () => _addChecklistItem(checklist['id']),
                                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)), // Make button wider
                                          ),
                                        ),
                                        // Handle case where checkItems might be empty
                                        if (checkItems.isEmpty)
                                          const ListTile(
                                            dense: true,
                                            title: Text("No items in this checklist.", style: TextStyle(fontStyle: FontStyle.italic)),
                                          ),
                                        if (checkItems.isNotEmpty)
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: checkItems.length,
                                            itemBuilder: (context, itemIndex) {
                                              final item = checkItems[itemIndex];
                                              final bool isComplete = item['state'] == "complete";
                                              return ListTile(
                                                dense: true, // Make items less tall
                                                title: Text(
                                                  item['name'] ?? "Unnamed Item",
                                                  style: TextStyle(
                                                    decoration: isComplete ? TextDecoration.lineThrough : null,
                                                    color: isComplete ? Colors.grey : null,
                                                  ),
                                                ),
                                                leading: Checkbox(
                                                  value: isComplete,
                                                  onChanged: _isUpdating ? null : (bool? newValue) {
                                                    // Call the corrected update function
                                                    _updateItemState(item['id'], newValue);
                                                  },
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                                                  tooltip: "Delete Item",
                                                  onPressed: _isUpdating ? null : () => _deleteChecklistItem(checklist['id'], item['id']),
                                                ),
                                              );
                                            },
                                          ),
                                        // Removed redundant delete button from here
                                    ],
                                ),
                              );
                            });
                      } else {
                        // Handle case where snapshot has data but it's empty
                        return const ListTile(
                          title: Text("No checklists found on this card."),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
