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
  Future<Map<String, dynamic>> checkHealth({String? baseUrl, String? apiKey});
  Future<TrSnapshotModel?> getCachedSnapshot();
  Future<TrSnapshotModel> fetchSnapshot({bool enrich = true});
  Future<TrSnapshotModel> refreshSnapshot({bool enrich = true});
  Future<List<TrTransactionModel>> getTransactions();
  Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  });
  Future<Map<String, dynamic>> verify({
    required String processId,
    required String code,
    String? phone,
  });
  Future<void> logout();
}

class TrRepositoryImpl implements TrRepository {
  TrRepositoryImpl({
    required TrBridgeApiClient client,
    required TrLocalCacheService cacheService,
    SettingsProvider? settingsProvider,
  })  : _client = client,
        _cacheService = cacheService,
        _settings = settingsProvider ?? SettingsProvider();

  final TrBridgeApiClient _client;
  final TrLocalCacheService _cacheService;
  final SettingsProvider _settings;
  TrConfigModel _currentConfig = const TrConfigModel();
  bool _hasLoadedConfig = false;

  Future<void> _ensureConfigLoaded() async {
    if (!_hasLoadedConfig) {
      await loadConfig();
    }
  }

  @override
  Future<TrConfigModel> loadConfig() async {
    final bool isEnabled = await _settings.trIntegrationEnabled;
    final String bridgeUrl = await _settings.trBridgeUrl;
    final String bridgeApiKey = await _settings.trBridgeApiKey;
    final String? fireflyAssetAccountId = await _settings.trFireflyAccountId;
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
    await _settings.setTrIntegrationEnabled(config.isEnabled);
    await _settings.setTrBridgeUrl(config.bridgeUrl);
    await _settings.setTrBridgeApiKey(config.bridgeApiKey);
    await _settings.setTrFireflyAccountId(config.fireflyAssetAccountId);
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
  Future<Map<String, dynamic>> checkHealth({
    String? baseUrl,
    String? apiKey,
  }) async {
    if (baseUrl == null && _client.baseUrl.isEmpty) {
      await _ensureConfigLoaded();
    }
    return _client.checkHealth(
      overrideUrl: baseUrl,
      overrideApiKey: apiKey,
    );
  }

  @override
  Future<TrSnapshotModel?> getCachedSnapshot() {
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
  Future<TrSnapshotModel> refreshSnapshot({bool enrich = true}) {
    return fetchSnapshot(enrich: enrich);
  }

  @override
  Future<List<TrTransactionModel>> getTransactions() async {
    await _ensureConfigLoaded();
    return _client.getTransactions();
  }

  @override
  Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) async {
    await _ensureConfigLoaded();
    return _client.login(phoneNumber: phone, pin: pin);
  }

  @override
  Future<Map<String, dynamic>> verify({
    required String processId,
    required String code,
    String? phone,
  }) async {
    await _ensureConfigLoaded();
    return _client.verify(
      processId: processId,
      code: code,
      phoneNumber: phone,
    );
  }

  @override
  Future<void> logout() async {
    await _ensureConfigLoaded();
    await _client.logout();
    await _cacheService.clear();
  }
}
