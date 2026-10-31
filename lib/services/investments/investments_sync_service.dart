import 'package:chopper/chopper.dart' show Response;
import 'package:logging/logging.dart';
import 'package:vibenance/auth.dart';
import 'package:vibenance/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:vibenance/services/investments/models/portfolio.dart';
import 'package:vibenance/services/investments/portfolio_parser.dart';

final Logger log = Logger('Services.Investments.InvestmentsSyncService');

class SyncCandidate {
  SyncCandidate({
    required this.transactionId,
    required this.journalId,
    required this.date,
    required this.amount,
    required this.description,
    this.detectedIsin,
    this.matchedHolding,
    this.suggestedShares,
  });

  final String transactionId;
  final String journalId;
  final DateTime date;
  final double amount;
  final String description;
  final String? detectedIsin;
  final Holding? matchedHolding;
  double? suggestedShares;
}

class InvestmentsSyncService {
  InvestmentsSyncService({required this.fireflyService});

  final FireflyService fireflyService;

  /// Lee la cuenta de inversión desde la API de Firefly III
  Future<AccountRead?> getAccount(String accountId) async {
    final FireflyIii api = fireflyService.api;
    try {
      final Response<AccountSingle> res = await api.v1AccountsIdGet(
        id: accountId,
      );
      if (res.isSuccessful && res.body != null) {
        return res.body!.data;
      }
    } catch (e, stack) {
      log.warning('Error fetching account $accountId: $e', e, stack);
    }
    return null;
  }

  /// Carga el portafolio parseándolo desde las notas de la cuenta
  Future<Portfolio> loadPortfolio(String accountId) async {
    final AccountRead? account = await getAccount(accountId);
    if (account == null) {
      return Portfolio();
    }
    final String? notes = account.attributes.notes;
    return PortfolioNotesParser.parsePortfolio(notes) ?? Portfolio();
  }

  /// Guarda el portafolio actualizado en las notas de la cuenta preservando notas previas
  Future<bool> savePortfolio(
    String accountId,
    Portfolio updatedPortfolio,
  ) async {
    final AccountRead? account = await getAccount(accountId);
    if (account == null) {
      return false;
    }

    final AccountProperties currentAttrs = account.attributes;
    final String currentNotes = currentAttrs.notes ?? '';
    final String newNotes = PortfolioNotesParser.updateNotesWithPortfolio(
      currentNotes,
      updatedPortfolio,
    );

    // Mapear AccountProperties a AccountUpdate preservando todos los campos requeridos
    final AccountUpdate updateBody = AccountUpdate(
      name: currentAttrs.name,
      iban: currentAttrs.iban,
      bic: currentAttrs.bic,
      accountNumber: currentAttrs.accountNumber,
      openingBalance: currentAttrs.openingBalance,
      openingBalanceDate: currentAttrs.openingBalanceDate,
      virtualBalance: currentAttrs.virtualBalance,
      currencyId: currentAttrs.currencyId,
      currencyCode: currentAttrs.currencyCode,
      active: currentAttrs.active,
      order: currentAttrs.order,
      includeNetWorth: currentAttrs.includeNetWorth,
      accountRole: currentAttrs.accountRole,
      creditCardType: currentAttrs.creditCardType,
      monthlyPaymentDate: currentAttrs.monthlyPaymentDate,
      liabilityType: currentAttrs.liabilityType,
      interest: currentAttrs.interest,
      interestPeriod: currentAttrs.interestPeriod,
      notes: newNotes,
      latitude: currentAttrs.latitude,
      longitude: currentAttrs.longitude,
      zoomLevel: currentAttrs.zoomLevel,
    );

    try {
      final Response<AccountSingle> putRes = await fireflyService.api
          .v1AccountsIdPut(id: accountId, body: updateBody);
      return putRes.isSuccessful;
    } catch (e, stack) {
      log.severe(
        'Error updating account $accountId with portfolio notes: $e',
        e,
        stack,
      );
      return false;
    }
  }

