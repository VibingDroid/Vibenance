import 'package:flutter/material.dart';
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: label.isNotEmpty
          ? Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.28,
                letterSpacing: 0.5,
              ),
            )
          : Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
