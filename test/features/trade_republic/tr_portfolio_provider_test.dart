import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_config_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';
import 'package:vibenance/features/trade_republic/data/tr_bridge_api_client.dart';
import 'package:vibenance/features/trade_republic/domain/tr_repository.dart';
import 'package:vibenance/features/trade_republic/presentation/providers/tr_portfolio_provider.dart';

class FakeTrRepository implements TrRepository {
  TrConfigModel currentConfig = const TrConfigModel(isEnabled: true);
  TrSnapshotModel? fakeSnapshot;
  List<TrTransactionModel> fakeTransactions = <TrTransactionModel>[];
  bool shouldExpireSession = false;
  bool loggedOut = false;

  @override
  Future<TrConfigModel> loadConfig() async => currentConfig;

  @override
  Future<void> saveConfig(TrConfigModel config) async {
    currentConfig = config;
  }

  @override
  Future<bool> testConnection({String? baseUrl, String? apiKey}) async => true;

  @override
  Future<TrSnapshotModel?> getCachedSnapshot() async => fakeSnapshot;

  @override
  Future<TrSnapshotModel> fetchSnapshot({bool enrich = true}) async {
    if (shouldExpireSession) {
      throw const TrSessionExpiredException(
        message: 'Sesión expirada en Trade Republic.',
      );
    }
    return fakeSnapshot ??
        const TrSnapshotModel(
          summary: TrPortfolioSummary(
            totalInvested: 100,
            currentValue: 120,
            profitLossAbs: 20,
            profitLossPct: 20,
            cashBalance: 10,
            currency: 'EUR',
          ),
          positions: <TrPositionModel>[],
          savingsPlans: <TrSavingsPlanModel>[],
        );
  }

  @override
  Future<List<TrTransactionModel>> fetchTransactions() async => fakeTransactions;

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String pin) async =>
      <String, dynamic>{'process_id': 'proc-1'};

  @override
  Future<Map<String, dynamic>> verify2fa(
    String processId,
    String code,
  ) async =>
      <String, dynamic>{'authenticated': true};

  @override
  Future<void> logout() async {
    loggedOut = true;
    fakeSnapshot = null;
    fakeTransactions = <TrTransactionModel>[];
  }
}

void main() {
  group('TrPortfolioProvider Tests', () {
    test('refresh updates state and handles success', () async {
      final FakeTrRepository repo = FakeTrRepository();
      final TrPortfolioProvider provider = TrPortfolioProvider(repository: repo);

      expect(provider.isLoading, isFalse);
      expect(provider.snapshot, isNull);

      await provider.refresh();

      expect(provider.snapshot, isNotNull);
      expect(provider.snapshot!.summary.totalInvested, 100);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.isSessionExpired, isFalse);
    });

    test('handles SessionExpired exception gracefully', () async {
      final FakeTrRepository repo = FakeTrRepository()..shouldExpireSession = true;
      final TrPortfolioProvider provider = TrPortfolioProvider(repository: repo);

      await provider.refresh();

      expect(provider.isSessionExpired, isTrue);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, contains('Sesión expirada'));
    });

    test('logout clears snapshot and resets authentication state', () async {
      final FakeTrRepository repo = FakeTrRepository();
      final TrPortfolioProvider provider = TrPortfolioProvider(repository: repo);

      await provider.refresh();
      expect(provider.snapshot, isNotNull);

      await provider.logout();
      expect(provider.snapshot, isNull);
      expect(provider.isAuthenticated, isFalse);
      expect(repo.loggedOut, isTrue);
    });
  });
}
