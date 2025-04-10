import 'package:flutter/material.dart';
import 'trello_service.dart'; // Assuming TrelloApiException is defined here

// --- Helper Functions for Color Mapping ---

// Function to convert Trello color name to Flutter Color object
Color trelloColorToFlutterColor(String? trelloColorName) {
  switch (trelloColorName?.toLowerCase()) {
    // Standard Trello colors
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'red':
      return Colors.red;
    case 'purple':
      return Colors.purple;
    case 'blue':
      return Colors.blue;
    case 'sky': // Trello light blue
      return Colors.lightBlue.shade400; // Adjusted for better visibility
    case 'lime': // Trello light green
      return Colors.lightGreen.shade500; // Adjusted
    case 'pink':
      return Colors.pink;
    case 'black':
      return Colors.black87;

    // Trello "subtle" colors (adjust Flutter colors as needed)
    case 'green_subtle':
      return Colors.green.shade100;
    case 'yellow_subtle':
      return Colors.yellow.shade100;
    case 'orange_subtle':
      return Colors.orange.shade100;
    case 'red_subtle':
      return Colors.red.shade100;
    case 'purple_subtle':
      return Colors.purple.shade100;
    case 'blue_subtle':
      return Colors.blue.shade100;
    case 'sky_subtle':
      return Colors.lightBlue.shade100;
    case 'lime_subtle':
      return Colors.lightGreen.shade100;
    case 'pink_subtle':
      return Colors.pink.shade100;
    case 'black_subtle':
      return Colors.grey.shade300;

    // Default case (null or unknown color)
    case null:
    default:
      return Colors.grey.shade400; // Default grey for labels without a color
  }
}

// Optional function to determine text color (black or white) for good contrast
Color getTextColorForBackground(Color backgroundColor) {
  // Calculate the luminance of the background color
  // If it's dark, return white, otherwise return black
  if (ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark) {
    return Colors.white;
  }
  // Use a slightly off-black for better readability on light backgrounds?
  return Colors.black87;
}

// --- End Helper Functions ---


class LabelModal extends StatefulWidget {
  final String cardId;
  final TrelloService trelloService;
  final String listId; // listId might not be needed if card data includes labels directly
  final String boardId;

  const LabelModal({Key? key, required this.cardId, required this.trelloService, required this.listId, required this.boardId}) : super(key: key);

  @override
  State<LabelModal> createState() => _LabelModalState();
}

class _LabelModalState extends State<LabelModal> {
  late Future<List<dynamic>> _boardLabelsFuture;
  // Store card labels directly from card data if possible, otherwise fetch separately
  List<dynamic> _cardLabelIds = []; // Store only IDs for checking existence
  bool _isLoadingCardLabels = true;
  bool _isUpdating = false; // Flag for API calls

