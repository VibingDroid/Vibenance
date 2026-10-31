import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger log = Logger('Services.Investments.MarketQuoteService');

class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.regularMarketPrice,
    required this.previousClose,
    required this.currency,
    required this.timestamp,
    this.longName,
  });

  final String symbol;
  final double regularMarketPrice;
  final double previousClose;
  final String currency;
  final DateTime timestamp;
  final String? longName;

  double get dayChange => regularMarketPrice - previousClose;

  double get dayChangePercent =>
      previousClose > 0 ? (dayChange / previousClose) * 100 : 0.0;
}

class MarketQuoteService {
  MarketQuoteService({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Duration cacheTtl = Duration(minutes: 5);
  final Map<String, ({MarketQuote quote, DateTime cachedAt})> _cache =
      <String, ({MarketQuote quote, DateTime cachedAt})>{};

  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json',
  };

  void clearCache() {
    _cache.clear();
  }

  /// Resuelve un ISIN al ticker más idóneo,
  /// priorizando mercados europeos (XETRA .DE, Frankfurt .F en EUR).
  Future<String?> resolveIsinToTicker(String isin) async {
    final String cleanIsin = isin.trim().toUpperCase();
    if (cleanIsin.isEmpty) return null;

    final Uri uri = Uri.parse(
      'https://query1.finance.yahoo.com/v1/finance/search?q=$cleanIsin&quotesCount=10',
    );

    try {
      final http.Response res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) {
        log.warning('Yahoo search failed for ISIN $cleanIsin (status ${res.statusCode})');
        return null;
      }

      final dynamic data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return null;

      final List<dynamic>? quotes = data['quotes'] as List<dynamic>?;
      if (quotes == null || quotes.isEmpty) return null;

      String? bestSymbol;
      int highestScore = -1;

      for (final dynamic item in quotes) {
        if (item is! Map<String, dynamic>) continue;
        final String? sym = item['symbol'] as String?;
        if (sym == null || sym.isEmpty) continue;

        final String upperSym = sym.toUpperCase();
        final String exch = (item['exchange'] as String? ?? '').toUpperCase();

        int score = 10;
        if (upperSym.endsWith('.DE')) {
          score = 100; // XETRA preferente
        } else if (upperSym.endsWith('.F')) {
          score = 90; // Frankfurt
        } else if (exch.contains('GER') || exch.contains('FRA') || exch.contains('XETRA')) {
          score = 80;
        } else if (upperSym.endsWith('.PA') || upperSym.endsWith('.AS') || upperSym.endsWith('.MC')) {
          score = 60; // Euronext / Madrid
        } else if (upperSym.endsWith('.L')) {
          score = 40; // LSE
        }

        if (score > highestScore) {
          highestScore = score;
          bestSymbol = sym;
        }
      }

      return bestSymbol;
    } catch (e, stack) {
      log.warning('Error resolving ISIN $cleanIsin: $e', e, stack);
      return null;
    }
  }

  /// Obtiene la cotización en tiempo real para un ticker,
  /// utilizando caché en memoria de 5 minutos a menos que forceRefresh sea true.
  Future<MarketQuote?> fetchQuote(String ticker, {bool forceRefresh = false}) async {
    final String cleanTicker = ticker.trim().toUpperCase();
    if (cleanTicker.isEmpty) return null;

    final DateTime now = DateTime.now();
    if (!forceRefresh && _cache.containsKey(cleanTicker)) {
      final ({MarketQuote quote, DateTime cachedAt}) entry = _cache[cleanTicker]!;
      if (now.difference(entry.cachedAt) < cacheTtl) {
        return entry.quote;
      }
    }

    final Uri uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$cleanTicker?interval=1d&range=1d',
    );

    try {
      final http.Response res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) {
        log.warning('Yahoo quote fetch failed for $cleanTicker (status ${res.statusCode})');
        return null;
      }

      final dynamic data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return null;

      final Map<String, dynamic>? chart = data['chart'] as Map<String, dynamic>?;
      final List<dynamic>? results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final Map<String, dynamic>? meta = results[0]['meta'] as Map<String, dynamic>?;
      if (meta == null) return null;

