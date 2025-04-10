import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates
import 'trello_service.dart'; // Assure-toi que TrelloApiException est défini ici

class ActivityModal extends StatefulWidget {
  final String cardId;
  final TrelloService trelloService;

  const ActivityModal({Key? key, required this.cardId, required this.trelloService}) : super(key: key);

  @override
  State<ActivityModal> createState() => _ActivityModalState();
}

class _ActivityModalState extends State<ActivityModal> {
  late Future<List<dynamic>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  void _fetchActivities() {
    setState(() {
      // Récupère les activités et inverse la liste pour afficher les plus récentes en premier
      _activityFuture = widget.trelloService.getCardActivities(widget.cardId)
          .then((activities) => activities.reversed.toList()) // Inverse la liste ici
          .catchError((error) {
            print("Error fetching activities: $error");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error loading activities: ${error is TrelloApiException ? error.message : error.toString()}"))
              );
            }
            return <dynamic>[]; // Retourne une liste vide en cas d'erreur
          });
    });
  }

  // Fonction pour construire une tuile représentant une activité
  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final String type = activity['type'] ?? 'unknown';
    final Map<String, dynamic>? data = activity['data'];
    final Map<String, dynamic>? memberCreator = activity['memberCreator'];
    final String creatorName = memberCreator?['fullName'] ?? 'Unknown User';
    // Trello API V1 avatar URL construction (adjust size parameter '30' or '50' or '170')
    final String? avatarHash = memberCreator?['avatarHash'];
    final String avatarUrl = avatarHash != null
        ? 'https://trello-members.s3.amazonaws.com/$avatarHash/50.png' // Use 50px size
        : ''; // Placeholder or default avatar URL

    DateTime? date = DateTime.tryParse(activity['date'] ?? '');
    String formattedDate = date != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal()) // Format JJ Mois AAAA, HH:mm
        : 'Unknown date';

    String description = _getActivityDescription(type, data, creatorName);

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300, // Placeholder background
        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 20) : null, // Placeholder icon
      ),
      title: Text(description, style: const TextStyle(fontSize: 14)),
      subtitle: Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      dense: true,
    );
  }

  // Fonction pour générer une description lisible de l'activité
  String _getActivityDescription(String type, Map<String, dynamic>? data, String creatorName) {
    if (data == null) return '$creatorName performed an action ($type)';

    switch (type) {
      case 'commentCard':
        return '$creatorName commented: "${data['text'] ?? ''}"';
      case 'updateCard':
        if (data['old']?.containsKey('due') ?? false) {
          return '$creatorName updated the due date.';
        } else if (data['old']?.containsKey('start') ?? false) {
           return '$creatorName updated the start date.';
        } else if (data['old']?.containsKey('desc') ?? false) {
          return '$creatorName updated the description.';
        } else if (data['old']?.containsKey('idList') ?? false) {
          return '$creatorName moved this card from "${data['listBefore']?['name'] ?? '?'}" to "${data['listAfter']?['name'] ?? '?'}"';
        } else if (data['old']?.containsKey('closed') ?? false) {
          bool wasClosed = data['old']['closed'] ?? false;
          return '$creatorName ${wasClosed ? 'sent this card to the board' : 'archived this card'}';
        } else if (data['card']?['name'] != null && data['old']?.containsKey('name') == true) {
           return '$creatorName renamed this card to "${data['card']['name']}" (from "${data['old']['name']}")';
        }
        return '$creatorName updated this card.'; // Generic update
      case 'addMemberToCard':
        return '$creatorName added ${data['member']?['name'] ?? 'a member'} to this card.';
      case 'removeMemberFromCard':
        return '$creatorName removed ${data['member']?['name'] ?? 'a member'} from this card.';
      case 'createCard':
        return '$creatorName created this card.';
      case 'addAttachmentToCard':
         return '$creatorName added an attachment: "${data['attachment']?['name'] ?? '?'}"';
      case 'deleteAttachmentFromCard':
         return '$creatorName deleted an attachment: "${data['attachment']?['name'] ?? '?'}"';
      case 'addChecklistToCard':
         return '$creatorName added the checklist "${data['checklist']?['name'] ?? '?'}"';
      case 'removeChecklistFromCard':
         return '$creatorName removed the checklist "${data['checklist']?['name'] ?? '?'}"';
       case 'updateCheckItemStateOnCard':
         String state = data['checkItem']?['state'] ?? '?';
         String itemName = data['checkItem']?['name'] ?? '?';
         String checklistName = data['checklist']?['name'] ?? '?';
         return '$creatorName marked "$itemName" ${state == 'complete' ? 'complete' : 'incomplete'} on checklist "$checklistName"';
      // Ajoutez d'autres types d'actions Trello ici si nécessaire
      default:
        return '$creatorName performed an action: $type';
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
                  const Text("Card Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Flexible( // Permet à la ListView de prendre l'espace restant
                child: FutureBuilder<List<dynamic>>(
                  future: _activityFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      // L'erreur est déjà affichée via ScaffoldMessenger dans _fetchActivities
                      return const Center(child: Text("Could not load activity."));
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final activities = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityTile(activities[index]);
                        },
                      );
                    } else {
                      return const Center(child: Text("No activity found for this card."));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