  final TextEditingController _labelNameController = TextEditingController();
  // Define the list of available Trello color names
  final List<String> _availableTrelloColors = [
    'green', 'yellow', 'orange', 'red', 'purple', 'blue', 'sky', 'lime', 'pink', 'black',
    'green_subtle', 'yellow_subtle', 'orange_subtle', 'red_subtle', 'purple_subtle', 'blue_subtle', 'sky_subtle', 'lime_subtle', 'pink_subtle', 'black_subtle',
    'null' // Representing the default grey color
  ];
  String _selectedColorValue = 'green'; // Default selected color NAME for creation

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _labelNameController.dispose();
    super.dispose();
  }

  // Load both board labels and card labels
  Future<void> _loadData() async {
     setState(() {
       _isLoadingCardLabels = true; // Start loading card labels
       // Fetch board labels (keep this future for the builder)
       _boardLabelsFuture = widget.trelloService.getBoardLabels(widget.boardId)
         .catchError((error) {
            print("Error fetching board labels: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading board labels: ${error is TrelloApiException ? error.message : error.toString()}"))
              );
            }
            return <dynamic>[]; // Return empty on error
         });
     });
     await _fetchCardLabels(); // Fetch card labels separately
  }


  // Fetch the labels currently assigned to the card
  // OPTIMIZATION: Ideally, the card data passed to this modal would already contain its labels.
  // If not, fetching all cards in the list is inefficient. Consider adding a getCardDetails endpoint.
  Future<void> _fetchCardLabels() async {
    setState(() => _isLoadingCardLabels = true);
    try {
      // Assuming getCards fetches full card details including 'idLabels'
      List<dynamic> cards = await widget.trelloService.getCards(widget.listId);
      dynamic cardData = cards.firstWhere((card) => card['id'] == widget.cardId, orElse: () => null);

      if (mounted) {
        setState(() {
          if (cardData != null && cardData['idLabels'] is List) {
            _cardLabelIds = List<dynamic>.from(cardData['idLabels']);
          } else {
             _cardLabelIds = []; // Reset if card not found or no labels
             print("Card data or idLabels not found for card ${widget.cardId}");
          }
          _isLoadingCardLabels = false;
        });
      }
    } catch (e) {
       print("Error fetching card labels: $e");
       if (mounted) {
         setState(() => _isLoadingCardLabels = false);
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading card labels: ${e is TrelloApiException ? e.message : e.toString()}"))
          );
       }
    }
  }

  // Toggle label on the card (add or remove)
  Future<void> _toggleLabel(String labelId, bool isCurrentlyAdded) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      if (isCurrentlyAdded) {
        await widget.trelloService.removeLabelFromCard(widget.cardId, labelId);
        // Update local state immediately for responsiveness
        if (mounted) {
          setState(() {
            _cardLabelIds.remove(labelId);
          });
        }
      } else {
        await widget.trelloService.addLabelToCard(widget.cardId, labelId);
         // Update local state immediately
        if (mounted) {
          setState(() {
            _cardLabelIds.add(labelId);
          });
        }
      }
      // Optional: Refetch card labels for absolute certainty, but immediate update is usually enough
      // await _fetchCardLabels();
    } on TrelloApiException catch (e) {
       print("Error toggling label $labelId: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating label: ${e.message}"))
          );
       }
       // Consider reverting local state change on error
    } catch (e) {
       print("Unexpected error toggling label $labelId: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("An unexpected error occurred."))
          );
       }
       // Consider reverting local state change on error
    } finally {
       if (mounted) setState(() => _isUpdating = false);
    }
  }


  // Create a new label on the board
  Future<void> _createLabel() async {
     if (_isUpdating) return;

    // Use a local variable for the color within the dialog's state
    String dialogSelectedColorValue = _selectedColorValue; // Initialize with current state

    final created = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage the dropdown state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Create new label"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _labelNameController,
                    decoration: const InputDecoration(hintText: "Enter label name"),
                    autofocus: true,
                  ),
                  const SizedBox(height: 15),
                  // Enhanced Dropdown with color preview
                  DropdownButtonFormField<String>(
                    value: dialogSelectedColorValue,
                    decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder()),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        // Update the color within the dialog's state
                        setDialogState(() {
                          dialogSelectedColorValue = newValue;
                        });
                      }
                    },
                    items: _availableTrelloColors
                        .map<DropdownMenuItem<String>>((String value) {
                      // Use 'null' string to represent the default grey color
                      String? colorNameForMapping = (value == 'null') ? null : value;
                      Color displayColor = trelloColorToFlutterColor(colorNameForMapping);
                      Color textColor = getTextColorForBackground(displayColor);

                      return DropdownMenuItem<String>(
                        value: value, // Store the string value ('green', 'null', etc.)
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: displayColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade400, width: 0.5)
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(value == 'null' ? 'Default (Grey)' : value, style: TextStyle(color: textColor)),
                          ],
                        ),
                         // Apply background color to the item itself for better visual cue
                        // Note: This might not render perfectly on all platforms/dropdown implementations
                         // style: DropdownMenuItemStyle(backgroundColor: displayColor), // Requires custom styling or package
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop(false); // Indicate not created
                    _labelNameController.clear();
                  },
                ),
                TextButton(
                  child: const Text("Create"),
                  onPressed: () async {
                    final labelName = _labelNameController.text.trim();
                    if (labelName.isNotEmpty) {
                      setState(() => _isUpdating = true); // Set updating flag
                      try {
                        // Use the color selected in the dialog
                        // Convert 'null' string back to null for the API call if needed by your service
                        String colorToSend = (dialogSelectedColorValue == 'null') ? 'null' : dialogSelectedColorValue;
                        // OR if your API expects null directly:
                        // String? colorToSend = (dialogSelectedColorValue == 'null') ? null : dialogSelectedColorValue;

                        await widget.trelloService.createLabel(widget.boardId, labelName, colorToSend);

                        _labelNameController.clear();
                        if (context.mounted) Navigator.of(context).pop(true); // Indicate created

                      } on TrelloApiException catch (e) {
                         print("Error creating label: $e");
                         if (context.mounted) {
                           Navigator.of(context).pop(false); // Indicate not created
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Error creating label: ${e.message}"))
                           );
                         }
                      } catch (e) {
                         print("Unexpected error creating label: $e");
                         if (context.mounted) {
                           Navigator.of(context).pop(false); // Indicate not created
                           ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text("An unexpected error occurred."))
                           );
                         }
                      } finally {
                         // Reset updating flag when done
                         if (mounted) setState(() => _isUpdating = false);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Label name cannot be empty.'),
                        duration: Duration(seconds: 2),
                      ));
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );

     // If a label was created, refresh the board labels list
     if (created == true && mounted) {
        setState(() {
          _boardLabelsFuture = widget.trelloService.getBoardLabels(widget.boardId);
        });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       insetPadding: const EdgeInsets.all(10.0),
       child: ConstrainedBox(
         constraints: BoxConstraints(
           maxHeight: MediaQuery.of(context).size.height * 0.8,
         ),
         child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Create new label"),
                  onPressed: _isUpdating ? null : _createLabel,
                ),
              ),
              const SizedBox(height: 10),
              const Text("Board Labels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(),
              // Show loading indicator while fetching card labels initially
              if (_isLoadingCardLabels)
                 const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text("Loading card labels..."))),

              // Display board labels once card labels are loaded (or failed)
              if (!_isLoadingCardLabels)
                Flexible(
                  child: SingleChildScrollView(
                    child: FutureBuilder<List<dynamic>>(
                      future: _boardLabelsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ));
                        } else if (snapshot.hasError) {
                           // Error handled in _loadData, show message if list is empty
                           if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const ListTile(
                                leading: Icon(Icons.error_outline, color: Colors.red),
                                title: Text("Could not load board labels."),
                              );
                           }
                        }

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final label = snapshot.data![index];
                                final String labelId = label['id'];
                                final String? trelloColorName = label['color'];
                                final String labelName = label['name'] ?? "No name";

                                // Determine Flutter color and text color
                                final Color bgColor = trelloColorToFlutterColor(trelloColorName);
                                final Color textColor = getTextColorForBackground(bgColor);

                                // Check if this label is currently on the card
                                final bool isAdded = _cardLabelIds.contains(labelId);

                                return ListTile(
                                    // *** MODIFICATION: Add colored leading indicator ***
                                    leading: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(4), // Slightly rounded square
                                         border: Border.all(color: Colors.grey.shade400, width: 0.5)
                                      ),
                                    ),
                                    title: Text(labelName, style: TextStyle(color: textColor)), // Use contrast text color
                                    // Optional: Set tile background color (can be too much)
                                    // tileColor: bgColor.withOpacity(0.1),
                                    trailing: IconButton(
                                      tooltip: isAdded ? 'Remove from card' : 'Add to card',
                                      icon: Icon(
                                        isAdded ? Icons.check_circle : Icons.add_circle_outline,
                                        color: isAdded ? Colors.green : Colors.grey,
                                      ),
                                      // Disable button while updating
                                      onPressed: _isUpdating ? null : () => _toggleLabel(labelId, isAdded),
                                    ));
                              });
                        } else {
                          return const ListTile(
                            title: Text("No labels found on this board."),
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
