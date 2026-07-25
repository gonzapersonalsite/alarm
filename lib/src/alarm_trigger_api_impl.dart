import 'package:alarm/alarm.dart';
import 'package:alarm/src/generated/platform_bindings.g.dart';
import 'package:logging/logging.dart';

/// Callback that is called when an alarm starts ringing.
typedef AlarmRangCallback = void Function(AlarmSettings alarm);

/// Callback that is called when an alarm is stopped.
typedef AlarmStoppedCallback = void Function(int alarmId);

/// Callback that is called when an alarm is deferred on the host side.
typedef AlarmSnoozedCallback = void Function(int alarmId, DateTime nextRingAt);

/// Implements the API that handles calls coming from the host platform.
class AlarmTriggerApiImpl extends AlarmTriggerApi {
  AlarmTriggerApiImpl._({
    required AlarmRangCallback alarmRang,
    required AlarmStoppedCallback alarmStopped,
    required AlarmSnoozedCallback alarmSnoozed,
  })  : _alarmRang = alarmRang,
        _alarmStopped = alarmStopped,
        _alarmSnoozed = alarmSnoozed,
        super() {
    AlarmTriggerApi.setUp(this);
  }

  static final _log = Logger('AlarmTriggerApiImpl');

  /// Cached instance of [AlarmTriggerApiImpl]
  static AlarmTriggerApiImpl? _instance;

  final AlarmRangCallback _alarmRang;

  final AlarmStoppedCallback _alarmStopped;

  final AlarmSnoozedCallback _alarmSnoozed;

  /// Ensures that this Dart isolate is listening for method calls that may come
  /// from the host platform.
  static void ensureInitialized({
    required AlarmRangCallback alarmRang,
    required AlarmStoppedCallback alarmStopped,
    required AlarmSnoozedCallback alarmSnoozed,
  }) {
    _instance ??= AlarmTriggerApiImpl._(
      alarmRang: alarmRang,
      alarmStopped: alarmStopped,
      alarmSnoozed: alarmSnoozed,
    );
  }

  @override
  Future<void> alarmRang(int alarmId) async {
    final settings = await Alarm.getAlarm(alarmId);
    if (settings == null) {
      _log.severe('Alarm with id $alarmId started ringing but the settings '
          'object could not be found. Please report this issue at: '
          'https://github.com/gdelataillade/alarm/issues');
      return;
    }
    _log.info('Alarm with id $alarmId started ringing.');
    _alarmRang(settings);
  }

  @override
  Future<void> alarmStopped(int alarmId) async {
    _log.info('Alarm with id $alarmId stopped.');
    _alarmStopped(alarmId);
  }

  @override
  Future<void> alarmSnoozed(int alarmId, int millisecondsSinceEpoch) async {
    final nextRingAt =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    _log.info('Alarm with id $alarmId snoozed until $nextRingAt.');
    _alarmSnoozed(alarmId, nextRingAt);
  }
}
