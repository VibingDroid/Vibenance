import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vibenance/services/push_notification_service.dart';

class PushNotificationsSettingsPage extends StatefulWidget {
  const PushNotificationsSettingsPage({super.key});

  @override
  State<PushNotificationsSettingsPage> createState() =>
      _PushNotificationsSettingsPageState();
}

class _PushNotificationsSettingsPageState
    extends State<PushNotificationsSettingsPage> {
  final PushNotificationService _service = PushNotificationService();
  late Future<bool> _enabledFuture;
  late Future<bool> _permissionFuture;
  late Future<String?> _tokenFuture;
  late Future<DateTime?> _lastSyncAtFuture;
  late Future<String?> _lastSyncErrorFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _enabledFuture = _service.isEnabled();
    _permissionFuture = _service.isSystemPermissionGranted();
    _tokenFuture = _service.getStoredToken();
    _lastSyncAtFuture = _service.getLastSyncAt();
    _lastSyncErrorFuture = _service.getLastSyncError();
  }

  String _truncateToken(String token) {
    if (token.length <= 24) return token;
    return '${token.substring(0, 12)}...${token.substring(token.length - 6)}';
  }

  Future<void> _requestPermission() async {
    final bool granted = await _service.requestSystemPermission();
    if (mounted) {
      final String message = granted
          ? 'Permiso de notificaciones concedido'
          : 'No se pudo obtener el permiso de notificaciones';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
    setState(_refresh);
  }

  Future<void> _copyToken(String? token) async {
    if (token == null) return;
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token FCM copiado'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    await _service.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones push')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        primary: false,
        children: <Widget>[
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: _enabledFuture,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              final bool enabled = snapshot.data ?? true;
              return SwitchListTile.adaptive(
                title: const Text('Notificaciones de nuevos movimientos'),
                subtitle: const Text(
                  'Recibe una notificación cuando se importe una transacción desde el servidor.',
                ),
                value: enabled,
                secondary: CircleAvatar(
                  child: Icon(
                    enabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                  ),
                ),
                onChanged: snapshot.connectionState == ConnectionState.done
                    ? (bool value) async {
                        await _service.setEnabled(value);
                        setState(_refresh);
                      }
                    : null,
              );
            },
          ),
          const Divider(),
          FutureBuilder<bool>(
            future: _permissionFuture,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              final bool granted = snapshot.data ?? false;
              final String statusText = granted ? 'Concedido' : 'Denegado';
              return ListTile(
                title: const Text('Estado del permiso del sistema'),
                subtitle: Text(statusText),
                leading: CircleAvatar(
                  child: Icon(granted ? Icons.check_circle : Icons.block),
                ),
                trailing: granted
                    ? null
                    : TextButton(
                        onPressed:
                            snapshot.connectionState == ConnectionState.done
                            ? _requestPermission
                            : null,
                        child: const Text('SOLICITAR'),
                      ),
              );
            },
          ),
          const Divider(),
          FutureBuilder<String?>(
            future: _tokenFuture,
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              final String? token = snapshot.data;
              final String subtitle = token != null
                  ? 'Token: ${_truncateToken(token)}'
                  : 'Token no disponible (falta google-services.json)';
              return ListTile(
                title: const Text('Token FCM'),
                subtitle: Text(subtitle),
                leading: const CircleAvatar(child: Icon(Icons.key)),
                trailing: token != null
                    ? IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copiar token FCM',
                        onPressed: () => _copyToken(token),
                      )
                    : null,
              );
            },
          ),
          const Divider(),
          FutureBuilder<List<dynamic>>(
            future: Future.wait(<Future<dynamic>>[
              _lastSyncAtFuture,
              _lastSyncErrorFuture,
            ]),
            builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
              final DateTime? lastSync = snapshot.data?[0] as DateTime?;
              final String? error = snapshot.data?[1] as String?;
              final bool hasError = error != null && error.isNotEmpty;
              final String subtitle;
              if (hasError) {
                subtitle = 'Error: $error';
              } else if (lastSync != null) {
                subtitle =
                    'Registrado el ${DateFormat("dd/MM/yyyy HH:mm").format(lastSync.toLocal())}';
              } else {
                subtitle = 'Pendiente de sincronización con el servidor';
              }
              return ListTile(
                title: const Text('Sincronización con el servidor'),
                subtitle: Text(subtitle),
                leading: CircleAvatar(
                  child: Icon(
                    hasError
                        ? Icons.error_outline
                        : (lastSync != null
                              ? Icons.cloud_done
                              : Icons.cloud_off),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Enviar notificación de prueba'),
            subtitle: const Text(
              'Emite una notificación local para comprobar el canal y permisos.',
            ),
            leading: const CircleAvatar(
              child: Icon(Icons.notifications_active_outlined),
            ),
            onTap: _sendTestNotification,
          ),
        ],
      ),
    );
  }
}