      final num? rawPrice = meta['regularMarketPrice'] as num?;
      final num? rawPrevClose = meta['chartPreviousClose'] as num? ?? rawPrice;
      final String currency = meta['currency'] as String? ?? 'EUR';
      final String? name = meta['longName'] as String? ?? meta['shortName'] as String?;

      if (rawPrice == null) return null;

      final MarketQuote quote = MarketQuote(
        symbol: cleanTicker,
        regularMarketPrice: rawPrice.toDouble(),
        previousClose: (rawPrevClose ?? rawPrice).toDouble(),
        currency: currency,
        timestamp: now,
        longName: name,
      );

      _cache[cleanTicker] = (quote: quote, cachedAt: now);
      return quote;
    } catch (e, stack) {
      log.warning('Error fetching quote for $cleanTicker: $e', e, stack);
      return null;
    }
  }

  /// Obtiene cotizaciones en lote para una lista de tickers
  Future<Map<String, MarketQuote>> fetchQuotes(
    List<String> tickers,
    {bool forceRefresh = false},
  ) async {
    final Map<String, MarketQuote> results = <String, MarketQuote>{};
    for (final String t in tickers) {
      final MarketQuote? q = await fetchQuote(t, forceRefresh: forceRefresh);
      if (q != null) {
        results[t.trim().toUpperCase()] = q;
      }
    }
    return results;
  }

  /// Consulta el precio de cierre de un día concreto (necesario para estimar participaciones en compras importadas)
  Future<double?> fetchHistoricalClosePrice(String ticker, DateTime date) async {
    final String cleanTicker = ticker.trim().toUpperCase();
    if (cleanTicker.isEmpty) return null;

    // Ventana de 4 días hacia atrás por si la fecha cayó en fin de semana o festivo de mercado
    final DateTime startWindow = date.subtract(const Duration(days: 4));
    final DateTime endWindow = date.add(const Duration(days: 1));

    final int period1 = startWindow.toUtc().millisecondsSinceEpoch ~/ 1000;
    final int period2 = endWindow.toUtc().millisecondsSinceEpoch ~/ 1000;

    final Uri uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$cleanTicker?period1=$period1&period2=$period2&interval=1d',
    );

    try {
      final http.Response res = await _client.get(uri, headers: _headers);
      if (res.statusCode != 200) {
        log.warning('Historical quote failed for $cleanTicker at $date (${res.statusCode})');
        return null;
      }

      final dynamic data = jsonDecode(res.body);
      if (data is! Map<String, dynamic>) return null;

      final Map<String, dynamic>? chart = data['chart'] as Map<String, dynamic>?;
      final List<dynamic>? results = chart?['result'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;

      final Map<String, dynamic> firstResult = results[0] as Map<String, dynamic>;
      final Map<String, dynamic>? indicators = firstResult['indicators'] as Map<String, dynamic>?;
      final List<dynamic>? quoteList = indicators?['quote'] as List<dynamic>?;

      if (quoteList != null && quoteList.isNotEmpty) {
        final Map<String, dynamic> quoteData = quoteList[0] as Map<String, dynamic>;
        final List<dynamic>? closeValues = quoteData['close'] as List<dynamic>?;
        if (closeValues != null && closeValues.isNotEmpty) {
          // Selecciona el último valor de cierre válido dentro del rango
          for (int i = closeValues.length - 1; i >= 0; i--) {
            final dynamic val = closeValues[i];
            if (val is num && val > 0) {
              return val.toDouble();
            }
          }
        }
      }

      // Fallback a chartPreviousClose o regularMarketPrice si vino en meta
      final Map<String, dynamic>? meta = firstResult['meta'] as Map<String, dynamic>?;
      final num? fallback = meta?['chartPreviousClose'] as num? ?? meta?['regularMarketPrice'] as num?;
      return fallback?.toDouble();
    } catch (e, stack) {
      log.warning('Error fetching historical close price for $cleanTicker: $e', e, stack);
      return null;
    }
  }
}
