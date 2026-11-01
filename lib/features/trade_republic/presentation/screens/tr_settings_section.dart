import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_config_model.dart';
import 'package:vibenance/features/trade_republic/presentation/providers/tr_portfolio_provider.dart';

class TrSettingsSection extends StatefulWidget {
  const TrSettingsSection({super.key});

  @override
  State<TrSettingsSection> createState() => _TrSettingsSectionState();
}

class _TrSettingsSectionState extends State<TrSettingsSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _fireflyAccountController =
      TextEditingController();

  bool _isEnabled = false;
  bool _obscureApiKey = true;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testStatusMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _fireflyAccountController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final TrPortfolioProvider provider = Provider.of<TrPortfolioProvider>(
      context,
      listen: false,
    );
    final TrConfigModel config = await provider.repository.loadConfig();
    if (!mounted) return;
    setState(() {
      _isEnabled = config.isEnabled;
      _urlController.text = config.bridgeUrl;
      _apiKeyController.text = config.bridgeApiKey;
      _fireflyAccountController.text = config.fireflyAssetAccountId ?? '';
      _isLoading = false;
    });
  }

  Future<void> _testConnection() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce primero la URL del microservicio puente'),
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testStatusMessage = null;
      _testSuccess = null;
    });

    final TrPortfolioProvider provider = Provider.of<TrPortfolioProvider>(
      context,
      listen: false,
    );
    final bool ok = await provider.repository.testConnection(
      baseUrl: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testSuccess = ok;
      _testStatusMessage = ok
          ? 'Conexión exitosa con el microservicio puente.'
          : 'No se pudo conectar con el microservicio puente.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_testStatusMessage!),
        backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );
  }

  Future<void> _saveConfig() async {
    if (_isEnabled && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final TrPortfolioProvider provider = Provider.of<TrPortfolioProvider>(
      context,
      listen: false,
    );

    final TrConfigModel newConfig = TrConfigModel(
      isEnabled: _isEnabled,
      bridgeUrl: _urlController.text.trim(),
      bridgeApiKey: _apiKeyController.text.trim(),
      fireflyAssetAccountId: _fireflyAccountController.text.trim().isEmpty
          ? null
          : _fireflyAccountController.text.trim(),
    );

    await provider.repository.saveConfig(newConfig);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración de Trade Republic guardada.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(Icons.candlestick_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Integración Trade Republic',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Activar Inversiones Trade Republic'),
            subtitle: const Text(
              'Consulta tu cartera, planes de ahorro y movimientos vía microservicio puente.',
            ),
            value: _isEnabled,
            onChanged: (bool value) async {
              setState(() => _isEnabled = value);
              await _saveConfig();
            },
          ),
          if (_isEnabled) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL del microservicio puente',
                  hintText: 'https://tr-bridge.midominio.com',
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (String? val) {
                  if (!_isEnabled) return null;
                  if (val == null || val.trim().isEmpty) {
                    return 'La URL del microservicio es requerida';
                  }
                  final Uri? uri = Uri.tryParse(val.trim());
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return 'Introduce una URL válida (ej. https://...)';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                controller: _apiKeyController,
                obscureText: _obscureApiKey,
                decoration: InputDecoration(
                  labelText: 'API Key del puente (X-Bridge-Api-Key)',
                  prefixIcon: const Icon(Icons.key),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                controller: _fireflyAccountController,
                decoration: const InputDecoration(
                  labelText:
                      'ID de cuenta de activos en Firefly III (opcional)',
                  hintText: 'ej. 12',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            if (_testStatusMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      (_testSuccess ?? false)
                          ? Icons.check_circle
                          : Icons.error_outline,
                      size: 16,
                      color: (_testSuccess ?? false)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testStatusMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: (_testSuccess ?? false)
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: const Text('Probar conexión'),
                  ),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveConfig,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
