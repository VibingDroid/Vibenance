import 'package:flutter/material.dart';

/// Metadata for a bank or neobank used when rendering badges and CSV exports.
@immutable
class BankInfo {
  final String shortLabel;
  final String fullName;
  final Color color;

  const BankInfo({
    required this.shortLabel,
    required this.fullName,
    required this.color,
  });
}

// --- Traditional banks operating in Spain ---

const BankInfo _bbva = BankInfo(
  shortLabel: 'BBVA',
  fullName: 'BBVA',
  color: Color(0xFF004481),
);

const BankInfo _santander = BankInfo(
  shortLabel: 'SAN',
  fullName: 'Santander',
  color: Color(0xFFEC0000),
);

const BankInfo _caixaBank = BankInfo(
  shortLabel: 'Caixa',
  fullName: 'CaixaBank',
  color: Color(0xFF00A9E0),
);

const BankInfo _ing = BankInfo(
  shortLabel: 'ING',
  fullName: 'ING',
  color: Color(0xFFFF6200),
);

const BankInfo _sabadell = BankInfo(
  shortLabel: 'SAB',
  fullName: 'Banco Sabadell',
  color: Color(0xFF007BC7),
);

const BankInfo _bankinter = BankInfo(
  shortLabel: 'BKT',
  fullName: 'Bankinter',
  color: Color(0xFFFF6600),
);

const BankInfo _abanca = BankInfo(
  shortLabel: 'Abanca',
  fullName: 'Abanca',
  color: Color(0xFF0066B3),
);

const BankInfo _ibercaja = BankInfo(
  shortLabel: 'Iber',
  fullName: 'Ibercaja',
  color: Color(0xFFE4002B),
);

const BankInfo _kutxabank = BankInfo(
  shortLabel: 'Kutxa',
  fullName: 'Kutxabank',
  color: Color(0xFF003865),
);

const BankInfo _unicaja = BankInfo(
  shortLabel: 'Uni',
  fullName: 'Unicaja Banco',
  color: Color(0xFF00833E),
);

const BankInfo _cajamar = BankInfo(
  shortLabel: 'CajaR',
  fullName: 'Cajamar Caja Rural',
  color: Color(0xFF009639),
);

const BankInfo _laboralKutxa = BankInfo(
  shortLabel: 'LabK',
  fullName: 'Laboral Kutxa',
  color: Color(0xFF00843D),
);

const BankInfo _evoBanco = BankInfo(
  shortLabel: 'EVO',
  fullName: 'EVO Banco',
  color: Color(0xFFFF5500),
);

const BankInfo _mediolanum = BankInfo(
  shortLabel: 'Medio',
  fullName: 'Banco Mediolanum',
  color: Color(0xFF0066A1),
);

const BankInfo _openbank = BankInfo(
  shortLabel: 'Open',
  fullName: 'Openbank',
  color: Color(0xFF1E1E1E),
);

const BankInfo _triodos = BankInfo(
  shortLabel: 'Trio',
  fullName: 'Triodos Bank',
  color: Color(0xFF00937D),
);

const BankInfo _deutscheBank = BankInfo(
  shortLabel: 'DB',
  fullName: 'Deutsche Bank',
  color: Color(0xFF0018A8),
);

// --- Neobanks / fintechs operating in Spain ---

const BankInfo _n26 = BankInfo(
  shortLabel: 'N26',
  fullName: 'N26',
  color: Color(0xFF36A18B),
);

const BankInfo _revolut = BankInfo(
  shortLabel: 'R',
  fullName: 'Revolut',
  color: Color(0xFF191C1F),
);

const BankInfo _wise = BankInfo(
  shortLabel: 'Wise',
  fullName: 'Wise',
  color: Color(0xFF2ED06E),
);

const BankInfo _paypal = BankInfo(
  shortLabel: 'PP',
  fullName: 'PayPal',
  color: Color(0xFF003087),
);

const BankInfo _bnext = BankInfo(
  shortLabel: 'Bnext',
  fullName: 'Bnext',
  color: Color(0xFFFF4F5A),
);

