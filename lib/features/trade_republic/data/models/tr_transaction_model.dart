class TrTransactionModel {
  const TrTransactionModel({
    required this.id,
    required this.timestamp,
    required this.title,
    this.subtitle,
    required this.amount,
    this.currency = 'EUR',
    required this.eventType,
    this.status,
    this.isin,
  });

  final String id;
  final DateTime timestamp;
  final String title;
  final String? subtitle;
  final double amount;
  final String currency;
  final String eventType;
  final String? status;
  final String? isin;

  factory TrTransactionModel.fromJson(Map<String, dynamic> json) {
    return TrTransactionModel(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
      eventType: json['event_type'] as String? ?? 'UNKNOWN',
      status: json['status'] as String?,
      isin: json['isin'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'currency': currency,
      'event_type': eventType,
      'status': status,
      'isin': isin,
    };
  }
}
