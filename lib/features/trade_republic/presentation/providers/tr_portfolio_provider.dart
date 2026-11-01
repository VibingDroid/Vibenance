import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';
import 'package:vibenance/features/trade_republic/data/tr_bridge_api_client.dart';
import 'package:vibenance/features/trade_republic/domain/tr_repository.dart';

final Logger _log = Logger('TR.PortfolioProvider');

class TrPortfolioProvider extends ChangeNotifier {
  TrPortfolioProvider({required TrRepository repository})
    : _repository = repository;

  final TrRepository _repository;
  TrRepository get repository => _repository;

  TrSnapshotModel? _snapshot;
  TrSnapshotModel? get snapshot => _snapshot;

  List<TrTransactionModel> _transactions = <TrTransactionModel>[];
  List<TrTransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  bool _isSessionExpired = false;
  bool get isSessionExpired => _isSessionExpired;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastRefreshedAt;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Offline-First: Load cached snapshot immediately
    _snapshot = await _repository.getCachedSnapshot();
    if (_snapshot != null) {
      _lastRefreshedAt = _snapshot!.fetchedAt;
    }
    _isLoading = false;
    notifyListeners();

    // 2. Refresh live in background
    await refresh();
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Health check first to verify session validity
      final Map<String, dynamic> health = await _repository.checkHealth();
      _isAuthenticated = health['authenticated'] == true;

      if (_isAuthenticated) {
        _snapshot = await _repository.refreshSnapshot();
        _lastRefreshedAt = _snapshot!.fetchedAt;
        _isSessionExpired = false;

        // Load transactions in background
        try {
          _transactions = await _repository.getTransactions();
        } catch (e) {
          _log.warning('Could not fetch TR transactions: $e');
        }
      } else {
        _isSessionExpired = true;
      }
    } on TrSessionExpiredException catch (e) {
      _log.info('TR session expired: $e');
      _isAuthenticated = false;
      _isSessionExpired = true;
      _errorMessage =
          'Tu sesión en Trade Republic ha caducado. Vuelve a iniciar sesión.';
    } on TrApiException catch (e) {
      _log.warning('TR API error: $e');
      _errorMessage = e.message;
    } catch (e, stack) {
      _log.severe('Unexpected error during TR refresh', e, stack);
      _errorMessage = 'Error de conexión con el puente de Trade Republic';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Map<String, dynamic> result = await _repository.login(
        phone: phone,
        pin: pin,
      );
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verify({
    required String processId,
    required String code,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Map<String, dynamic> result = await _repository.verify(
        processId: processId,
        code: code,
        phone: phone,
      );
      if (result['authenticated'] == true) {
        _isAuthenticated = true;
        _isSessionExpired = false;
        // Trigger fresh portfolio snapshot
        await refresh();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
      _isAuthenticated = false;
      _isSessionExpired = false;
      _snapshot = null;
      _transactions = <TrTransactionModel>[];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
