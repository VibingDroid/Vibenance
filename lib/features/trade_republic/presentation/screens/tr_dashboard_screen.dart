import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';
import 'package:vibenance/features/trade_republic/presentation/providers/tr_portfolio_provider.dart';
import 'package:vibenance/features/trade_republic/presentation/screens/tr_auth_bottom_sheet.dart';
import 'package:vibenance/features/trade_republic/presentation/widgets/tr_hero_summary_card.dart';
import 'package:vibenance/features/trade_republic/presentation/widgets/tr_position_card.dart';
import 'package:vibenance/features/trade_republic/presentation/widgets/tr_savings_plan_tile.dart';

class TrDashboardScreen extends StatefulWidget {
  const TrDashboardScreen({super.key});

  @override
  State<TrDashboardScreen> createState() => _TrDashboardScreenState();
}

class _TrDashboardScreenState extends State<TrDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final TrPortfolioProvider provider = Provider.of<TrPortfolioProvider>(
        context,
        listen: false,
      );
      provider.init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TrPortfolioProvider provider = Provider.of<TrPortfolioProvider>(
      context,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inversiones (TR)'),
        actions: <Widget>[
          if (provider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Cerrar sesión TR',
              onPressed: () => _confirmLogout(context, provider),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: provider.isRefreshing ? null : () => provider.refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(icon: Icon(Icons.pie_chart_outline), text: 'Cartera'),
            Tab(icon: Icon(Icons.repeat), text: 'Planes'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Actividad'),
          ],
        ),
      ),
      body: provider.isLoading && provider.snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                if (provider.isSessionExpired)
                  _buildSessionExpiredBanner(context, provider),
                if (provider.errorMessage != null && !provider.isSessionExpired)
                  _buildErrorBanner(theme, provider.errorMessage!),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildPortfolioTab(context, provider),
                      _buildSavingsPlansTab(context, provider),
                      _buildActivityTab(context, provider),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSessionExpiredBanner(
    BuildContext context,
    TrPortfolioProvider provider,
  ) {
    final ThemeData theme = Theme.of(context);
    return MaterialBanner(
      backgroundColor: theme.colorScheme.errorContainer,
      leading: Icon(
        Icons.lock_clock_outlined,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: Text(
        'Sesión no iniciada o expirada en Trade Republic.',
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
      actions: <Widget>[
        FilledButton.tonal(
          onPressed: () => TrAuthBottomSheet.show(context, provider),
          child: const Text('Conectar'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
      child: Text(
        message,
        style: TextStyle(
          color: theme.colorScheme.onErrorContainer,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPortfolioTab(
    BuildContext context,
    TrPortfolioProvider provider,
  ) {
    final TrSnapshotModel? snapshot = provider.snapshot;
    if (snapshot == null && !provider.isAuthenticated) {
      return _buildEmptyAuthState(context, provider);
    }

    if (snapshot == null) {
      return const Center(child: Text('No hay datos de cartera disponibles'));
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: snapshot.positions.length + 1,
        itemBuilder: (BuildContext ctx, int index) {
          if (index == 0) {
            return TrHeroSummaryCard(
              summary: snapshot.summary,
              lastUpdated: provider.lastRefreshedAt,
            );
          }
          final TrPositionModel position = snapshot.positions[index - 1];
          return TrPositionCard(position: position);
        },
      ),
    );
  }

  Widget _buildSavingsPlansTab(
    BuildContext context,
    TrPortfolioProvider provider,
  ) {
    final TrSnapshotModel? snapshot = provider.snapshot;
    if (snapshot == null && !provider.isAuthenticated) {
      return _buildEmptyAuthState(context, provider);
    }

    final List<TrSavingsPlanModel> plans =
        snapshot?.savingsPlans ?? <TrSavingsPlanModel>[];
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    final double monthlyTotal = plans.fold<double>(
      0.0,
      (double acc, TrSavingsPlanModel p) => acc + (p.paused ? 0.0 : p.amount),
    );

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.savings_outlined),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Ahorro periódico activo',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currencyFormat.format(monthlyTotal)} / mes',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay planes de ahorro programados')),
            )
          else
            ...plans.map((TrSavingsPlanModel p) => TrSavingsPlanTile(plan: p)),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, TrPortfolioProvider provider) {
    final List<TrTransactionModel> txs = provider.transactions;
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    if (txs.isEmpty && !provider.isAuthenticated) {
      return _buildEmptyAuthState(context, provider);
    }

    if (txs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No se registran movimientos recientes')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: txs.length,
        separatorBuilder: (BuildContext _, int index) =>
            const Divider(height: 1),
        itemBuilder: (BuildContext ctx, int index) {
          final TrTransactionModel tx = txs[index];
          final bool isPositive = tx.amount >= 0;
          final Color amountColor = isPositive
              ? Colors.green.shade700
              : theme.colorScheme.onSurface;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              child: Icon(
                isPositive ? Icons.south_west : Icons.north_east,
                size: 18,
              ),
            ),
            title: Text(
              tx.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(tx.timestamp.toLocal())}${tx.subtitle != null ? ' • ${tx.subtitle}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            trailing: Text(
              currencyFormat.format(tx.amount),
              style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyAuthState(
    BuildContext context,
    TrPortfolioProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Conecta tu cuenta de Trade Republic',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Visualiza tus acciones, ETFs, planes de inversión y saldo disponible directamente en Vibenance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => TrAuthBottomSheet.show(context, provider),
              icon: const Icon(Icons.login),
              label: const Text('Conectar con Trade Republic'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, TrPortfolioProvider provider) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Deseas desconectar la cuenta de Trade Republic? Las cookies de sesión serán eliminadas del puente.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              provider.logout();
            },
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
  }
}
