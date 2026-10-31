import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibenance/auth.dart';
import 'package:vibenance/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:vibenance/services/investments/investments_sync_service.dart';
import 'package:vibenance/services/investments/market_quote_service.dart';
import 'package:vibenance/services/investments/models/portfolio.dart';
import 'package:vibenance/settings.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final MarketQuoteService _quoteService = MarketQuoteService();
  InvestmentsSyncService? _syncService;

  Portfolio _portfolio = Portfolio();
  AccountRead? _account;
  Map<String, MarketQuote> _quotes = <String, MarketQuote>{};
  List<SyncCandidate> _pendingCandidates = <SyncCandidate>[];

  bool _isLoading = true;
  bool _isSyncingQuotes = false;
  bool _isCheckingPendingPurchases = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool refreshQuotes = false}) async {
    final SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final FireflyService firefly = Provider.of<FireflyService>(
      context,
      listen: false,
    );

    final String? accountId = settings.investmentsAccountId;
    if (accountId == null || accountId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _syncService = InvestmentsSyncService(fireflyService: firefly);
    setState(() => _isLoading = true);

    try {
      final AccountRead? acc = await _syncService!.getAccount(accountId);
      final Portfolio port = await _syncService!.loadPortfolio(accountId);

      _account = acc;
      _portfolio = port;

      // Cotizaciones
      final List<String> tickers = port.holdings
          .map((Holding h) => h.ticker.trim())
          .where((String t) => t.isNotEmpty)
          .toList();

      if (tickers.isNotEmpty) {
        _quotes = await _quoteService.fetchQuotes(
          tickers,
          forceRefresh: refreshQuotes,
        );
      }

      // Detectar compras pendientes de sincronizar
      _checkPendingPurchases();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshQuotesOnly() async {
    if (_isSyncingQuotes) return;
    setState(() => _isSyncingQuotes = true);

    try {
      final List<String> tickers = _portfolio.holdings
          .map((Holding h) => h.ticker.trim())
          .where((String t) => t.isNotEmpty)
          .toList();

      if (tickers.isNotEmpty) {
        final Map<String, MarketQuote> newQuotes = await _quoteService
            .fetchQuotes(tickers, forceRefresh: true);
        if (mounted) {
          setState(() => _quotes = newQuotes);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncingQuotes = false);
      }
    }
  }

  Future<void> _checkPendingPurchases() async {
    if (_syncService == null) return;
    final SettingsProvider settings = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final String? accountId = settings.investmentsAccountId;
    if (accountId == null) return;

    setState(() => _isCheckingPendingPurchases = true);
    try {
      final List<SyncCandidate> candidates = await _syncService!
          .findUnprocessedPurchases(accountId, _portfolio);
      if (mounted) {
        setState(() => _pendingCandidates = candidates);
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingPendingPurchases = false);
      }
    }
  }

  double get _totalMarketValue {
    double total = 0.0;
    for (final Holding h in _portfolio.holdings) {
      final MarketQuote? q = _quotes[h.ticker.toUpperCase()];
      final double price = q?.regularMarketPrice ?? h.averageBuyPrice;
      total += (h.shares * price);
    }
    return total;
  }

  double get _totalInvestedAmount => _portfolio.totalInvestedAmount;

  double get _totalProfitLoss => _totalMarketValue - _totalInvestedAmount;

  double get _totalProfitLossPercent => _totalInvestedAmount > 0
      ? (_totalProfitLoss / _totalInvestedAmount) * 100
      : 0.0;

  double get _todayChange {
    double change = 0.0;
    for (final Holding h in _portfolio.holdings) {
      final MarketQuote? q = _quotes[h.ticker.toUpperCase()];
      if (q != null) {
        change += (h.shares * q.dayChange);
      }
    }
    return change;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SettingsProvider settings = Provider.of<SettingsProvider>(context);

    if (!settings.investmentsEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inversiones')),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const <Widget>[
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Vibenance',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: const Center(
          child: Text('El módulo de inversiones está desactivado.'),
        ),
      );
    }

    if (settings.investmentsAccountId == null ||
        settings.investmentsAccountId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inversiones')),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const <Widget>[
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Vibenance',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.account_balance,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Selecciona tu cuenta de inversión',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configura qué cuenta de tipo Activo representa tu broker en los ajustes de la aplicación.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inversiones'),
        actions: <Widget>[
          if (_isSyncingQuotes)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar cotizaciones',
              onPressed: _refreshQuotesOnly,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const <Widget>[
            DrawerHeader(
              child: Center(
                child: Text(
                  'Vibenance',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHoldingDialog,
        icon: const Icon(Icons.add),
        label: const Text('Añadir posición'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(refreshQuotes: true),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: <Widget>[
                  _buildSummaryCard(theme),
                  _buildSyncButtonRow(theme),
                  _buildHoldingsSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final bool isPositive = _totalProfitLoss >= 0;
    final Color pnlColor = isPositive ? Colors.green : Colors.red;

    final double currentAccBalance =
        double.tryParse(_account?.attributes.currentBalance ?? '0.0') ?? 0.0;
    final bool matchesFireflyBalance =
        (_totalInvestedAmount - currentAccBalance).abs() < 1.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Valor de Mercado Actual',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_totalMarketValue.toStringAsFixed(2)} €',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Capital Aportado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_totalInvestedAmount.toStringAsFixed(2)} €',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_account != null)
                      Row(
                        children: <Widget>[
                          Icon(
                            matchesFireflyBalance
                                ? Icons.check_circle_outline
                                : Icons.info_outline,
                            size: 14,
                            color: matchesFireflyBalance
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            matchesFireflyBalance
                                ? 'Cuadra con saldo Firefly'
                                : 'Saldo Firefly: ${currentAccBalance.toStringAsFixed(2)} €',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: matchesFireflyBalance
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      'Rentabilidad Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isPositive ? '+' : ''}${_totalProfitLoss.toStringAsFixed(2)} € (${_totalProfitLossPercent.toStringAsFixed(2)}%)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: pnlColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Hoy: ${_todayChange >= 0 ? '+' : ''}${_todayChange.toStringAsFixed(2)} €',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _todayChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButtonRow(ThemeData theme) {
    final int pendingCount = _pendingCandidates.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showSyncDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isCheckingPendingPurchases
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Badge(
                      isLabelVisible: pendingCount > 0,
                      label: Text('$pendingCount'),
                      child: const Icon(Icons.sync),
                    ),
              label: Text(
                pendingCount > 0
                    ? 'Sincronizar compras ($pendingCount pendientes)'
                    : 'Sincronizar compras',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsSection(ThemeData theme) {
    if (_portfolio.holdings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: <Widget>[
              Icon(Icons.pie_chart_outline, size: 48, color: theme.hintColor),
              const SizedBox(height: 12),
              Text(
                'No hay posiciones en la cartera',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Usa "Sincronizar compras" para detectar compras de Firefly III o añade una manualmente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Posiciones (${_portfolio.holdings.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._portfolio.holdings.map((Holding h) => _buildHoldingCard(h, theme)),
      ],
    );
  }

  Widget _buildHoldingCard(Holding holding, ThemeData theme) {
    final MarketQuote? quote = _quotes[holding.ticker.toUpperCase()];
    final double currentPrice =
        quote?.regularMarketPrice ?? holding.averageBuyPrice;
    final double totalValue = holding.shares * currentPrice;
    final double pnl = totalValue - holding.investedAmount;
    final double pnlPercent = holding.investedAmount > 0
        ? (pnl / holding.investedAmount) * 100
        : 0.0;
    final bool isPositive = pnl >= 0;
    final Color pnlColor = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditHoldingDialog(holding),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      holding.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${totalValue.toStringAsFixed(2)} €',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${holding.ticker} • ${holding.isin}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${pnl.toStringAsFixed(2)} € (${pnlPercent.toStringAsFixed(2)}%)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: pnlColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Títulos: ${holding.shares.toStringAsFixed(6)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Medio: ${holding.averageBuyPrice.toStringAsFixed(2)} €  |  Actual: ${currentPrice.toStringAsFixed(2)} €',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddHoldingDialog() async {
    final TextEditingController isinCtrl = TextEditingController();
    final TextEditingController tickerCtrl = TextEditingController();
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController sharesCtrl = TextEditingController();
    final TextEditingController investedCtrl = TextEditingController();
    final TextEditingController categoryCtrl = TextEditingController();

    bool resolving = false;

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Añadir Posición'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: isinCtrl,
                      decoration: InputDecoration(
                        labelText: 'ISIN (ej. IE00B4L5Y983)',
                        suffixIcon: IconButton(
                          icon: resolving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          onPressed: () async {
                            final String isin = isinCtrl.text.trim();
                            if (isin.isNotEmpty) {
                              setStateDialog(() => resolving = true);
                              final String? t = await _quoteService
                                  .resolveIsinToTicker(isin);
                              if (t != null) {
                                tickerCtrl.text = t;
                                final MarketQuote? q = await _quoteService
                                    .fetchQuote(t);
                                if (q != null && q.longName != null) {
                                  nameCtrl.text = q.longName!;
                                }
                              }
                              setStateDialog(() => resolving = false);
                            }
                          },
                        ),
                      ),
                    ),
                    TextField(
                      controller: tickerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ticker (ej. EUNL.DE)',
                      ),
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre activo',
                      ),
                    ),
                    TextField(
                      controller: sharesCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Participaciones (hasta 6 decimales)',
                      ),
                    ),
                    TextField(
                      controller: investedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Capital aportado total (€)',
                      ),
                    ),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Categoría (opcional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double shares =
                        double.tryParse(sharesCtrl.text.replaceAll(',', '.')) ??
                        0.0;
                    final double invested =
                        double.tryParse(
                          investedCtrl.text.replaceAll(',', '.'),
                        ) ??
                        0.0;

                    if (shares <= 0 || tickerCtrl.text.trim().isEmpty) {
                      return;
                    }

                    final Holding newH = Holding(
                      isin: isinCtrl.text.trim().toUpperCase(),
                      ticker: tickerCtrl.text.trim().toUpperCase(),
                      name: nameCtrl.text.trim().isNotEmpty
                          ? nameCtrl.text.trim()
                          : tickerCtrl.text.trim().toUpperCase(),
                      category: categoryCtrl.text.trim().isNotEmpty
                          ? categoryCtrl.text.trim()
                          : null,
                      shares: shares,
                      investedAmount: invested,
                    );

                    final List<Holding> hList = List<Holding>.from(
                      _portfolio.holdings,
                    )..add(newH);
                    final Portfolio updatedPort = _portfolio.copyWith(
                      holdings: hList,
                    );

                    final SettingsProvider settings =
                        Provider.of<SettingsProvider>(context, listen: false);
                    final bool ok = await _syncService!.savePortfolio(
                      settings.investmentsAccountId!,
                      updatedPort,
                    );

                    if (ok && mounted) {
                      Navigator.pop(ctx);
                      _loadData(refreshQuotes: true);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditHoldingDialog(Holding holding) async {
    final TextEditingController nameCtrl = TextEditingController(
      text: holding.name,
    );
    final TextEditingController tickerCtrl = TextEditingController(
      text: holding.ticker,
    );
    final TextEditingController isinCtrl = TextEditingController(
      text: holding.isin,
    );
    final TextEditingController sharesCtrl = TextEditingController(
      text: holding.shares.toStringAsFixed(6),
    );
    final TextEditingController investedCtrl = TextEditingController(
      text: holding.investedAmount.toStringAsFixed(2),
    );
    final TextEditingController categoryCtrl = TextEditingController(
      text: holding.category ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Editar ${holding.ticker}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: isinCtrl,
                  decoration: const InputDecoration(labelText: 'ISIN'),
                ),
                TextField(
                  controller: tickerCtrl,
                  decoration: const InputDecoration(labelText: 'Ticker'),
                ),
                TextField(
                  controller: sharesCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Participaciones',
                  ),
                ),
                TextField(
                  controller: investedCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Capital aportado (€)',
                  ),
                ),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final List<Holding> hList =
                    List<Holding>.from(_portfolio.holdings)..removeWhere(
                      (Holding h) =>
                          h.isin == holding.isin && h.ticker == holding.ticker,
                    );
                final Portfolio updatedPort = _portfolio.copyWith(
                  holdings: hList,
                );
                final SettingsProvider settings = Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                );
                final bool ok = await _syncService!.savePortfolio(
                  settings.investmentsAccountId!,
                  updatedPort,
                );
                if (ok && mounted) {
                  Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Eliminar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double shares =
                    double.tryParse(sharesCtrl.text.replaceAll(',', '.')) ??
                    0.0;
                final double invested =
                    double.tryParse(investedCtrl.text.replaceAll(',', '.')) ??
                    0.0;

                final int idx = _portfolio.holdings.indexOf(holding);
                if (idx != -1) {
                  final List<Holding> hList = List<Holding>.from(
                    _portfolio.holdings,
                  );
                  hList[idx] = holding.copyWith(
                    name: nameCtrl.text.trim(),
                    isin: isinCtrl.text.trim().toUpperCase(),
                    ticker: tickerCtrl.text.trim().toUpperCase(),
                    shares: shares,
                    investedAmount: invested,
                    category: categoryCtrl.text.trim().isNotEmpty
                        ? categoryCtrl.text.trim()
                        : null,
                  );
                  final Portfolio updatedPort = _portfolio.copyWith(
                    holdings: hList,
                  );
                  final SettingsProvider settings =
                      Provider.of<SettingsProvider>(context, listen: false);
                  final bool ok = await _syncService!.savePortfolio(
                    settings.investmentsAccountId!,
                    updatedPort,
                  );
                  if (ok && mounted) {
                    Navigator.pop(ctx);
                    _loadData(refreshQuotes: true);
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSyncDialog() async {
    if (_pendingCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay compras nuevas pendientes de sincronizar.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return _SyncBottomSheet(
          candidates: _pendingCandidates,
          portfolio: _portfolio,
          quoteService: _quoteService,
          onConfirm: (purchases) async {
            final Portfolio updated =
                InvestmentsSyncService.applyConfirmedPurchases(
                  currentPortfolio: _portfolio,
                  purchases: purchases,
                );
            final SettingsProvider settings = Provider.of<SettingsProvider>(
              context,
              listen: false,
            );
            final bool ok = await _syncService!.savePortfolio(
              settings.investmentsAccountId!,
              updated,
            );
            if (ok && mounted) {
              Navigator.pop(ctx);
              _loadData(refreshQuotes: true);
            }
          },
        );
      },
    );
  }
}

class _SyncBottomSheet extends StatefulWidget {
  const _SyncBottomSheet({
    required this.candidates,
    required this.portfolio,
    required this.quoteService,
    required this.onConfirm,
  });

  final List<SyncCandidate> candidates;
  final Portfolio portfolio;
  final MarketQuoteService quoteService;
  final Future<void> Function(
    List<
      ({
        SyncCandidate candidate,
        String isin,
        String ticker,
        String name,
        double shares,
        double amount,
        String? category,
      })
    >
    purchases,
  )
  onConfirm;

  @override
  State<_SyncBottomSheet> createState() => _SyncBottomSheetState();
}

class _SyncBottomSheetState extends State<_SyncBottomSheet> {
  final Map<String, TextEditingController> _sharesControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _tickerControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _isinControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _nameControllers =
      <String, TextEditingController>{};
  final Set<String> _selectedCandidates = <String>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final SyncCandidate c in widget.candidates) {
      _selectedCandidates.add(c.transactionId);

      final String isin = c.detectedIsin ?? c.matchedHolding?.isin ?? '';
      final String ticker = c.matchedHolding?.ticker ?? '';
      final String name = c.matchedHolding?.name ?? c.description;

      _isinControllers[c.transactionId] = TextEditingController(text: isin);
      _tickerControllers[c.transactionId] = TextEditingController(text: ticker);
      _nameControllers[c.transactionId] = TextEditingController(text: name);

      final double initialShares = c.suggestedShares ?? 0.0;
      _sharesControllers[c.transactionId] = TextEditingController(
        text: initialShares > 0 ? initialShares.toStringAsFixed(6) : '',
      );

      // Si no tenía participaciones específicas ni ticker, estimar con precio histórico
      _estimateSharesIfNeeded(c, ticker, isin);
    }
  }

  Future<void> _estimateSharesIfNeeded(
    SyncCandidate c,
    String initialTicker,
    String isin,
  ) async {
    String t = initialTicker;
    if (t.isEmpty && isin.isNotEmpty) {
      final String? resolved = await widget.quoteService.resolveIsinToTicker(
        isin,
      );
      if (resolved != null) {
        t = resolved;
        _tickerControllers[c.transactionId]?.text = t;
      }
    }

    if (t.isNotEmpty &&
        (_sharesControllers[c.transactionId]?.text.isEmpty ?? true)) {
      final double? closePrice = await widget.quoteService
          .fetchHistoricalClosePrice(t, c.date);
      if (closePrice != null && closePrice > 0) {
        final double estimated = c.amount / closePrice;
        if (mounted) {
          setState(() {
            _sharesControllers[c.transactionId]?.text = estimated
                .toStringAsFixed(6);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Sincronizar compras detectadas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifica o ajusta las participaciones estimadas antes de confirmar.',
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.candidates.length,
              itemBuilder: (BuildContext context, int index) {
                final SyncCandidate c = widget.candidates[index];
                final bool isSelected = _selectedCandidates.contains(
                  c.transactionId,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: isSelected,
                          title: Text(
                            c.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Fecha: ${c.date.toLocal().toString().split(' ')[0]}  |  Importe: ${c.amount.toStringAsFixed(2)} €',
                          ),
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _selectedCandidates.add(c.transactionId);
                              } else {
                                _selectedCandidates.remove(c.transactionId);
                              }
                            });
                          },
                        ),
                        if (isSelected) ...<Widget>[
                          const Divider(),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextField(
                                  controller:
                                      _tickerControllers[c.transactionId],
                                  decoration: const InputDecoration(
                                    labelText: 'Ticker',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller:
                                      _sharesControllers[c.transactionId],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Participaciones',
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          final List<
                            ({
                              SyncCandidate candidate,
                              String isin,
                              String ticker,
                              String name,
                              double shares,
                              double amount,
                              String? category,
                            })
                          >
                          purchases = [];

                          for (final SyncCandidate c in widget.candidates) {
                            if (!_selectedCandidates.contains(
                              c.transactionId,
                            )) {
                              continue;
                            }

                            final String isin =
                                _isinControllers[c.transactionId]?.text
                                    .trim() ??
                                '';
                            final String ticker =
                                _tickerControllers[c.transactionId]?.text
                                    .trim() ??
                                '';
                            final String name =
                                _nameControllers[c.transactionId]?.text
                                    .trim() ??
                                '';
                            final double shares =
                                double.tryParse(
                                  _sharesControllers[c.transactionId]?.text
                                          .replaceAll(',', '.') ??
                                      '0',
                                ) ??
                                0.0;

                            if (shares > 0 && ticker.isNotEmpty) {
                              purchases.add((
                                candidate: c,
                                isin: isin,
                                ticker: ticker,
                                name: name,
                                shares: shares,
                                amount: c.amount,
                                category: null,
                              ));
                            }
                          }

                          await widget.onConfirm(purchases);
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar Compras'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