  /// Detecta transacciones candidatas a compra aún no procesadas en el portfolio
  Future<List<SyncCandidate>> findUnprocessedPurchases(
    String accountId,
    Portfolio portfolio,
  ) async {
    final List<SyncCandidate> candidates = <SyncCandidate>[];

    try {
      final Response<TransactionArray> res = await fireflyService.api
          .v1AccountsIdTransactionsGet(id: accountId, limit: 100);

      if (!res.isSuccessful || res.body == null) {
        return candidates;
      }

      final List<TransactionRead> txList = res.body!.data;
      for (final TransactionRead tr in txList) {
        final String txId = tr.id;
        if (portfolio.isTransactionProcessed(txId)) {
          continue;
        }

        final List<TransactionSplit> splits = tr.attributes.transactions;
        for (final TransactionSplit split in splits) {
          // Verificamos si representa una compra/depósito en la cuenta de inversión
          final double amount = (double.tryParse(split.amount) ?? 0.0).abs();
          if (amount <= 0.0) continue;

          final String description = split.description;
          final String notes = split.notes ?? '';
          final String combinedText = '$description $notes';

          final String? detectedIsin = PortfolioNotesParser.extractIsin(
            combinedText,
          );
          final double? explicitShares = PortfolioNotesParser.extractShares(
            combinedText,
          );

          // Intentar asociar con un holding existente por ISIN, Ticker o Nombre
          final Holding? matchedHolding = portfolio.findHolding(
            isin: detectedIsin,
            name: description,
          );

          // Si tiene ISIN detectado o coincide con un holding existente
          final bool isRelevant =
              detectedIsin != null || matchedHolding != null;
          if (isRelevant) {
            final String journalId = split.transactionJournalId ?? txId;
            candidates.add(
              SyncCandidate(
                transactionId: txId,
                journalId: journalId,
                date: split.date,
                amount: amount,
                description: description,
                detectedIsin: detectedIsin,
                matchedHolding: matchedHolding,
                suggestedShares: explicitShares,
              ),
            );
            // No agregar múltiples veces si un split ya clasificó la transacción
            break;
          }
        }
      }
    } catch (e, stack) {
      log.warning('Error finding unprocessed purchases: $e', e, stack);
    }

    return candidates;
  }

  /// Aplica una lista de compras confirmadas al portfolio de la cuenta
  static Portfolio applyConfirmedPurchases({
    required Portfolio currentPortfolio,
    required List<
      ({
        SyncCandidate candidate,
        String isin,
        String ticker,
        String name,
        double shares,
        double amount,
        String? category,
      })
    >
    purchases,
  }) {
    final List<Holding> updatedHoldings = List<Holding>.from(
      currentPortfolio.holdings,
    );
    final Set<String> updatedTxIds = Set<String>.from(
      currentPortfolio.processedTransactionIds,
    );

    for (final ({
          double amount,
          SyncCandidate candidate,
          String? category,
          String isin,
          String name,
          double shares,
          String ticker,
        })
        purchase
        in purchases) {
      final String isin = purchase.isin.trim().toUpperCase();
      final String ticker = purchase.ticker.trim().toUpperCase();
      final String name = purchase.name.trim();
      final double newShares = purchase.shares;
      final double newAmount = purchase.amount;

      final int existingIdx = updatedHoldings.indexWhere(
        (Holding h) =>
            (isin.isNotEmpty && h.isin.trim().toUpperCase() == isin) ||
            (ticker.isNotEmpty && h.ticker.trim().toUpperCase() == ticker),
      );

      if (existingIdx != -1) {
        final Holding current = updatedHoldings[existingIdx];
        final double totalShares = current.shares + newShares;
        final double totalInvested = current.investedAmount + newAmount;

        updatedHoldings[existingIdx] = current.copyWith(
          shares: totalShares,
          investedAmount: totalInvested,
        );
      } else {
        updatedHoldings.add(
          Holding(
            isin: isin,
            ticker: ticker,
            name: name.isNotEmpty ? name : (isin.isNotEmpty ? isin : ticker),
            category: purchase.category,
            shares: newShares,
            investedAmount: newAmount,
          ),
        );
      }

      updatedTxIds.add(purchase.candidate.transactionId.trim());
    }

    return currentPortfolio.copyWith(
      updatedAt: DateTime.now().toUtc(),
      processedTransactionIds: updatedTxIds.toList(),
      holdings: updatedHoldings,
    );
  }
}
