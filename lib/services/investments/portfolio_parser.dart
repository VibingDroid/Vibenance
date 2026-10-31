import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:vibenance/services/investments/models/portfolio.dart';

final Logger log = Logger('Services.Investments.PortfolioNotesParser');

class PortfolioNotesParser {
  static const String startTag = '---VIBENANCE_PORTFOLIO_START---';
  static const String endTag = '---VIBENANCE_PORTFOLIO_END---';

  /// Regex para detectar ISIN (2 letras de país + 9 caracteres alfanuméricos + 1 dígito de control)
  static final RegExp isinRegex = RegExp(r'\b([A-Z]{2}[A-Z0-9]{9}[0-9])\b');

  /// Regex para intentar extraer número de participaciones de textos descriptivos
  /// Ej: "12.345678 títulos", "3,50 participaciones", "shares: 10", "4.123456 uds"
  static final RegExp sharesRegex = RegExp(
    r'(?:shares|t[ií]tulos|participaciones|acciones|uds|unidades)[\s:]+([0-9]+(?:[.,][0-9]+)?)|([0-9]+(?:[.,][0-9]+)?)\s*(?:shares|t[ií]tulos|participaciones|acciones|acc\.|uds|unidades)',
    caseSensitive: false,
  );

  /// Parsea el bloque JSON de cartera embebido en las notas de la cuenta.
  /// Retorna null si no existe el bloque o si ocurre un error de parsing.
  static Portfolio? parsePortfolio(String? notes) {
    if (notes == null || notes.isEmpty) {
      return null;
    }

    final int startIndex = notes.indexOf(startTag);
    final int endIndex = notes.indexOf(endTag);

    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      return null;
    }

    final String jsonContent = notes
        .substring(startIndex + startTag.length, endIndex)
        .trim();

    if (jsonContent.isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is Map<String, dynamic>) {
        return Portfolio.fromJson(decoded);
      }
    } catch (e, stack) {
      log.warning('Error decoding portfolio json from notes: $e', e, stack);
    }
    return null;
  }

  /// Inserta o reemplaza el bloque de cartera en las notas,
  /// preservando exactamente todo el texto fuera de las etiquetas.
  static String updateNotesWithPortfolio(
    String? currentNotes,
    Portfolio portfolio,
  ) {
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    final String portfolioJson = encoder.convert(portfolio.toJson());
    final String block = '$startTag\n$portfolioJson\n$endTag';

    if (currentNotes == null || currentNotes.trim().isEmpty) {
      return block;
    }

    final int startIndex = currentNotes.indexOf(startTag);
    final int endIndex = currentNotes.indexOf(endTag);

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final String before = currentNotes.substring(0, startIndex);
      final String after = currentNotes.substring(endIndex + endTag.length);
      return '$before$block$after';
    } else {
      // No había bloque previo: anexar al final preservando notas existentes
      final String trimmed = currentNotes.trimRight();
      return '$trimmed\n\n$block\n';
    }
  }

  /// Extrae el primer ISIN válido encontrado en un texto
  static String? extractIsin(String? text) {
    if (text == null || text.isEmpty) return null;
    final Match? match = isinRegex.firstMatch(text);
    return match?.group(1);
  }

  /// Extrae el número de participaciones si viene especificado en la descripción
  static double? extractShares(String? text) {
    if (text == null || text.isEmpty) return null;
    final Match? match = sharesRegex.firstMatch(text);
    if (match != null) {
      final String? raw = match.group(1) ?? match.group(2);
      if (raw != null) {
        final String normalized = raw.replaceAll(',', '.');
        final double? val = double.tryParse(normalized);
        if (val != null && val > 0) {
          return double.parse(val.toStringAsFixed(6));
        }
      }
    }
    return null;
  }
}
