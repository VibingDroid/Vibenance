import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibenance/auth.dart';
import 'package:vibenance/generated/l10n/app_localizations.dart';
import 'package:vibenance/layout.dart';
import 'package:vibenance/pages/transaction.dart';
import 'package:vibenance/theme.dart';

class NewTransactionFab extends StatelessWidget {
  const NewTransactionFab({super.key, required this.context, this.accountId});

  final BuildContext context;
  final String? accountId;

  @override
  Widget build(BuildContext context) {
    if (context.watch<LayoutProvider>().currentSize >= .expanded) {
      return FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(S.of(context).transactionTitleAdd),
            content: Container(
              constraints: BoxConstraints(
                minWidth: 280,
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              width: .maxFinite,
              child: TransactionPage(accountId: accountId),
            ),
          ),
        ),
        tooltip: S.of(context).formButtonTransactionAdd,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FtTheme.radius),
        ),
        backgroundColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FtTheme.radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: FtColors.brandGradient,
            ),
          ),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
      );
    } else {
      return OpenContainer(
        openBuilder: (BuildContext context, Function closedContainer) =>
            TransactionPage(accountId: accountId),
        openColor: Theme.of(context).cardColor,
        closedColor: Colors.transparent,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
        ),
        closedElevation: 4,
        closedBuilder: (BuildContext context, Function openContainer) {
          return GestureDetector(
            onTap: () => openContainer(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FtTheme.radius),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: FtColors.brandGradient,
                ),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
        onClosed: (bool? refresh) {
          if (refresh ?? false == true) {
            if (context.mounted) {
              context.read<FireflyService>().transStock!.clear();
            }
          }
        },
      );
    }
  }
}
