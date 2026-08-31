import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

/// Ajout d'un rendez-vous de visite au calendrier de l'appareil + rappel
/// local (notification programmée) le jour de la visite.
class RappelService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialise = false;

  static Future<void> initialiser() async {
    if (_initialise) return;
    _initialise = true;

    tzdata.initializeTimeZones();

    const params = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(params);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static String _horodatageCal(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year}${p(d.month)}${p(d.day)}T${p(d.hour)}${p(d.minute)}00';
  }

  /// ouvre l'agenda (Google Calendar / navigateur) avec l'événement pré-rempli
  static Future<bool> ajouterAuCalendrier({
    required String titreBien,
    required String nomLocataire,
    required DateTime dateVisite,
  }) async {
    final debut = _horodatageCal(dateVisite);
    final fin = _horodatageCal(dateVisite.add(const Duration(hours: 1)));
    final uri = Uri.parse(
      'https://calendar.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=${Uri.encodeComponent('Visite — $titreBien')}'
      '&dates=$debut/$fin'
      '&details=${Uri.encodeComponent('Rendez-vous de visite via LogeFacile avec $nomLocataire.')}'
      '&location=${Uri.encodeComponent(titreBien)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// programme une notification locale ~2 h avant la visite (ou tout de suite
  /// si la visite est dans moins de 2 h, utile pour la démo)
  static Future<void> programmerRappel({
    required int id,
    required String titreBien,
    required DateTime dateVisite,
  }) async {
    await initialiser();

    var quand = dateVisite.subtract(const Duration(hours: 2));
    final maintenant = DateTime.now();
    if (quand.isBefore(maintenant)) {
      quand = maintenant.add(const Duration(seconds: 10));
    }

    final heure =
        '${dateVisite.hour.toString().padLeft(2, '0')}h'
        '${dateVisite.minute.toString().padLeft(2, '0')}';

    await _plugin.zonedSchedule(
      id,
      'Rappel de visite',
      'Visite de « $titreBien » aujourd\'hui à $heure.',
      tz.TZDateTime.from(quand, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'rappels_visite',
          'Rappels de visite',
          channelDescription:
              'Rappel le jour d\'un rendez-vous de visite accepté',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> annulerRappel(int id) => _plugin.cancel(id);
}
