import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibenance/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:vibenance/utils/bank_detector.dart';

class BankLogoBadge extends StatelessWidget {
  final String accountName;
  final String? iban;
  final ShortAccountTypeProperty? type;
  final double size;

  const BankLogoBadge({
    super.key,
    required this.accountName,
    this.iban,
    this.type,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final BankInfo? bank = detectBank(accountName, iban);

    Color bgColor = bank?.color ?? const Color(0xFF1E2C45);
    final String label = bank?.shortLabel ?? '';
    final String? assetPath = bank?.assetPath;
    IconData? icon;

    if (label.isEmpty) {
      if (type == ShortAccountTypeProperty.liability ||
          type == ShortAccountTypeProperty.liabilities) {
        bgColor = const Color(0xFF4A154B);
        icon = Icons.credit_card_outlined;
      } else if (type == ShortAccountTypeProperty.cash) {
        bgColor = const Color(0xFF1B5E20);
        icon = Icons.account_balance_wallet_outlined;
      } else if (type == ShortAccountTypeProperty.expense) {
        bgColor = const Color(0xFFB71C1C);
        icon = Icons.shopping_bag_outlined;
      } else if (type == ShortAccountTypeProperty.revenue) {
        bgColor = const Color(0xFF0D47A1);
        icon = Icons.arrow_downward_outlined;
      } else {
        bgColor = const Color(0xFF1E2C45);
        icon = Icons.account_balance_outlined;
      }
    }

    Widget content;
    if (assetPath != null) {
      content = Semantics(
        label: label,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Opacity(opacity: 0.0, child: Text(label)),
            Padding(
              padding: EdgeInsets.all(size * 0.18),
              child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
            ),
          ],
        ),
      );
    } else if (label.isNotEmpty) {
      content = Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.28,
          letterSpacing: 0.5,
        ),
      );
    } else {
      content = Icon(icon, color: Colors.white, size: size * 0.5);
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isVeryDark = bgColor.computeLuminance() < 0.05;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: isDark && isVeryDark
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              )
            : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (isDark && isVeryDark)
                ? Colors.black.withValues(alpha: 0.5)
                : bgColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
