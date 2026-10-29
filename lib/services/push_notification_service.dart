import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vibenance/stubs/http_client_stub.dart'
    if (dart.library.io) 'package:vibenance/stubs/http_client_native.dart';

http.Client get _httpClient => getPlatformHttpClient();

final Logger _log = Logger('PushNotificationService');

const String _fcmTokenKey = 'FCM_TOKEN';
const String _pushEnabledKey = 'push_notifications_enabled';
const String _importRunnerUrlKey = 'import_runner_url';
const String _lastSyncAtKey = 'fcm_last_sync_at';
const String _lastSyncErrorKey = 'fcm_last_sync_error';
const String _channelId = 'fcm_movements';
const String _channelName = 'Nuevos movimientos';
const String _channelDescription =
    'Notificaciones push de nuevos movimientos importados';

Future<FlutterLocalNotificationsPlugin> _initNotificationsPlugin() async {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
    ),
  );
  return plugin;
}

Future<bool> _pushNotificationsEnabled() async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  return await prefs.getBool(_pushEnabledKey) ?? true;
}

String _defaultRunnerUrl(Uri? firefly) {
  if (firefly == null) {
    return "";
  }
  final List<String> labels = firefly.host.split(".");
  if (labels.length >= 3) {
    labels[0] = "import-runner";
    return "${firefly.scheme}://${labels.join(".")}";
  }
  return "";
}

Future<String?> _getImportRunnerUrl({String? host}) async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  if (host != null && host.isNotEmpty) {
    try {
      return _defaultRunnerUrl(Uri.parse(host));
    } on FormatException {
      _log.warning('Cannot derive import runner URL from host $host');
      return null;
    }
  }
  final String? stored = await prefs.getString(_importRunnerUrlKey);
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }
  final String? storedHost = await const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  ).read(key: 'api_host');
  if (storedHost == null || storedHost.isEmpty) {
    return null;
  }
  try {
    return _defaultRunnerUrl(Uri.parse(storedHost));
  } on FormatException {
    return null;
  }
}

Future<String?> _readStoredApiKey() {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  ).read(key: 'api_key');
}

int _to32BitId(int value) => value & 0x7fffffff;

