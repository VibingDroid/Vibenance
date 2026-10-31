import 'package:flutter_test/flutter_test.dart';
import 'package:vibenance/services/investments/models/portfolio.dart';
import 'package:vibenance/services/investments/portfolio_parser.dart';

void main() {
  group('PortfolioNotesParser Tests', () {
    test('parses empty or null notes as null', () {
      expect(PortfolioNotesParser.parsePortfolio(null), isNull);
      expect(PortfolioNotesParser.parsePortfolio(''), isNull);
      expect(
        PortfolioNotesParser.parsePortfolio('Notas del usuario sin cartera'),
        isNull,
      );
    });

    test('parses well-formed portfolio block from notes', () {
      const String notes = '''
Nota anterior del usuario: cuenta de inversión en Trade Republic.
IBAN personal guardado.

---VIBENANCE_PORTFOLIO_START---
{
  "version": 1,
  "broker": "trade_republic",
  "updated_at": "2026-10-31T21:00:00.000Z",
  "processed_transaction_ids": ["1042", "1089", "1120"],
  "holdings": [
    {
      "isin": "IE00B4L5Y983",
      "ticker": "EUNL.DE",
      "name": "Core MSCI World USD (Acc)",
      "category": "RV Global",
      "shares": 42.154821,
      "invested_amount": 3850.00
    }
  ]
}
---VIBENANCE_PORTFOLIO_END---

Texto posterior que tampoco debe borrarse.
''';

      final Portfolio? portfolio = PortfolioNotesParser.parsePortfolio(notes);
      expect(portfolio, isNotNull);
      expect(portfolio!.version, equals(1));
      expect(portfolio.broker, equals('trade_republic'));
      expect(
        portfolio.processedTransactionIds,
        equals(<String>['1042', '1089', '1120']),
      );
      expect(portfolio.holdings.length, equals(1));

      final Holding holding = portfolio.holdings.first;
      expect(holding.isin, equals('IE00B4L5Y983'));
      expect(holding.ticker, equals('EUNL.DE'));
      expect(holding.name, equals('Core MSCI World USD (Acc)'));
      expect(holding.category, equals('RV Global'));
      expect(holding.shares, equals(42.154821));
      expect(holding.investedAmount, equals(3850.0));
      expect(holding.averageBuyPrice, closeTo(3850.0 / 42.154821, 0.0001));
    });

    test('preserves user text outside portfolio block when updating notes', () {
      const String initialNotes = '''
Notas del usuario importantes:
- IBAN DE123456789
- Custodio solar

---VIBENANCE_PORTFOLIO_START---
{
  "version": 1,
  "broker": "trade_republic",
  "updated_at": "2026-10-01T10:00:00.000Z",
  "processed_transaction_ids": ["101"],
  "holdings": []
}
---VIBENANCE_PORTFOLIO_END---

Fin de notas personalizadas.
''';

      final Portfolio updatedPortfolio = Portfolio(
        version: 1,
        broker: 'trade_republic',
        updatedAt: DateTime.parse('2026-10-31T21:00:00Z'),
        processedTransactionIds: <String>['101', '102'],
        holdings: <Holding>[
          Holding(
            isin: 'IE00BK5BQT80',
            ticker: 'VWCE.DE',
            name: 'Vanguard FTSE All-World',
            shares: 10.543210,
            investedAmount: 1200.50,
          ),
        ],
      );

      final String resultNotes = PortfolioNotesParser.updateNotesWithPortfolio(
        initialNotes,
        updatedPortfolio,
      );

      // Verifica que el texto anterior y posterior se mantenga intacto
      expect(resultNotes.contains('Notas del usuario importantes:'), isTrue);
      expect(resultNotes.contains('- IBAN DE123456789'), isTrue);
      expect(resultNotes.contains('Fin de notas personalizadas.'), isTrue);

      // Verifica que el nuevo bloque contenga los nuevos datos
      final Portfolio? parsedBack = PortfolioNotesParser.parsePortfolio(
        resultNotes,
      );
      expect(parsedBack, isNotNull);
      expect(
        parsedBack!.processedTransactionIds,
        equals(<String>['101', '102']),
      );
      expect(parsedBack.holdings.length, equals(1));
      expect(parsedBack.holdings.first.isin, equals('IE00BK5BQT80'));
      expect(parsedBack.holdings.first.shares, equals(10.543210));
    });

    test(
      'appends portfolio to existing notes when no tags present without destroying text',
      () {
        const String initialNotes =
            'Solo unas notas que ya existían en Firefly III.';

        final Portfolio newPortfolio = Portfolio(
          version: 1,
          broker: 'trade_republic',
          holdings: <Holding>[
            Holding(
              isin: 'US0378331005',
              ticker: 'APC.F',
              name: 'Apple Inc.',
              shares: 5.0,
              investedAmount: 950.0,
            ),
          ],
        );

        final String resultNotes =
            PortfolioNotesParser.updateNotesWithPortfolio(
              initialNotes,
              newPortfolio,
            );

        expect(
          resultNotes.startsWith(
            'Solo unas notas que ya existían en Firefly III.',
          ),
          isTrue,
        );
        expect(resultNotes.contains(PortfolioNotesParser.startTag), isTrue);
        expect(resultNotes.contains(PortfolioNotesParser.endTag), isTrue);

        final Portfolio? parsed = PortfolioNotesParser.parsePortfolio(
          resultNotes,
        );
        expect(parsed, isNotNull);
        expect(parsed!.holdings.first.ticker, equals('APC.F'));
      },
    );
  });

  group('Regex Matcher Tests', () {
    test('extracts valid European ISINs from diverse transaction texts', () {
      expect(
        PortfolioNotesParser.extractIsin(
          'Plan de inversión IE00B4L5Y983 Core MSCI World',
        ),
        equals('IE00B4L5Y983'),
      );
      expect(
        PortfolioNotesParser.extractIsin(
          'Compra LU1681045370 Amundi Prime Global',
        ),
        equals('LU1681045370'),
      );
      expect(
        PortfolioNotesParser.extractIsin('Transferencia nómina sin ISIN'),
        isNull,
      );
      expect(
        PortfolioNotesParser.extractIsin('US0378331005 Apple Inc'),
        equals('US0378331005'),
      );
    });

    test(
      'extracts shares from transaction description with decimal formats',
      () {
        expect(
          PortfolioNotesParser.extractShares('Compra de 4.125678 títulos'),
          equals(4.125678),
        );
        expect(
          PortfolioNotesParser.extractShares('Ejecutadas 12,500000 acciones'),
          equals(12.5),
        );
        expect(
          PortfolioNotesParser.extractShares('shares: 0.854321 en broker'),
          equals(0.854321),
        );
        expect(
          PortfolioNotesParser.extractShares('Traspaso periódico mensual'),
          isNull,
        );
      },
    );
  });
}
