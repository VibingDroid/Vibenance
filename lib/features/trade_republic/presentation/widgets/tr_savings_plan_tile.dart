import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';

class TrSavingsPlanTile extends StatelessWidget {
  const TrSavingsPlanTile({super.key, required this.plan});

  final TrSavingsPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'es_ES',
      symbol: '€',
      decimalDigits: 2,
    );

    String intervalLabel;
    switch (plan.interval.toLowerCase()) {
      case 'weekly':
        intervalLabel = 'Semanal';
        break;
      case 'biweekly':
      case 'fortnightly':
        intervalLabel = 'Quincenal';
        break;
      case 'quarterly':
        intervalLabel = 'Trimestral';
        break;
      case 'monthly':
      default:
        intervalLabel = 'Mensual';
        break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: plan.paused
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.secondaryContainer,
        foregroundColor: plan.paused
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.onSecondaryContainer,
        child: Icon(plan.paused ? Icons.pause : Icons.repeat, size: 20),
      ),
      title: Text(
        plan.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          decoration: plan.paused ? TextDecoration.lineThrough : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$intervalLabel • ${plan.isin}${plan.nextExecutionDate != null ? ' • Próx: ${plan.nextExecutionDate}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            currencyFormat.format(plan.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (plan.paused)
            Text(
              'Pausado',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
