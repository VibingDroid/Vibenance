import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_transaction_model.dart';

class TrApiException implements Exception {
  const TrApiException(this.message, {this.errorCode, this.statusCode});
  final String message;
  final String? errorCode;
  final int? statusCode;

  @override
  String toString() => 'TrApiException($errorCode, status: $statusCode): $message';
}

class TrSessionExpiredException extends TrApiException {
  const TrSessionExpiredException(super.message, {super.statusCode = 401})
      : super(errorCode: 'TR_SESSION_EXPIRED');
}

class TrBridgeApiClient {
  TrBridgeApiClient({
    required String baseUrl,
    String apiKey = '',
    http.Client? httpClient,
  })  : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _apiKey = apiKey,
        _client = httpClient ?? http.Client();

  final String _baseUrl;
  final String _apiKey;
  final http.Client _client;

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_apiKey.isNotEmpty) 'X-Bridge-Api-Key': _apiKey,
      };

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    final String fullUrl = '$_baseUrl$cleanPath';
    final Uri uri = Uri.parse(fullUrl);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParameters.map(
          (String k, dynamic v) => MapEntry<String, String>(k, v.toString()),
        ),
      );
    }
    return uri;
  }

  Future<Map<String, dynamic>> checkHealth({
    String? overrideUrl,
    String? overrideApiKey,
  }) async {
    final String targetBase = (overrideUrl != null && overrideUrl.isNotEmpty)
        ? overrideUrl.replaceAll(RegExp(r'/+$'), '')
        : _baseUrl;
    final Uri uri = Uri.parse('$targetBase/api/v1/health');
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      if ((overrideApiKey ?? _apiKey).isNotEmpty)
        'X-Bridge-Api-Key': (overrideApiKey ?? _apiKey),
    };

    final http.Response response = await _client.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw TrApiException(
      'Error connecting to bridge health: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String pin,
  }) async {
    final Uri uri = _buildUri('/api/v1/auth/login');
    final http.Response response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(<String, String>{
        'phone_number': phoneNumber,
        'pin': pin,
      }),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verify({
    required String processId,
    required String code,
    String? phoneNumber,
  }) async {
    final Uri uri = _buildUri('/api/v1/auth/verify');
    final http.Response response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(<String, dynamic>{
        'process_id': processId,
        'code': code,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      }),
    );

    return _handleResponse(response);
  }

  Future<void> logout() async {
    final Uri uri = _buildUri('/api/v1/auth/logout');
    final http.Response response = await _client.post(uri, headers: _headers);
    _handleResponse(response);
  }

  Future<TrSnapshotModel> fetchPortfolioSnapshot({
    bool enrich = true,
    bool includeSavingsPlans = true,
  }) async {
    final Uri uri = _buildUri('/api/v1/portfolio/snapshot', <String, dynamic>{
      'enrich': enrich,
      'include_savings_plans': includeSavingsPlans,
    });

    final http.Response response = await _client.get(uri, headers: _headers);
    final Map<String, dynamic> data = _handleResponse(response);
    return TrSnapshotModel.fromJson(data);
  }

  Future<List<TrTransactionModel>> fetchTransactions({String? since}) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (since != null) {
      query['since'] = since;
    }
    final Uri uri = _buildUri('/api/v1/transactions', query);

    final http.Response response = await _client.get(uri, headers: _headers);
    final Map<String, dynamic> data = _handleResponse(response);
    final List<dynamic>? items = data['items'] as List<dynamic>?;
    if (items == null) {
      return <TrTransactionModel>[];
    }
    return items
        .map((dynamic it) =>
            TrTransactionModel.fromJson(it as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        // Not JSON
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final String? errorCode = body['error_code'] as String? ??
        (body['detail'] is Map ? body['detail']['error_code'] : null);
    final String message = body['message'] as String? ??
        (body['detail'] is Map
            ? body['detail']['message']
            : (body['detail']?.toString() ?? 'HTTP error ${response.statusCode}'));

    if (response.statusCode == 401 && errorCode == 'TR_SESSION_EXPIRED') {
      throw TrSessionExpiredException(message, statusCode: response.statusCode);
    }

    throw TrApiException(
      message,
      errorCode: errorCode,
      statusCode: response.statusCode,
    );
  }
}