const BankInfo _myinvestor = BankInfo(
  shortLabel: 'MyInv',
  fullName: 'MyInvestor',
  color: Color(0xFFFF6A13),
);

const BankInfo _tradeRepublic = BankInfo(
  shortLabel: 'TR',
  fullName: 'Trade Republic',
  color: Color(0xFF00D47B),
);

// Spanish bank entity codes (4 digits after ES + 2 check digits).
const Map<String, BankInfo> _banksByEntityCode = <String, BankInfo>{
  '0182': _bbva,
  '0049': _santander,
  '2100': _caixaBank,
  '1465': _ing,
  '0081': _sabadell,
  '0128': _bankinter,
  '2080': _abanca,
  '2085': _ibercaja,
  '2095': _kutxabank,
  '2103': _unicaja,
  '3058': _cajamar,
  '3035': _laboralKutxa,
  '0239': _evoBanco,
  '0186': _mediolanum,
  '0073': _openbank,
  '1491': _triodos,
  '0019': _deutscheBank,
  '1563': _n26,
  '1583': _revolut,
};

// Keywords are checked in insertion order; more specific phrases are listed
// first to avoid shadowing by broader keywords.
const Map<String, BankInfo> _banksByKeyword = <String, BankInfo>{
  // Distinct digital / secondary brands first.
  'openbank': _openbank,
  'imagin': _caixaBank,
  'evobanco': _evoBanco,
  'evo banco': _evoBanco,
  'laboral kutxa': _laboralKutxa,
  'cajamar': _cajamar,
  'caja rural': _cajamar,
  'deutsche bank': _deutscheBank,

  // Main banks and neobanks.
  'bbva': _bbva,
  'santander': _santander,
  'caixa': _caixaBank,
  'ing': _ing,
  'sabadell': _sabadell,
  'bankinter': _bankinter,
  'abanca': _abanca,
  'ibercaja': _ibercaja,
  'kutxa': _kutxabank,
  'unicaja': _unicaja,
  'mediolanum': _mediolanum,
  'triodos': _triodos,
  'n26': _n26,
  'revolut': _revolut,
  'wise': _wise,
  'paypal': _paypal,
  'bnext': _bnext,
  'myinvestor': _myinvestor,
  'trade republic': _tradeRepublic,
};

final RegExp _whitespaceExp = RegExp(r'\s+');

/// Extracts the 4-digit Spanish bank entity code from [iban].
///
/// A Spanish IBAN has the form `ESxxEEEE...` where `xx` are the IBAN check
/// digits and `EEEE` is the bank entity code. Returns `null` when the IBAN is
/// missing, too short, or does not start with `ES`.
String? _extractSpanishEntityCode(String? iban) {
  if (iban == null || iban.isEmpty) return null;
  final String cleaned = iban.replaceAll(_whitespaceExp, '').toUpperCase();
  if (!cleaned.startsWith('ES')) return null;
  if (cleaned.length < 8) return null;
  return cleaned.substring(4, 8);
}

/// Detects a Spanish bank or neobank from an account name and optional IBAN.
///
/// Detection order:
/// 1. Spanish IBAN 4-digit entity code (`ESxxEEEE...`).
/// 2. Case-insensitive keywords in [accountName] when no Spanish IBAN matches
///    or the IBAN is empty.
///
/// Returns `null` when no bank can be detected.
BankInfo? detectBank(String accountName, String? iban) {
  final String? entityCode = _extractSpanishEntityCode(iban);
  if (entityCode != null) {
    final BankInfo? byCode = _banksByEntityCode[entityCode];
    if (byCode != null) return byCode;
  }

  final String normalizedName = accountName.trim().toLowerCase();
  if (normalizedName.isEmpty) return null;

  for (final MapEntry<String, BankInfo> entry in _banksByKeyword.entries) {
    if (normalizedName.contains(entry.key)) {
      return entry.value;
    }
  }

  return null;
}
