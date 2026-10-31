import 'dart:convert';

class Holding {
  Holding({
    required this.isin,
    required this.ticker,
    required this.name,
    this.category,
    required this.shares,
    required this.investedAmount,
  });

  final String isin;
  final String ticker;
  final String name;
  final String? category;
  final double shares;
  final double investedAmount;

  /// Precio medio ponderado de compra
  double get averageBuyPrice => shares > 0 ? (investedAmount / shares) : 0.0;

  Holding copyWith({
    String? isin,
    String? ticker,
    String? name,
    String? category,
    double? shares,
    double? investedAmount,
  }) {
    return Holding(
      isin: isin ?? this.isin,
      ticker: ticker ?? this.ticker,
      name: name ?? this.name,
      category: category ?? this.category,
      shares: shares != null ? double.parse(shares.toStringAsFixed(6)) : this.shares,
      investedAmount: investedAmount ?? this.investedAmount,
    );
  }

  factory Holding.fromJson(Map<String, dynamic> json) {
    final num rawShares = json['shares'] as num? ?? 0.0;
    final num rawInvested = json['invested_amount'] as num? ?? 0.0;
    return Holding(
      isin: (json['isin'] as String? ?? '').trim(),
      ticker: (json['ticker'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      category: json['category'] as String?,
      shares: double.parse(rawShares.toDouble().toStringAsFixed(6)),
      investedAmount: rawInvested.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{
      'isin': isin,
      'ticker': ticker,
      'name': name,
      'shares': double.parse(shares.toStringAsFixed(6)),
      'invested_amount': double.parse(investedAmount.toStringAsFixed(2)),
    };
    if (category != null && category!.trim().isNotEmpty) {
      map['category'] = category;
    }
    return map;
  }
}

class Portfolio {
  Portfolio({
    this.version = 1,
    this.broker = 'trade_republic',
    DateTime? updatedAt,
    List<String>? processedTransactionIds,
    List<Holding>? holdings,
  })  : updatedAt = updatedAt ?? DateTime.now().toUtc(),
        processedTransactionIds = processedTransactionIds ?? <String>[],
        holdings = holdings ?? <Holding>[];

  final int version;
  final String broker;
  final DateTime updatedAt;
  final List<String> processedTransactionIds;
  final List<Holding> holdings;

  double get totalInvestedAmount =>
      holdings.fold<double>(0.0, (double sum, Holding h) => sum + h.investedAmount);

  Holding? findHolding({String? isin, String? ticker, String? name}) {
    final String cleanIsin = isin?.trim().toUpperCase() ?? '';
    final String cleanTicker = ticker?.trim().toUpperCase() ?? '';
    final String cleanName = name?.trim().toLowerCase() ?? '';

    for (final Holding h in holdings) {
      if (cleanIsin.isNotEmpty && h.isin.trim().toUpperCase() == cleanIsin) {
        return h;
      }
      if (cleanTicker.isNotEmpty && h.ticker.trim().toUpperCase() == cleanTicker) {
        return h;
      }
      if (cleanName.isNotEmpty && h.name.trim().toLowerCase() == cleanName) {
        return h;
      }
    }
    return null;
  }

  bool isTransactionProcessed(String txId) =>
      processedTransactionIds.contains(txId.trim());

  Portfolio copyWith({
    int? version,
    String? broker,
    DateTime? updatedAt,
    List<String>? processedTransactionIds,
    List<Holding>? holdings,
  }) {
    return Portfolio(
      version: version ?? this.version,
      broker: broker ?? this.broker,
      updatedAt: updatedAt ?? this.updatedAt,
      processedTransactionIds:
          processedTransactionIds ?? List<String>.from(this.processedTransactionIds),
      holdings: holdings ?? List<Holding>.from(this.holdings),
    );
  }

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final int ver = json['version'] as int? ?? 1;
    final String brk = json['broker'] as String? ?? 'trade_republic';
    DateTime updated;
    try {
      updated = DateTime.parse(json['updated_at'] as String);
    } catch (_) {
      updated = DateTime.now().toUtc();
    }
    final List<dynamic> txIdsRaw = json['processed_transaction_ids'] as List<dynamic>? ?? <dynamic>[];
    final List<String> txIds = txIdsRaw.map((dynamic e) => e.toString().trim()).toList();

    final List<dynamic> holdingsRaw = json['holdings'] as List<dynamic>? ?? <dynamic>[];
    final List<Holding> hList = holdingsRaw
        .whereType<Map<String, dynamic>>()
        .map(Holding.fromJson)
        .toList();

    return Portfolio(
      version: ver,
      broker: brk,
      updatedAt: updated,
      processedTransactionIds: txIds,
      holdings: hList,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'broker': broker,
      'updated_at': updatedAt.toIso8601String(),
      'processed_transaction_ids': processedTransactionIds,
      'holdings': holdings.map((Holding h) => h.toJson()).toList(),
    };
  }
}
