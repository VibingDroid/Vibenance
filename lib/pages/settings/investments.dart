import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibenance/auth.dart';
import 'package:vibenance/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:vibenance/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:vibenance/settings.dart';

class InvestmentsSettingsSection extends StatefulWidget {
  const InvestmentsSettingsSection({super.key});

  @override
  State<InvestmentsSettingsSection> createState() =>
      _InvestmentsSettingsSectionState();
}

class _InvestmentsSettingsSectionState
    extends State<InvestmentsSettingsSection> {
  List<AccountRead> _assetAccounts = <AccountRead>[];
  bool _isLoadingAccounts = false;

  @override
  void initState() {
    super.initState();
    _loadAssetAccounts();
  }

  Future<void> _loadAssetAccounts() async {
    final FireflyService firefly =
        Provider.of<FireflyService>(context, listen: false);
    if (!firefly.hasApi()) return;

    setState(() => _isLoadingAccounts = true);
    try {
      final res = await firefly.api.v1AccountsGet(
        type: enums.AccountTypeFilter.assetAccount,
        limit: 100,
      );
      if (res.isSuccessful && res.body != null) {
        setState(() {
          _assetAccounts = res.body!.data;
        });
      }
    } catch (_) {
      // Silencioso
    } finally {
      if (mounted) {
        setState(() => _isLoadingAccounts = false);
      }
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Módulo de Inversiones (Beta)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Seguimiento de carteras y sincronización de compras (Trade Republic / brokers).',
          ),
          trailing: Switch(
            value: settings.investmentsEnabled,
            onChanged: (bool val) {
              settings.setInvestmentsEnabled(val);
            },
          ),
        ),
        if (settings.investmentsEnabled) ...<Widget>[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Cuenta de inversión (Firefly III)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_isLoadingAccounts)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_assetAccounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'No se encontraron cuentas de tipo Activo en Firefly III.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: _assetAccounts.any(
                  (AccountRead a) => a.id == settings.investmentsAccountId,
                )
                    ? settings.investmentsAccountId
                    : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: 'Selecciona una cuenta de activo',
                ),
                items: _assetAccounts.map((AccountRead a) {
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text(a.attributes.name),
                  );
                }).toList(),
                onChanged: (String? newId) {
                  settings.setInvestmentsAccountId(newId);
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
