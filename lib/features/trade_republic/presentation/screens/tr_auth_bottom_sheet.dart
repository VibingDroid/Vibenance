import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibenance/features/trade_republic/presentation/providers/tr_portfolio_provider.dart';

class TrAuthBottomSheet extends StatefulWidget {
  const TrAuthBottomSheet({super.key, required this.provider});

  final TrPortfolioProvider provider;

  static Future<bool?> show(
    BuildContext context,
    TrPortfolioProvider provider,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TrAuthBottomSheet(provider: provider),
      ),
    );
  }

  @override
  State<TrAuthBottomSheet> createState() => _TrAuthBottomSheetState();
}

class _TrAuthBottomSheetState extends State<TrAuthBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  int _currentStep = 1; // 1: Phone + PIN, 2: 2FA Code
  String? _processId;
  int _countdownSeconds = 60;
  Timer? _countdownTimer;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleStep1Submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> res = await widget.provider.login(
        phone: _phoneController.text.trim(),
        pin: _pinController.text.trim(),
      );

      final String? pid = res['process_id'] as String?;
      final int countdown = (res['countdown_seconds'] as num?)?.toInt() ?? 60;

      if (pid != null && pid.isNotEmpty) {
        setState(() {
          _currentStep = 2;
          _processId = pid;
        });
        _startCountdown(countdown);
      } else {
        setState(() {
          _error =
              res['message'] as String? ??
              'No se recibió process_id del bridge';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleStep2Submit() async {
    if (_codeController.text.trim().length < 4) {
      setState(() {
        _error = 'Introduce el código de 4 dígitos';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.provider.verify(
        processId: _processId ?? '',
        code: _codeController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.account_balance_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Conectar Trade Republic',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentStep == 1
                              ? 'Paso 1: Identificación'
                              : 'Paso 2: Confirmación 2FA',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              if (_currentStep == 1) ...<Widget>[
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de teléfono (E.164)',
                    hintText: '+34600000000',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Introduce tu teléfono con prefijo internacional';
                    }
                    if (!val.trim().startsWith('+')) {
                      return 'Debe comenzar con + (ej. +34)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'PIN de Trade Republic (4 dígitos)',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? val) {
                    if (val == null || val.trim().length != 4) {
                      return 'El PIN debe tener exactamente 4 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleStep1Submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(_isSubmitting ? 'Iniciando...' : 'Continuar'),
                ),
              ] else ...<Widget>[
                Text(
                  'Se ha enviado una notificación push a tu app de Trade Republic. Confírmala o introduce el código de 4 dígitos que aparece en pantalla:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Código 2FA (4 dígitos)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tiempo restante: ${_countdownSeconds}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleStep2Submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSubmitting ? 'Verificando...' : 'Verificar y Conectar',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          _countdownTimer?.cancel();
                          setState(() {
                            _currentStep = 1;
                            _error = null;
                          });
                        },
                  child: const Text('Volver atrás'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
