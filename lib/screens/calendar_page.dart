import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../features/trello_service.dart'; // Assuming TrelloApiException is defined here

class PageCalendrier extends StatefulWidget {
  final TrelloService trelloService;
  final String idTableau; // This is the BOARD ID

  const PageCalendrier(
      {Key? key, required this.trelloService, required this.idTableau})
      : super(key: key);

  @override
  _PageCalendrierState createState() => _PageCalendrierState();
}

class _PageCalendrierState extends State<PageCalendrier> {
  DateTime _jourSelectionne = DateTime.now();
  DateTime? _jourCourant;
  CalendarFormat _formatCalendrier = CalendarFormat.month;
  Map<DateTime, List<EvenementCalendrier>> _evenements = {};
  final FlutterLocalNotificationsPlugin _pluginNotificationsLocales =
      FlutterLocalNotificationsPlugin();
  final String _idCanal = 'canal_evenement_calendrier';
  final String _nomCanal = 'Rappels d\'événements du calendrier';
  final String _descriptionCanal = 'Rappels pour les événements du calendrier';

  // Store the first list ID to avoid fetching it repeatedly in the dialog
  String? _idPremiereListe;

  @override
  void initState() {
    super.initState();
    _initialiserNotifications();
    _chargerEvenementsEtPremiereListe(); // Load events and find the first list ID
    tz_data.initializeTimeZones();
    _configurerFuseauHoraireLocal();
  }

  Future<void> _configurerFuseauHoraireLocal() async {
    tz.setLocalLocation(tz.local);
  }

  Future<void> _initialiserNotifications() async {
    const AndroidInitializationSettings parametresInitialisationAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings parametresInitialisation =
        InitializationSettings(
      android: parametresInitialisationAndroid,
    );
    await _pluginNotificationsLocales.initialize(parametresInitialisation,
        onDidReceiveNotificationResponse: _onReceptionReponseNotification);
    await _creerCanalNotification();
  }

