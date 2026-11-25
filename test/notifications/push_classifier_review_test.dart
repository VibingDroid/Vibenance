import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/notificationlistener.dart';
import 'package:vibenance/services/push_notification_service.dart';

void main() {
  group('Classifier review push routing & payload safety', () {
    test('identifies classifier review FCM data maps', () {
      expect(
        PushNotificationService.isClassifierReviewData(const <String, dynamic>{
          'type': 'classifier_review',
        }),
        isTrue,
      );
      expect(
        PushNotificationService.isClassifierReviewData(const <String, dynamic>{
          'route': 'ai_categorizer',
        }),
        isTrue,
      );
      expect(
        PushNotificationService.isClassifierReviewData(const <String, dynamic>{
          'count': '2',
          'sources': 'bbva',
        }),
        isFalse,
      );
      expect(PushNotificationService.isClassifierReviewData(null), isFalse);
    });

    test('identifies classifier review local notification payloads', () {
      final String jsonPayload = jsonEncode(const <String, String>{
        'type': 'classifier_review',
        'route': 'ai_categorizer',
      });
      expect(
        PushNotificationService.isClassifierReviewPayload(jsonPayload),
        isTrue,
      );
      expect(
        PushNotificationService.isClassifierReviewPayload('classifier_review'),
        isTrue,
      );
      expect(
        PushNotificationService.isClassifierReviewPayload('push_test'),
        isFalse,
      );
      expect(PushNotificationService.isClassifierReviewPayload(''), isFalse);
    });

    test(
      'safely parses NotificationTransaction and ignores non-NL payloads',
      () {
        expect(tryParseNotificationTransaction('push_test'), isNull);
        expect(
          tryParseNotificationTransaction(
            jsonEncode(const <String, String>{'type': 'classifier_review'}),
          ),
          isNull,
        );

        final String validNl = jsonEncode(
          NotificationTransaction(
            'com.bbva.bbvacontigo',
            'Pago con tarjeta',
            'Compra 12,50 EUR',
            DateTime.utc(2026, 11, 25, 10, 0),
          ),
        );
        final NotificationTransaction? parsed = tryParseNotificationTransaction(
          validNl,
        );
        expect(parsed, isNotNull);
        expect(parsed!.appName, 'com.bbva.bbvacontigo');
        expect(parsed.title, 'Pago con tarjeta');
      },
    );

    test('tracks and consumes pending classifier review navigation once', () {
      final PushNotificationService service = PushNotificationService();
      // Clear any leftover state
      service.consumePendingClassifierReview();

      int notifications = 0;
      void listener() => notifications++;
      service.openClassifierReviewRequests.addListener(listener);
      addTearDown(
        () => service.openClassifierReviewRequests.removeListener(listener),
      );

      expect(service.consumePendingClassifierReview(), isFalse);
      service.requestOpenClassifierReview();
      expect(notifications, 1);
      expect(service.consumePendingClassifierReview(), isTrue);
      expect(service.consumePendingClassifierReview(), isFalse);
    });
  });
}