Future<void> _showLocalNotification(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message,
) async {
  if (!(await _pushNotificationsEnabled())) {
    _log.fine(
      () =>
          'FCM message ${message.messageId} skipped: push notifications disabled',
    );
    return;
  }

  final String? title =
      message.notification?.title ?? message.data['title'] as String?;
  final String? body =
      message.notification?.body ?? message.data['body'] as String?;

  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    _log.fine(
      () =>
          'FCM message ${message.messageId} has no displayable content, skipping local notification',
    );
    return;
  }

  final int notificationId = _to32BitId(
    message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
  );

  await plugin.show(
    id: notificationId,
    title: title ?? 'Nuevo movimiento',
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_notification',
      ),
    ),
    payload: message.data['payload'] ?? message.data.toString(),
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _log.finest(() => 'FCM background message received: ${message.messageId}');
  if (message.notification != null) {
    return;
  }
  final FlutterLocalNotificationsPlugin plugin =
      await _initNotificationsPlugin();
  await _showLocalNotification(plugin, message);
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  bool _initialized = false;
  FlutterLocalNotificationsPlugin? _plugin;

  Future<void> initialize() async {
    if (_initialized) {
      _log.finest(() => 'PushNotificationService already initialized');
      return;
    }
    if (kIsWeb || !Platform.isAndroid) {
      _log.finest(
        () =>
            'PushNotificationService skipped: push notifications are Android-only',
      );
      return;
    }

    try {
      await Firebase.initializeApp();
      _log.info('Firebase initialized successfully');
    } catch (e, stackTrace) {
      _log.warning(
        () =>
            'Firebase initialization failed (google-services.json might be missing): $e',
        e,
        stackTrace,
      );
      return;
    }

    _plugin = await _initNotificationsPlugin();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    _log.info('FCM permission status: ${settings.authorizationStatus}');

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    _log.info('Android POST_NOTIFICATIONS permission granted: $granted');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _log.info('FCM foreground message received: ${message.messageId}');
      if (_plugin != null) {
        _showLocalNotification(_plugin!, message);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      _log.info('FCM token refreshed');
      await _storeToken(token);
      await syncWithBackend();
    });

    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _log.info('FCM token: $token');
        await _storeToken(token);
        await syncWithBackend();
      } else {
        _log.warning('FCM token is null');
      }
    } catch (e, stackTrace) {
      _log.warning('Failed to get FCM token: $e', e, stackTrace);
    }

    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    return await prefs.getBool(_pushEnabledKey) ?? true;
  }

  Future<DateTime?> getLastSyncAt() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? value = await prefs.getString(_lastSyncAtKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<String?> getLastSyncError() {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    return prefs.getString(_lastSyncErrorKey);
  }

  Future<void> _setLastSyncSuccess() async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setString(_lastSyncAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_lastSyncErrorKey, '');
  }

  Future<void> _setLastSyncError(String error) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setString(_lastSyncAtKey, DateTime.now().toIso8601String());
    await prefs.setString(_lastSyncErrorKey, error);
  }

  Future<void> syncWithBackend({
    String? host,
    String? apiKey,
    Map<String, String>? customHeaders,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      _log.finest(() => 'syncWithBackend skipped: not Android');
      return;
    }

    final String? token = await getStoredToken();
    if (token == null || token.isEmpty) {
      _log.info('syncWithBackend skipped: no FCM token available');
      return;
    }

    final String? runnerUrl = await _getImportRunnerUrl(host: host);
    if (runnerUrl == null || runnerUrl.isEmpty) {
      _log.info('syncWithBackend skipped: no import runner URL available');
      return;
    }

    final String? bearer = apiKey ?? await _readStoredApiKey();
    if (bearer == null || bearer.isEmpty) {
      _log.warning('syncWithBackend skipped: no API key available');
      await _setLastSyncError('No API key available');
      return;
    }

    final bool enabled = await isEnabled();
    final Uri url = Uri.parse('$runnerUrl/api/fcm/register');
    final Map<String, String> headers = <String, String>{
      HttpHeaders.authorizationHeader: 'Bearer $bearer',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (customHeaders != null && customHeaders.isNotEmpty) {
      headers.addAll(customHeaders);
    }

    final http.Client client = _httpClient;
    try {
      final http.Response response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(<String, dynamic>{
          'token': token,
          'name': 'Vibenance (Android)',
          'enabled': enabled,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info('FCM token registered with import runner at $runnerUrl');
        await _setLastSyncSuccess();
      } else {
        final String error =
            'Import runner returned HTTP ${response.statusCode}: ${response.body}';
        _log.warning(error);
        await _setLastSyncError(error);
      }
    } catch (e, stackTrace) {
      final String error = 'Failed to register FCM token: $e';
      _log.warning(error, e, stackTrace);
      await _setLastSyncError(error);
    } finally {
      client.close();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setBool(_pushEnabledKey, enabled);
    _log.info('Push notifications enabled: $enabled');
    await syncWithBackend();
  }

  Future<bool> isSystemPermissionGranted() async {
    try {
      final NotificationSettings settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e, stackTrace) {
      _log.warning(
        'Could not read FCM notification settings: $e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  Future<bool> requestSystemPermission() async {
    try {
      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e, stackTrace) {
      _log.warning('Could not request FCM permission: $e', e, stackTrace);
      return false;
    }
  }

  Future<void> _storeToken(String token) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setString(_fcmTokenKey, token);
    _log.info('FCM token stored in SharedPreferences');
  }

  Future<String?> getStoredToken() {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    return prefs.getString(_fcmTokenKey);
  }

  Future<void> showTestNotification() async {
    if (kIsWeb || !Platform.isAndroid) {
      _log.finest(() => 'showTestNotification skipped: not Android');
      return;
    }

    final FlutterLocalNotificationsPlugin plugin =
        _plugin ?? await _initNotificationsPlugin();

    await plugin.show(
      id: _to32BitId(DateTime.now().millisecondsSinceEpoch),
      title: 'Prueba de Vibenance',
      body: 'Las notificaciones push están funcionando correctamente.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_notification',
        ),
      ),
      payload: 'push_test',
    );
    _log.info('Test notification shown');
  }
}