  Future<void> _creerCanalNotification() async {
    // Check if the widget is mounted before accessing platform channels
    if (!mounted) return;
    // No need to check lifecycle state here, just create the channel
    final AndroidNotificationChannel canal = AndroidNotificationChannel(
      _idCanal,
      _nomCanal,
      description: _descriptionCanal,
      importance: Importance.max,
    );
    await _pluginNotificationsLocales
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  void _onReceptionReponseNotification(
      NotificationResponse notificationResponse) async {
    print('Réponse à la notification : ${notificationResponse.payload}');
    // Handle notification tap logic here if needed
  }

  Future<void> _programmerNotification(EvenementCalendrier evenement) async {
    // Ensure tempsRappel is not null and positive
    if (evenement.tempsRappel != null && evenement.tempsRappel! > 0) {
      // Calculate reminder time based on START date
      final DateTime dateRappel = evenement.dateDebut
          .subtract(Duration(minutes: evenement.tempsRappel!));

      // Check if reminder time is in the future
      if (dateRappel.isAfter(DateTime.now())) {
        print(
            'Programmation de la notification pour : ${evenement.titre} à ${dateRappel}');
        try {
          final AndroidNotificationDetails detailsNotificationAndroid =
              AndroidNotificationDetails(
            _idCanal,
            _nomCanal,
            channelDescription: _descriptionCanal,
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          );
          final NotificationDetails detailsNotification =
              NotificationDetails(android: detailsNotificationAndroid);

          await _pluginNotificationsLocales.zonedSchedule(
            evenement.hashCode, // Use event hashcode as unique ID
            'Rappel : ${evenement.titre}',
            evenement.description.isNotEmpty ? evenement.description : 'Événement à venir.', // Provide default body if description is empty
            tz.TZDateTime.from(dateRappel, tz.local),
            detailsNotification,
            androidAllowWhileIdle: true,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: evenement.idCarte, // Optionally pass card ID as payload
          );
          print('Notification programmée avec succès !');
        } catch (e) {
          print("Erreur lors de la programmation de la notification: $e");
        }
      } else {
        print('L\'heure du rappel (${dateRappel}) est dans le passé. Non programmé.');
      }
    } else {
      // print('L\'heure du rappel n\'est pas définie ou est invalide pour cet événement.');
    }
  }

  // Combined function to load events and find the first list ID
  Future<void> _chargerEvenementsEtPremiereListe() async {
    setState(() {
      _evenements = {}; // Clear existing events
      _idPremiereListe = null; // Reset list ID
    });

    try {
      List<dynamic> listes =
          await widget.trelloService.getLists(widget.idTableau);

      if (listes.isNotEmpty) {
        // Store the ID of the first list found
        _idPremiereListe = listes.first['id'];
        print("Première liste trouvée : $_idPremiereListe");
      } else {
        print("Aucune liste trouvée sur le tableau ${widget.idTableau}");
        // Optionally show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Aucune liste trouvée sur ce tableau."))
           );
        }
      }

      Map<DateTime, List<EvenementCalendrier>> nouveauxEvenements = {};
      for (var liste in listes) {
        List<dynamic> cartes = await widget.trelloService.getCards(liste['id']);
        for (var carte in cartes) {
          DateTime? dateDebut;
          DateTime? dateFin;
          // Trello uses 'dueReminder' (minutes before due, bool, or null)
          // The simple integer 'reminder' field you were using likely doesn't exist directly.
          // We'll attempt to read 'dueReminder' if available, otherwise keep tempsRappel null.
          int? tempsRappel;
          String description = carte['desc'] ?? ""; // Use empty string if null
          String idCarte = carte['id']; // Get card ID

          if (carte['start'] != null) {
            try {
              dateDebut = DateTime.parse(carte['start']).toLocal();
            } catch (e) { print("Error parsing start date for card ${carte['id']}: ${carte['start']}"); }
          }
          if (carte['due'] != null) {
             try {
              dateFin = DateTime.parse(carte['due']).toLocal();
            } catch (e) { print("Error parsing due date for card ${carte['id']}: ${carte['due']}"); }
          }

          // Attempt to read 'dueReminder' - Note: This might need adjustment based on actual API response
          if (carte['dueReminder'] is int) {
             tempsRappel = carte['dueReminder'];
          } else if (carte['dueReminder'] is double) { // Handle potential double values
             tempsRappel = (carte['dueReminder'] as double).toInt();
          }
          // Add more checks if 'dueReminder' can be boolean or other types based on Trello API

          // Only create an event if we have valid start and end dates
          if (dateDebut != null && dateFin != null) {
            // Normalize dates to ignore time for calendar grouping
            DateTime dateDebutFormatee =
                DateTime.utc(dateDebut.year, dateDebut.month, dateDebut.day);
            DateTime dateFinFormatee =
                DateTime.utc(dateFin.year, dateFin.month, dateFin.day);

            EvenementCalendrier nouvelEvenement = EvenementCalendrier(
              idCarte: idCarte, // Store card ID
              titre: carte['name'],
              dateDebut: dateDebut, // Use original date for reminder calculation
              dateFin: dateFin,     // Use original date
              tempsRappel: tempsRappel,
              description: description,
            );

            // Add event to map for each day it spans (using normalized dates)
            for (DateTime jour = dateDebutFormatee;
                jour.isBefore(dateFinFormatee.add(const Duration(days: 1)));
                jour = jour.add(const Duration(days: 1))) {
              // Ensure the key uses UTC to avoid timezone issues with map keys
              DateTime jourCle = DateTime.utc(jour.year, jour.month, jour.day);
              if (nouveauxEvenements[jourCle] == null) {
                nouveauxEvenements[jourCle] = [];
              }
              nouveauxEvenements[jourCle]!.add(nouvelEvenement);
            }
            // Schedule notification for the event
            _programmerNotification(nouvelEvenement);
          }
        }
      }
      // Update state only if the widget is still mounted
      if (mounted) {
        setState(() {
          _evenements = nouveauxEvenements;
        });
      }
    } on TrelloApiException catch (e) {
       print("Erreur Trello lors du chargement des événements : $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Erreur Trello: ${e.message}"))
         );
       }
    }
     catch (e) {
      print("Erreur inattendue lors du chargement des événements Trello : $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Une erreur inattendue est survenue."))
         );
       }
    }
  }

  void _afficherDialogueAjoutEvenement(DateTime jour) {
    // Check if we found a list ID during init
    if (_idPremiereListe == null) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Impossible d'ajouter un événement : aucune liste trouvée."))
       );
       return; // Don't show dialog if no list is available
    }

    String titre = '';
    // Use the selected day, ensuring time is midnight for consistency
    DateTime dateDebut = DateTime(jour.year, jour.month, jour.day);
    DateTime dateFin = DateTime(jour.year, jour.month, jour.day);
    // Reminder time is not set via createCardWithDetails in this service version
    // int? tempsRappel;
    String description = "";

    // Use a StatefulWidget for the dialog content to manage date state locally
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog content
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un événement'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(hintText: 'Titre'),
                      onChanged: (value) => titre = value,
                    ),
                    ListTile(
                      title: Text(
                          'Date de début : ${dateDebut.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? selection = await showDatePicker(
                          context: context,
                          initialDate: dateDebut,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selection != null && selection != dateDebut) {
                          // Use setDialogState to update the dialog's UI
                          setDialogState(() {
                            dateDebut = selection;
                            // Ensure end date is not before start date
                            if (dateFin.isBefore(dateDebut)) {
                               dateFin = dateDebut;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Date de fin : ${dateFin.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? selection = await showDatePicker(
                          context: context,
                          initialDate: dateFin,
                          // Ensure firstDate is not before startDate
                          firstDate: dateDebut,
                          lastDate: DateTime(2100),
                        );
                        if (selection != null && selection != dateFin) {
                          // Use setDialogState to update the dialog's UI
                          setDialogState(() {
                            dateFin = selection;
                          });
                        }
                      },
                    ),
                    // Reminder field removed as it's not passed to createCardWithDetails
                    // TextField(
                    //   decoration: const InputDecoration(
                    //       hintText: 'Temps de rappel (minutes avant)'),
                    //   keyboardType: TextInputType.number,
                    //   onChanged: (value) => tempsRappel = int.tryParse(value),
                    // ),
                    TextField(
                      decoration: const InputDecoration(hintText: 'Description'),
                      maxLines: 3, // Allow multi-line description
                      onChanged: (value) => description = value,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Ajouter'),
                  onPressed: () async {
                    if (titre.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("Le titre ne peut pas être vide."))
                       );
                       return;
                    }

                    // Use the stored _idPremiereListe
                    final String targetListId = _idPremiereListe!;

                    try {
                      // Call createCardWithDetails with the CORRECT 5 arguments
                      Map<String, dynamic> newCard = await widget.trelloService.createCardWithDetails(
                          targetListId,  // 1st: The determined list ID
                          titre,         // 2nd: Name
                          dateDebut,     // 3rd: Start Date
                          dateFin,       // 4th: Due Date
                          description    // 5th: Description (tempsRappel removed)
                      );

                      print("Carte créée avec succès : ${newCard['id']}");

                      // Create local event object for potential immediate notification scheduling
                      // Note: Reminder time is not set here as it wasn't part of creation
                       EvenementCalendrier nouvelEvenement = EvenementCalendrier(
                         idCarte: newCard['id'],
                         titre: titre,
                         dateDebut: dateDebut,
                         dateFin: dateFin,
                         tempsRappel: null, // Reminder not set during creation
                         description: description,
                       );
                      // Optionally schedule notification immediately if needed,
                      // otherwise _chargerEvenementsEtPremiereListe will handle it on refresh.
                      // _programmerNotification(nouvelEvenement);


                      // Refresh the events from Trello to include the new one
                      // Use await to ensure refresh completes before closing dialog if needed
                      await _chargerEvenementsEtPremiereListe();

                      // Close the dialog only if the widget is still mounted
                      if (context.mounted) Navigator.of(context).pop();

                    } on TrelloApiException catch (e) {
                       print("Erreur Trello lors de la création de la carte: $e");
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text("Erreur Trello: ${e.message}"))
                         );
                         // Optionally keep the dialog open on error
                         // Navigator.of(context).pop();
                       }
                    } catch (e) {
                       print("Erreur inattendue lors de la création de la carte: $e");
                       if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Une erreur inattendue est survenue."))
                         );
                         // Optionally keep the dialog open on error
                         // Navigator.of(context).pop();
                       }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        // Add a refresh button?
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.refresh),
        //     onPressed: _chargerEvenementsEtPremiereListe,
        //   ),
        // ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR', // Set locale if needed
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _jourSelectionne,
            calendarFormat: _formatCalendrier,
            // Use UTC for selectedDayPredicate key comparison
            selectedDayPredicate: (jour) {
              return isSameDay(_jourCourant, jour);
            },
            // Use UTC for onDaySelected dates
            onDaySelected: (jourSelectionne, jourCourant) {
              // jourSelectionne is the tapped day, jourCourant is the focused day
              if (!isSameDay(_jourCourant, jourSelectionne)) {
                setState(() {
                  // Set both _jourCourant (selected) and _jourSelectionne (focused)
                  _jourCourant = DateTime.utc(jourSelectionne.year, jourSelectionne.month, jourSelectionne.day);
                  _jourSelectionne = DateTime.utc(jourCourant.year, jourCourant.month, jourCourant.day);
                });
              }
            },
            onFormatChanged: (format) {
              if (_formatCalendrier != format) {
                setState(() {
                  _formatCalendrier = format;
                });
              }
            },
            onPageChanged: (jourFocus) {
               // Update focused day, but not necessarily selected day
               setState(() {
                 _jourSelectionne = DateTime.utc(jourFocus.year, jourFocus.month, jourFocus.day);
               });
            },
            // Use UTC for eventLoader key comparison
            eventLoader: (jour) {
              // Ensure the key uses UTC
              DateTime jourCle = DateTime.utc(jour.year, jour.month, jour.day);
              return _evenements[jourCle] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary, // Use colorScheme
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary), // Use colorScheme
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5), // Use colorScheme
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary), // Use colorScheme
                  ),
                );
              },
              markerBuilder: (context, date, evenements) {
                if (evenements.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _construireMarqueurEvenements(date, evenements),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          // Display events for the selected day (_jourCourant)
          if (_jourCourant != null)
            Expanded(
              child: ListView.builder(
                // Use the UTC version of _jourCourant as the key
                itemCount: _evenements[DateTime.utc(_jourCourant!.year, _jourCourant!.month, _jourCourant!.day)]?.length ?? 0,
                itemBuilder: (context, index) {
                  final evenement = _evenements[DateTime.utc(_jourCourant!.year, _jourCourant!.month, _jourCourant!.day)]![index];
                  return Card( // Wrap ListTile in a Card for better visuals
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: ListTile(
                      title: Text(evenement.titre),
                      subtitle: Text(
                        'Début: ${evenement.dateDebut.toLocal().toString().split(' ')[0]}\n'
                        'Fin: ${evenement.dateFin.toLocal().toString().split(' ')[0]}\n'
                        '${evenement.description}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Add trailing icon or action?
                      // trailing: Icon(Icons.info_outline),
                      // onTap: () { /* Show event details? */ },
                    ),
                  );
                },
              ),
            ),
          // Show message if no day is selected or no events for the selected day
           if (_jourCourant == null)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text("Sélectionnez un jour pour voir les événements."),
             ),
           if (_jourCourant != null && (_evenements[DateTime.utc(_jourCourant!.year, _jourCourant!.month, _jourCourant!.day)]?.isEmpty ?? true))
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text("Aucun événement pour ce jour."),
             ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _afficherDialogueAjoutEvenement(_jourCourant ?? DateTime.now()),
        tooltip: 'Ajouter un événement', // Add tooltip
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _construireMarqueurEvenements(DateTime date, List evenements) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.secondary, // Use colorScheme secondary
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${evenements.length}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary, // Use colorScheme
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Updated Event class to include card ID
class EvenementCalendrier {
  final String idCarte; // Added card ID
  final String titre;
  final DateTime dateDebut; // Store original DateTime with time
  final DateTime dateFin;   // Store original DateTime with time
  final int? tempsRappel; // Corresponds to Trello's dueReminder (minutes before due)
  final String description;

  EvenementCalendrier({
    required this.idCarte,
    required this.titre,
    required this.dateDebut,
    required this.dateFin,
    this.tempsRappel,
    required this.description,
  });

  // Override hashCode and == if using this class in Sets or as Map keys directly
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvenementCalendrier &&
          runtimeType == other.runtimeType &&
          idCarte == other.idCarte;

  @override
  int get hashCode => idCarte.hashCode;
}
