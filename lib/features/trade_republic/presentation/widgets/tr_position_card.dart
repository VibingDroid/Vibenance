import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';

class TrPositionCard extends StatelessWidget {
  const TrPositionCard({super.key, required this.position});

  final TrPositionModel position;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    final bool isPositive = position.profitLossAbs >= 0;
    final Color plColor = isPositive
        ? Colors.green.shade700
        : Colors.red.shade700;
    final String sign = isPositive ? '+' : '';

    IconData typeIcon = Icons.show_chart;
    if (position.instrumentType == 'etf') {
      typeIcon = Icons.pie_chart_outline;
    } else if (position.instrumentType == 'bond') {
      typeIcon = Icons.account_balance_outlined;
    } else if (position.instrumentType == 'crypto') {
      typeIcon = Icons.currency_bitcoin;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(typeIcon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    position.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${position.quantity.toStringAsFixed(position.quantity.truncateToDouble() == position.quantity ? 0 : 4)} un. • ${position.isin}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  currencyFormat.format(position.currentValue),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sign${currencyFormat.format(position.profitLossAbs)} ($sign${position.profitLossPct.toStringAsFixed(1)}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: plColor,
                    fontWeight: FontWeight.w600,
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
