import 'package:vibenance/features/trade_republic/data/models/tr_config_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';
import 'package:vibenance/features/trade_republic/data/tr_bridge_api_client.dart';
import 'package:vibenance/features/trade_republic/data/tr_local_cache_service.dart';
import 'package:vibenance/settings.dart';

abstract class TrRepository {
  Future<TrConfigModel> loadConfig();
  Future<void> saveConfig(TrConfigModel config);
  Future<bool> testConnection({String? baseUrl, String? apiKey});
  Future<TrSnapshotModel?> getCachedSnapshot();
  Future<TrSnapshotModel> fetchSnapshot({bool enrich = true});
  Future<List<TrTransactionModel>> fetchTransactions();
  Future<Map<String, dynamic>> login(String phoneNumber, String pin);
  Future<Map<String, dynamic>> verify2fa(String processId, String code);
  Future<void> logout();
}

class TrRepositoryImpl implements TrRepository {
  TrRepositoryImpl({
    required TrBridgeApiClient client,
    required TrLocalCacheService cacheService,
  })  : _client = client,
        _cacheService = cacheService;

  final TrBridgeApiClient _client;
  final TrLocalCacheService _cacheService;
  TrConfigModel _currentConfig = const TrConfigModel();
  bool _hasLoadedConfig = false;

  Future<void> _ensureConfigLoaded() async {
    if (!_hasLoadedConfig) {
      await loadConfig();
    }
  }

  @override
  Future<TrConfigModel> loadConfig() async {
    final Settings settings = Settings();
    final bool isEnabled = await settings.trIntegrationEnabled;
    final String bridgeUrl = await settings.trBridgeUrl;
    final String bridgeApiKey = await settings.trBridgeApiKey;
    final String? fireflyAssetAccountId = await settings.trFireflyAccountId;
    _currentConfig = TrConfigModel(
      isEnabled: isEnabled,
      bridgeUrl: bridgeUrl,
      bridgeApiKey: bridgeApiKey,
      fireflyAssetAccountId: fireflyAssetAccountId,
    );
    _client.updateConfig(baseUrl: bridgeUrl, apiKey: bridgeApiKey);
    _hasLoadedConfig = true;
    return _currentConfig;
  }

  @override
  Future<void> saveConfig(TrConfigModel config) async {
    final Settings settings = Settings();
    settings.trIntegrationEnabled = Future<bool>.value(config.isEnabled);
    settings.trBridgeUrl = Future<String>.value(config.bridgeUrl);
    settings.trBridgeApiKey = Future<String>.value(config.bridgeApiKey);
    settings.trFireflyAccountId =
        Future<String?>.value(config.fireflyAssetAccountId);
    _currentConfig = config;
    _client.updateConfig(baseUrl: config.bridgeUrl, apiKey: config.bridgeApiKey);
    _hasLoadedConfig = true;
  }

  @override
  Future<bool> testConnection({String? baseUrl, String? apiKey}) async {
    if (baseUrl == null && _client.baseUrl.isEmpty) {
      await _ensureConfigLoaded();
    }
    return _client.healthCheck(testUrl: baseUrl, testApiKey: apiKey);
  }

  @override
  Future<TrSnapshotModel?> getCachedSnapshot() async {
    return _cacheService.loadSnapshot();
  }

  @override
  Future<TrSnapshotModel> fetchSnapshot({bool enrich = true}) async {
    await _ensureConfigLoaded();
    final TrSnapshotModel snapshot = await _client.getSnapshot(enrich: enrich);
    await _cacheService.saveSnapshot(snapshot);
    return snapshot;
  }

  @override
  Future<List<TrTransactionModel>> fetchTransactions() async {
    await _ensureConfigLoaded();
    return _client.getTransactions();
  }

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String pin) async {
    await _ensureConfigLoaded();
    return _client.login(phoneNumber, pin);
  }

  @override
  Future<Map<String, dynamic>> verify2fa(
    String processId,
    String code,
  ) async {
    await _ensureConfigLoaded();
    return _client.verify(processId, code);
  }

  @override
  Future<void> logout() async {
    await _ensureConfigLoaded();
    await _client.logout();
    await _cacheService.clear();
  }
}
