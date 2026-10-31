import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';

final Logger _log = Logger('TR.LocalCacheService');

class TrLocalCacheService {
  static const String _snapshotCacheKey = 'tr_portfolio_snapshot_cache';

  Future<void> saveSnapshot(TrSnapshotModel snapshot) async {
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String jsonStr = jsonEncode(snapshot.toJson());
      await prefs.setString(_snapshotCacheKey, jsonStr);
    } catch (e, stack) {
      _log.warning('Error saving TR snapshot to cache', e, stack);
    }
  }

  Future<TrSnapshotModel?> loadSnapshot() async {
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      final String? jsonStr = await prefs.getString(_snapshotCacheKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        return null;
      }
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return TrSnapshotModel.fromJson(decoded);
      }
    } catch (e, stack) {
      _log.warning('Error loading TR snapshot from cache', e, stack);
    }
    return null;
  }

  Future<void> clearCache() async {
    try {
      final SharedPreferencesAsync prefs = SharedPreferencesAsync();
      await prefs.remove(_snapshotCacheKey);
    } catch (e, stack) {
      _log.warning('Error clearing TR snapshot cache', e, stack);
    }
  }
}
