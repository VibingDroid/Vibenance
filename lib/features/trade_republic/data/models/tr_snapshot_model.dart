class TrPortfolioSummary {
  const TrPortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.profitLossAbs,
    required this.profitLossPct,
    required this.cashBalance,
    this.currency = 'EUR',
    this.iban,
  });

  final double totalInvested;
  final double currentValue;
  final double profitLossAbs;
  final double profitLossPct;
  final double cashBalance;
  final String currency;
  final String? iban;

  double get totalPortfolioValue => currentValue + cashBalance;

  factory TrPortfolioSummary.fromJson(Map<String, dynamic> json) {
    return TrPortfolioSummary(
      totalInvested: (json['total_invested'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0.0,
      profitLossAbs: (json['profit_loss_abs'] as num?)?.toDouble() ?? 0.0,
      profitLossPct: (json['profit_loss_pct'] as num?)?.toDouble() ?? 0.0,
      cashBalance: (json['cash_balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      iban: json['iban'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'total_invested': totalInvested,
      'current_value': currentValue,
      'profit_loss_abs': profitLossAbs,
      'profit_loss_pct': profitLossPct,
      'cash_balance': cashBalance,
      'currency': currency,
      'iban': iban,
    };
  }
}

class TrPositionModel {
  const TrPositionModel({
    required this.isin,
    required this.name,
    required this.instrumentType,
    required this.quantity,
    required this.averageBuyIn,
    required this.currentPrice,
    required this.currentValue,
    required this.profitLossAbs,
    required this.profitLossPct,
  });

  final String isin;
  final String name;
  final String instrumentType;
  final double quantity;
  final double averageBuyIn;
  final double currentPrice;
  final double currentValue;
  final double profitLossAbs;
  final double profitLossPct;

  factory TrPositionModel.fromJson(Map<String, dynamic> json) {
    return TrPositionModel(
      isin: json['isin'] as String? ?? '',
      name: json['name'] as String? ?? '',
      instrumentType: json['instrument_type'] as String? ?? 'stock',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      averageBuyIn: (json['average_buy_in'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['current_value'] as num?)?.toDouble() ?? 0.0,
      profitLossAbs: (json['profit_loss_abs'] as num?)?.toDouble() ?? 0.0,
      profitLossPct: (json['profit_loss_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isin': isin,
      'name': name,
      'instrument_type': instrumentType,
      'quantity': quantity,
      'average_buy_in': averageBuyIn,
      'current_price': currentPrice,
      'current_value': currentValue,
      'profit_loss_abs': profitLossAbs,
      'profit_loss_pct': profitLossPct,
    };
  }
}

class TrSavingsPlanModel {
  const TrSavingsPlanModel({
    required this.id,
    required this.isin,
    required this.name,
    required this.amount,
    required this.interval,
    this.nextExecutionDate,
    this.paused = false,
  });

  final String id;
  final String isin;
  final String name;
  final double amount;
  final String interval;
  final String? nextExecutionDate;
  final bool paused;

  factory TrSavingsPlanModel.fromJson(Map<String, dynamic> json) {
    return TrSavingsPlanModel(
      id: json['id'] as String? ?? '',
      isin: json['isin'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      interval: json['interval'] as String? ?? 'monthly',
      nextExecutionDate: json['next_execution_date'] as String?,
      paused: json['paused'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'isin': isin,
      'name': name,
      'amount': amount,
      'interval': interval,
      'next_execution_date': nextExecutionDate,
      'paused': paused,
    };
  }
}

class TrSnapshotModel {
  const TrSnapshotModel({
    required this.summary,
    required this.positions,
    this.savingsPlans = const <TrSavingsPlanModel>[],
    required this.fetchedAt,
  });

  final TrPortfolioSummary summary;
  final List<TrPositionModel> positions;
  final List<TrSavingsPlanModel> savingsPlans;
  final DateTime fetchedAt;

  factory TrSnapshotModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? summaryJson =
        json['summary'] as Map<String, dynamic>?;
    final List<dynamic>? positionsJson = json['positions'] as List<dynamic>?;
    final List<dynamic>? savingsJson = json['savings_plans'] as List<dynamic>?;

    return TrSnapshotModel(
      summary: summaryJson != null
          ? TrPortfolioSummary.fromJson(summaryJson)
          : const TrPortfolioSummary(
              totalInvested: 0,
              currentValue: 0,
              profitLossAbs: 0,
              profitLossPct: 0,
              cashBalance: 0,
            ),
      positions: positionsJson != null
          ? positionsJson
                .map(
                  (dynamic p) =>
                      TrPositionModel.fromJson(p as Map<String, dynamic>),
                )
                .toList()
          : <TrPositionModel>[],
      savingsPlans: savingsJson != null
          ? savingsJson
                .map(
                  (dynamic s) =>
                      TrSavingsPlanModel.fromJson(s as Map<String, dynamic>),
                )
                .toList()
          : <TrSavingsPlanModel>[],
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary.toJson(),
      'positions': positions.map((TrPositionModel p) => p.toJson()).toList(),
      'savings_plans': savingsPlans
          .map((TrSavingsPlanModel s) => s.toJson())
          .toList(),
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }
}
