import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../features/trello_service.dart';

class PageCalendrier extends StatefulWidget {
  final TrelloService trelloService;
  final String idTableau;

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
  final String _idCanal = 'canal_evenement_calendrier'; // ID unique du canal
  final String _nomCanal =
      'Rappels d\'événements du calendrier'; // Nom du canal
  final String _descriptionCanal =
      'Rappels pour les événements du calendrier'; // Description du canal

  @override
  void initState() {
    super.initState();
    _initialiserNotifications();
    _chargerEvenementsTrello();
    tz_data.initializeTimeZones();
    _configurerFuseauHoraireLocal();
  }

  Future<void> _configurerFuseauHoraireLocal() async {
    tz.setLocalLocation(tz.local);
  }

  Future<void> _initialiserNotifications() async {
    const AndroidInitializationSettings parametresInitialisationAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Utilisez l'icône de votre application
    final InitializationSettings parametresInitialisation =
        InitializationSettings(
      android: parametresInitialisationAndroid,
    );
    await _pluginNotificationsLocales.initialize(parametresInitialisation,
        onDidReceiveNotificationResponse: _onReceptionReponseNotification);
    // Créer le canal de notification
    await _creerCanalNotification();
  }

  Future<void> _creerCanalNotification() async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
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
  }

  void _onReceptionReponseNotification(
      NotificationResponse notificationResponse) async {
    // Gérer la réponse à la notification ici
    print('Réponse à la notification : ${notificationResponse.payload}');
  }

  Future<void> _programmerNotification(EvenementCalendrier evenement) async {
    if (evenement.tempsRappel != null) {
      final DateTime dateRappel = evenement.dateDebut
          .subtract(Duration(minutes: evenement.tempsRappel!));
      if (dateRappel.isAfter(DateTime.now())) {
        print(
            'Programmation de la notification pour : ${evenement.titre} à ${dateRappel}');
        final AndroidNotificationDetails detailsNotificationAndroid =
            AndroidNotificationDetails(
          _idCanal, // Utiliser l'ID du canal
          _nomCanal,
          channelDescription: _descriptionCanal,
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        final NotificationDetails detailsNotification =
            NotificationDetails(android: detailsNotificationAndroid);
        await _pluginNotificationsLocales.zonedSchedule(
          evenement.hashCode, // Utiliser un ID unique pour chaque événement
          'Rappel : ${evenement.titre}',
          evenement.description,
          tz.TZDateTime.from(dateRappel, tz.local),
          detailsNotification,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('Notification programmée avec succès !');
      } else {
        print('L\'heure du rappel est dans le passé. Non programmé.');
      }
    } else {
      print('L\'heure du rappel n\'est pas définie pour cet événement.');
    }
  }

  Future<void> _chargerEvenementsTrello() async {
    try {
      List<dynamic> listes =
          await widget.trelloService.getLists(widget.idTableau);
      Map<DateTime, List<EvenementCalendrier>> nouveauxEvenements = {};
      for (var liste in listes) {
        List<dynamic> cartes = await widget.trelloService.getCards(liste['id']);
        for (var carte in cartes) {
          DateTime? dateDebut;
          DateTime? dateFin;
          int? tempsRappel;
          String description = "";

          if (carte['start'] != null) {
            dateDebut = DateTime.parse(carte['start']);
          }
          if (carte['due'] != null) {
            dateFin = DateTime.parse(carte['due']);
          }
          if (carte['reminder'] != null) {
            tempsRappel = carte['reminder'];
          }
          if (carte['desc'] != null) {
            description = carte['desc'];
          }

          if (dateDebut != null && dateFin != null) {
            DateTime dateDebutFormatee =
                DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
            DateTime dateFinFormatee =
                DateTime(dateFin.year, dateFin.month, dateFin.day);
            EvenementCalendrier nouvelEvenement = EvenementCalendrier(
              titre: carte['name'],
              dateDebut: dateDebutFormatee,
              dateFin: dateFinFormatee,
              tempsRappel: tempsRappel,
              description: description,
            );
            for (DateTime jour = dateDebutFormatee;
                jour.isBefore(dateFinFormatee.add(const Duration(days: 1)));
                jour = jour.add(const Duration(days: 1))) {
              if (nouveauxEvenements[jour] == null) {
                nouveauxEvenements[jour] = [];
              }
              nouveauxEvenements[jour]!.add(nouvelEvenement);
            }
            _programmerNotification(nouvelEvenement);
          }
        }
      }
      setState(() {
        _evenements = nouveauxEvenements;
      });
    } catch (e) {
      print("Erreur lors du chargement des événements Trello : $e");
    }
  }

  void _afficherDialogueAjoutEvenement(DateTime jour) {
    String titre = '';
    DateTime dateDebut = jour;
    DateTime dateFin = jour;
    int? tempsRappel;
    String description = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                      setState(() {
                        dateDebut = selection;
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
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selection != null && selection != dateFin) {
                      setState(() {
                        dateFin = selection;
                      });
                    }
                  },
                ),
                TextField(
                  decoration: const InputDecoration(
                      hintText: 'Temps de rappel (minutes avant)'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => tempsRappel = int.tryParse(value),
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Description'),
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
                if (titre.isNotEmpty) {
                  EvenementCalendrier nouvelEvenement = EvenementCalendrier(
                    titre: titre,
                    dateDebut: dateDebut,
                    dateFin: dateFin,
                    tempsRappel: tempsRappel,
                    description: description,
                  );
                  await widget.trelloService.createCardWithDetails(
                      widget.idTableau,
                      titre,
                      dateDebut,
                      dateFin,
                      tempsRappel,
                      description);
                  _programmerNotification(nouvelEvenement);
                  setState(() {
                    _chargerEvenementsTrello();
                  });
                  if (context.mounted) Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _jourSelectionne,
            calendarFormat: _formatCalendrier,
            selectedDayPredicate: (jour) {
              return isSameDay(_jourCourant, jour);
            },
            onDaySelected: (jourSelectionne, jourCourant) {
              if (!isSameDay(_jourCourant, jourSelectionne)) {
                setState(() {
                  _jourCourant = jourSelectionne;
                  _jourSelectionne = jourCourant;
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
            onPageChanged: (jourSelectionne) {
              _jourSelectionne = jourSelectionne;
            },
            eventLoader: (jour) {
              return _evenements[jour] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: const TextStyle(color: Colors.white),
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
          const SizedBox(height: 20),
          if (_jourCourant != null)
            Expanded(
              child: ListView.builder(
                itemCount: _evenements[_jourCourant]?.length ?? 0,
                itemBuilder: (context, index) {
                  final evenement = _evenements[_jourCourant]![index];
                  return ListTile(
                    title: Text(evenement.titre),
                    subtitle: Text(evenement.description),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _afficherDialogueAjoutEvenement(_jourCourant ?? DateTime.now()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _construireMarqueurEvenements(DateTime date, List evenements) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).primaryColor,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${evenements.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
          ),
        ),
      ),
    );
  }
}

class EvenementCalendrier {
  final String titre;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int? tempsRappel;
  final String description;

  EvenementCalendrier({
    required this.titre,
    required this.dateDebut,
    required this.dateFin,
    this.tempsRappel,
    required this.description,
  });
}
