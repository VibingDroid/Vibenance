import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibenance/features/trade_republic/data/models/tr_snapshot_model.dart';
import 'package:vibenance/features/trade_republic/data/tr_bridge_api_client.dart';

void main() {
  group('TrBridgeApiClient Tests', () {
    test('healthCheck returns true on 200 OK', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.url.path, '/api/v1/health');
        expect(request.headers['X-Bridge-Api-Key'], 'test-token');
        return http.Response('{"status": "ok", "authenticated": true}', 200);
      });

      final TrBridgeApiClient client = TrBridgeApiClient(
        baseUrl: 'https://tr-bridge.local:8085',
        apiKey: 'test-token',
        httpClient: mockClient,
      );

      final bool isHealthy = await client.healthCheck();
      expect(isHealthy, isTrue);
    });

    test('healthCheck returns false on error response', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        return http.Response('{"error": "unauthorized"}', 401);
      });

      final TrBridgeApiClient client = TrBridgeApiClient(
        baseUrl: 'https://tr-bridge.local:8085',
        apiKey: 'bad-token',
        httpClient: mockClient,
      );

      final bool isHealthy = await client.healthCheck();
      expect(isHealthy, isFalse);
    });

    test('login returns process_id on success', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.url.path, '/api/v1/auth/login');
        final Map<String, dynamic> body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['phone_number'], '+34600000000');
        expect(body['pin'], '1234');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'process_id': 'proc-abc-123',
            'countdown_seconds': 60,
            'message': 'Código enviado a la app de Trade Republic',
          }),
          200,
        );
      });

      final TrBridgeApiClient client = TrBridgeApiClient(
        baseUrl: 'https://tr-bridge.local:8085',
        apiKey: 'key',
        httpClient: mockClient,
      );

      final Map<String, dynamic> res = await client.login('+34600000000', '1234');
      expect(res['process_id'], 'proc-abc-123');
    });

    test('getSnapshot throws TrSessionExpiredException on 401 TR_SESSION_EXPIRED', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'error_code': 'TR_SESSION_EXPIRED',
            'message': 'Session expired',
          }),
          401,
        );
      });

      final TrBridgeApiClient client = TrBridgeApiClient(
        baseUrl: 'https://tr-bridge.local:8085',
        apiKey: 'key',
        httpClient: mockClient,
      );

      expect(
        () => client.getSnapshot(),
        throwsA(isA<TrSessionExpiredException>()),
      );
    });

    test('getSnapshot parses valid snapshot JSON', () async {
      final MockClient mockClient = MockClient((http.Request request) async {
        expect(request.url.queryParameters['enrich'], 'true');
        return http.Response(
          jsonEncode(<String, dynamic>{
            'summary': <String, dynamic>{
              'total_invested': 500.0,
              'current_value': 600.0,
              'profit_loss_abs': 100.0,
              'profit_loss_pct': 20.0,
              'cash_balance': 50.0,
              'currency': 'EUR',
              'iban': 'DE1234',
            },
            'positions': <dynamic>[],
            'savings_plans': <dynamic>[],
            'fetched_at': '2026-10-31T21:00:00Z',
          }),
          200,
        );
      });

      final TrBridgeApiClient client = TrBridgeApiClient(
        baseUrl: 'https://tr-bridge.local:8085',
        apiKey: 'key',
        httpClient: mockClient,
      );

      final TrSnapshotModel snapshot = await client.getSnapshot();
      expect(snapshot.summary.totalInvested, 500.0);
      expect(snapshot.summary.currentValue, 600.0);
      expect(snapshot.summary.cashBalance, 50.0);
    });
  });
}
