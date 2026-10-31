import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/services/investments/investments_sync_service.dart';
import 'package:vibenance/services/investments/models/portfolio.dart';

void main() {
  group('InvestmentsSyncService - applyConfirmedPurchases', () {
    test('accumulates shares and invested_amount for existing holding and tracks txId', () {
      final Portfolio initialPortfolio = Portfolio(
        version: 1,
        broker: 'trade_republic',
        processedTransactionIds: <String>['101'],
        holdings: <Holding>[
          Holding(
            isin: 'IE00B4L5Y983',
            ticker: 'EUNL.DE',
            name: 'Core MSCI World',
            shares: 10.0,
            investedAmount: 1000.0,
          ),
        ],
      );

      final SyncCandidate candidate = SyncCandidate(
        transactionId: '102',
        journalId: '102',
        date: DateTime.parse('2026-10-15T09:00:00Z'),
        amount: 250.0,
        description: 'Trade Republic Sparplan IE00B4L5Y983',
        detectedIsin: 'IE00B4L5Y983',
      );

      final Portfolio updated = InvestmentsSyncService.applyConfirmedPurchases(
        currentPortfolio: initialPortfolio,
        purchases: [
          (
            candidate: candidate,
            isin: 'IE00B4L5Y983',
            ticker: 'EUNL.DE',
            name: 'Core MSCI World',
            shares: 2.500000,
            amount: 250.0,
            category: null,
          ),
        ],
      );

      expect(updated.processedTransactionIds, containsAll(<String>['101', '102']));
      expect(updated.holdings.length, equals(1));
      final Holding h = updated.holdings.first;
      expect(h.shares, equals(12.5));
      expect(h.investedAmount, equals(1250.0));
      expect(h.averageBuyPrice, equals(100.0));
    });

    test('creates new holding when purchasing unknown ISIN/ticker', () {
      final Portfolio initialPortfolio = Portfolio();

      final SyncCandidate candidate = SyncCandidate(
        transactionId: '501',
        journalId: '501',
        date: DateTime.parse('2026-10-20T10:00:00Z'),
        amount: 500.0,
        description: 'Compra S&P 500 IE00B5BMR087',
        detectedIsin: 'IE00B5BMR087',
      );

      final Portfolio updated = InvestmentsSyncService.applyConfirmedPurchases(
        currentPortfolio: initialPortfolio,
        purchases: [
          (
            candidate: candidate,
            isin: 'IE00B5BMR087',
            ticker: 'SXR8.DE',
            name: 'iShares Core S&P 500',
            shares: 0.985432,
            amount: 500.0,
            category: 'RV USA',
          ),
        ],
      );

      expect(updated.processedTransactionIds, contains('501'));
      expect(updated.holdings.length, equals(1));
      final Holding h = updated.holdings.first;
      expect(h.isin, equals('IE00B5BMR087'));
      expect(h.ticker, equals('SXR8.DE'));
      expect(h.shares, equals(0.985432));
      expect(h.investedAmount, equals(500.0));
      expect(h.averageBuyPrice, closeTo(500.0 / 0.985432, 0.0001));
    });
  });
}
