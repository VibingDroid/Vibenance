import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_config_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';

void main() {
  group('Trade Republic Models Test', () {
    test(
      'TrConfigModel serialization excludes sensitive keys and parses correctly',
      () {
        const TrConfigModel config = TrConfigModel(
          isEnabled: true,
          bridgeUrl: 'https://tr-bridge.example.com',
          bridgeApiKey: 'secret-key-123',
          fireflyAssetAccountId: '42',
        );

        final Map<String, dynamic> json = config.toJson();
        expect(json['is_enabled'], isTrue);
        expect(json['bridge_url'], 'https://tr-bridge.example.com');
        expect(json['firefly_asset_account_id'], '42');
        // API key must never be exported in toJson
        expect(json.containsKey('bridge_api_key'), isFalse);

        final TrConfigModel copy = config.copyWith(isEnabled: false);
        expect(copy.isEnabled, isFalse);
        expect(copy.bridgeUrl, 'https://tr-bridge.example.com');
        expect(copy.bridgeApiKey, 'secret-key-123');
      },
    );

    test('TrSnapshotModel parses summary, positions and savings plans', () {
      final Map<String, dynamic> rawJson = <String, dynamic>{
        'summary': <String, dynamic>{
          'total_invested': 1000.0,
          'current_value': 1250.50,
          'profit_loss_abs': 250.50,
          'profit_loss_pct': 25.05,
          'cash_balance': 300.00,
          'currency': 'EUR',
          'iban': 'DE89370400440532013000',
        },
        'positions': <dynamic>[
          <String, dynamic>{
            'isin': 'US0378331005',
            'name': 'Apple Inc.',
            'instrument_type': 'stock',
            'quantity': 5.0,
            'average_buy_in': 150.0,
            'current_price': 180.0,
            'current_value': 900.0,
            'profit_loss_abs': 150.0,
            'profit_loss_pct': 20.0,
          },
        ],
        'savings_plans': <dynamic>[
          <String, dynamic>{
            'id': 'plan-1',
            'isin': 'IE00B4L5Y983',
            'name': 'iShares Core MSCI World',
            'amount': 100.0,
            'interval': 'monthly',
            'next_execution_date': '2026-11-02',
            'paused': false,
          },
        ],
        'fetched_at': '2026-10-31T20:00:00.000Z',
      };

      final TrSnapshotModel snapshot = TrSnapshotModel.fromJson(rawJson);

      expect(snapshot.summary.totalInvested, 1000.0);
      expect(snapshot.summary.currentValue, 1250.50);
      expect(
        snapshot.summary.totalPortfolioValue,
        1550.50,
      ); // 1250.50 + 300 cash
      expect(snapshot.summary.profitLossAbs, 250.50);
      expect(snapshot.summary.currency, 'EUR');

      expect(snapshot.positions.length, 1);
      expect(snapshot.positions.first.name, 'Apple Inc.');
      expect(snapshot.positions.first.isin, 'US0378331005');
      expect(snapshot.positions.first.instrumentType, 'stock');

      expect(snapshot.savingsPlans.length, 1);
      expect(snapshot.savingsPlans.first.id, 'plan-1');
      expect(snapshot.savingsPlans.first.interval, 'monthly');
      expect(snapshot.savingsPlans.first.paused, isFalse);
    });

    test('TrTransactionModel parses transaction data', () {
      final Map<String, dynamic> rawJson = <String, dynamic>{
        'id': 'tx-1',
        'timestamp': '2026-10-30T15:30:00.000Z',
        'title': 'Compra de Apple Inc.',
        'subtitle': '5 acciones @ 180 €',
        'amount': -900.0,
        'currency': 'EUR',
        'type': 'BUY',
        'status': 'EXECUTED',
      };

      final TrTransactionModel tx = TrTransactionModel.fromJson(rawJson);
      expect(tx.id, 'tx-1');
      expect(tx.title, 'Compra de Apple Inc.');
      expect(tx.amount, -900.0);
      expect(tx.currency, 'EUR');
    });
  });
}
