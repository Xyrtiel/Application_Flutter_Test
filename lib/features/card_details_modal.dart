import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import pour le formatage des dates
import 'trello_service.dart';
import 'member_modal.dart';
import 'label_modal.dart';
import 'checklist_modal.dart';
import '../screens/calendar_page.dart';

class CardDetailsModal extends StatefulWidget {
  final Map<String, dynamic> card;
  final TrelloService trelloService;
  final String listId;
  final String boardId;

  const CardDetailsModal({
    Key? key,
    required this.card,
    required this.trelloService,
    required this.listId,
    required this.boardId,
  }) : super(key: key);

  @override
  State<CardDetailsModal> createState() => _CardDetailsModalState();
}

class _CardDetailsModalState extends State<CardDetailsModal> {
  late TextEditingController _descriptionController;
  bool _isEditingDescription = false;
  late Future<List<dynamic>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.card['desc'] ?? "");
    _fetchActivities(); // Charge les activités
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _fetchActivities() {
    setState(() {
      _activitiesFuture = widget.trelloService.getCardActivities(widget.card['id'])
          .then((activities) => activities.reversed.toList()) // Inverse pour afficher les plus récentes en premier
          .catchError((error) {
            print("Error fetching activities: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading activities: ${error is TrelloApiException ? error.message : error.toString()}"))
              );
            }
            return <dynamic>[];
          });
    });
  }


  void _toggleEditDescription() async {
    final shouldSave = _isEditingDescription;
    setState(() {
      _isEditingDescription = !_isEditingDescription;
    });

    if (shouldSave) {
      try {
        await widget.trelloService.updateCard(widget.card['id'], widget.card['name'],
            _descriptionController.text);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Description sauvegardée."), duration: Duration(seconds: 2))
            );
         }
         // Mettre à jour l'objet card local si nécessaire
         widget.card['desc'] = _descriptionController.text;

      } on TrelloApiException catch (e) {
         print("Error saving description: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur sauvegarde description: ${e.message}"))
            );
         }
      } catch (e) {
         print("Unexpected error saving description: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Une erreur inattendue est survenue."))
            );
         }
      }
    }
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageCalendrier(
          trelloService: widget.trelloService,
          idTableau: widget.boardId,
        ),
      ),
    );
  }

  // --- Fonctions d'aide pour l'activité ---

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final String type = activity['type'] ?? 'unknown';
    final Map<String, dynamic>? data = activity['data'];
    final Map<String, dynamic>? memberCreator = activity['memberCreator'];
    final String creatorName = memberCreator?['fullName'] ?? 'Utilisateur inconnu';
    final String? avatarHash = memberCreator?['avatarHash'];
    final String avatarUrl = avatarHash != null
        ? 'https://trello-members.s3.amazonaws.com/$avatarHash/50.png'
        : '';

    DateTime? date = DateTime.tryParse(activity['date'] ?? '');
    String formattedDate = date != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(date.toLocal())
        : 'Date inconnue';

    String description = _getActivityDescription(type, data, creatorName);

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 20) : null,
      ),
      title: Text(description, style: const TextStyle(fontSize: 14)),
      subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      dense: true,
    );
  }

  // *** MODIFIÉ ICI ***
  String _getActivityDescription(String type, Map<String, dynamic>? data, String creatorName) {
    if (data == null) return '$creatorName a effectué une action ($type)';

    switch (type) {
      case 'commentCard':
        return '$creatorName a commenté : "${data['text'] ?? ''}"';
      case 'updateCard':
        if (data['old']?.containsKey('due') ?? false) {
          return '$creatorName a mis à jour la date d\'échéance.';
        } else if (data['old']?.containsKey('start') ?? false) {
           return '$creatorName a mis à jour la date de début.';
        } else if (data['old']?.containsKey('desc') ?? false) {
          return '$creatorName a mis à jour la description.';
        } else if (data['old']?.containsKey('idList') ?? false) {
          return '$creatorName a déplacé cette carte de "${data['listBefore']?['name'] ?? '?'}" vers "${data['listAfter']?['name'] ?? '?'}"';
        } else if (data['old']?.containsKey('closed') ?? false) {
          bool wasClosed = data['old']['closed'] ?? false;
          return '$creatorName ${wasClosed ? 'a désarchivé cette carte' : 'a archivé cette carte'}';
        } else if (data['card']?['name'] != null && data['old']?.containsKey('name') == true) {
           return '$creatorName a renommé cette carte en "${data['card']['name']}" (anciennement "${data['old']['name']}")';
        }
        return '$creatorName a mis à jour cette carte.';
      case 'addMemberToCard':
        return '$creatorName a ajouté ${data['member']?['name'] ?? 'un membre'} à cette carte.';
      case 'removeMemberFromCard':
        return '$creatorName a retiré ${data['member']?['name'] ?? 'un membre'} de cette carte.';
      // *** MODIFICATION ICI ***
      case 'createCard':
        String listName = data['list']?['name'] ?? '?'; // Récupère le nom de la liste
        return '$creatorName a créé cette carte dans la liste "$listName"'; // Ajoute le nom de la liste
      // *** FIN MODIFICATION ***
      case 'addAttachmentToCard':
         return '$creatorName a ajouté une pièce jointe : "${data['attachment']?['name'] ?? '?'}"';
      case 'deleteAttachmentFromCard':
         return '$creatorName a supprimé une pièce jointe : "${data['attachment']?['name'] ?? '?'}"';
      case 'addChecklistToCard':
         return '$creatorName a ajouté la checklist "${data['checklist']?['name'] ?? '?'}"';
      case 'removeChecklistFromCard':
         return '$creatorName a supprimé la checklist "${data['checklist']?['name'] ?? '?'}"';
       case 'updateCheckItemStateOnCard':
         String state = data['checkItem']?['state'] ?? '?';
         String itemName = data['checkItem']?['name'] ?? '?';
         String checklistName = data['checklist']?['name'] ?? '?';
         return '$creatorName a marqué "$itemName" comme ${state == 'complete' ? 'terminé' : 'non terminé'} dans la checklist "$checklistName"';
      default:
        return '$creatorName a effectué une action : $type';
    }
  }
  // --- Fin des fonctions d'aide ---


  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: ConstrainedBox(
         constraints: BoxConstraints(
           maxHeight: MediaQuery.of(context).size.height * 0.9,
         ),
         child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Contenu Principal (Gauche) ---
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entête
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.credit_card, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(widget.card['name'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Fermer',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Icon(Icons.description_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Description",
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  _isEditingDescription
                                      ? TextFormField(
                                          controller: _descriptionController,
                                          maxLines: 5,
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                              hintText: "Ajouter une description...",
                                              border: OutlineInputBorder()
                                              ),
                                        )
                                      : InkWell(
                                          onTap: _toggleEditDescription,
                                          child: Container(
                                            width: double.infinity,
                                            constraints: const BoxConstraints(minHeight: 50),
                                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                            child: Text(
                                              _descriptionController.text.isEmpty
                                                  ? "Ajouter une description..."
                                                  : _descriptionController.text,
                                              style: TextStyle(color: _descriptionController.text.isEmpty ? Colors.grey : null),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 10),
                                  if (_isEditingDescription)
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _toggleEditDescription,
                                          child: const Text('Sauvegarder'),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () {
                                             _descriptionController.text = widget.card['desc'] ?? "";
                                             setState(() => _isEditingDescription = false);
                                          },
                                          child: const Text('Annuler'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                         ],
                      ),
                      const SizedBox(height: 20),

                      // Activité
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            const Icon(Icons.list_alt, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Activité",
                                      style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  FutureBuilder<List<dynamic>>(
                                    future: _activitiesFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ));
                                      } else if (snapshot.hasError) {
                                        return const ListTile(
                                          dense: true,
                                          leading: Icon(Icons.error_outline, color: Colors.red),
                                          title: Text("Impossible de charger l'activité."),
                                        );
                                      } else if (snapshot.hasData &&
                                          snapshot.data!.isNotEmpty) {
                                        return ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: snapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              return _buildActivityTile(snapshot.data![index]);
                                            });
                                      } else {
                                        return const ListTile(
                                          dense: true,
                                          title: Text("Aucune activité pour le moment."),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                         ],
                       ),
                    ],
                  ),
                ),
              ),

              // --- Barre Latérale (Droite) ---
              const VerticalDivider(),
              SizedBox(
                width: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Ajouter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildSidebarButton(
                      icon: Icons.person_add_outlined,
                      label: "Membres",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => MemberModal(
                            cardId: widget.card['id'],
                            trelloService: widget.trelloService,
                            boardId: widget.boardId,
                          ),
                        );
                      },
                    ),
                    _buildSidebarButton(
                      icon: Icons.label_outline,
                      label: "Étiquettes",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => LabelModal(
                            cardId: widget.card['id'],
                            trelloService: widget.trelloService,
                            listId: widget.listId,
                            boardId: widget.boardId,
                          ),
                        );
                      },
                    ),
                    _buildSidebarButton(
                      icon: Icons.checklist_outlined,
                      label: "Checklist",
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ChecklistModal(
                            cardId: widget.card['id'],
                            trelloService: widget.trelloService,
                          ),
                        );
                      },
                    ),
                    _buildSidebarButton(
                      icon: Icons.date_range_outlined,
                      label: "Dates",
                      onPressed: _navigateToCalendar,
                    ),
                    _buildSidebarButton(
                        icon: Icons.attach_file_outlined,
                        label: "Pièce jointe",
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fonctionnalité Pièce jointe non implémentée."))
                           );
                        },
                    ),
                     const Divider(height: 20),
                     const Text("Actions", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                     const SizedBox(height: 10),
                  ],
                ),
              )
            ],
          ),
                 ),
       ),
    );
  }

  Widget _buildSidebarButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(90, 36),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
    );
  }
}
