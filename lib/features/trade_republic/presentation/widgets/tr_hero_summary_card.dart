import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';

class TrHeroSummaryCard extends StatelessWidget {
  const TrHeroSummaryCard({
    super.key,
    required this.summary,
    this.lastUpdated,
  });

  final TrPortfolioSummary summary;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    final bool isPositive = summary.profitLossAbs >= 0;
    final Color plColor = isPositive ? Colors.green.shade700 : Colors.red.shade700;
    final String sign = isPositive ? '+' : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'VALOR TOTAL DE CARTERA',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (lastUpdated != null)
                  Text(
                    DateFormat('HH:mm').format(lastUpdated!.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(summary.totalPortfolioValue),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: plColor,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$sign${currencyFormat.format(summary.profitLossAbs)} ($sign${summary.profitLossPct.toStringAsFixed(2)}%)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: plColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Inversiones',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(summary.currentValue),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Efectivo disponible',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currencyFormat.format(summary.cashBalance),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
