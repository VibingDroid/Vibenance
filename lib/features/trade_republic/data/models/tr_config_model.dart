class TrConfigModel {
  const TrConfigModel({
    this.isEnabled = false,
    this.bridgeUrl = '',
    this.bridgeApiKey = '',
    this.fireflyAssetAccountId,
  });

  final bool isEnabled;
  final String bridgeUrl;
  final String bridgeApiKey;
  final String? fireflyAssetAccountId;

  TrConfigModel copyWith({
    bool? isEnabled,
    String? bridgeUrl,
    String? bridgeApiKey,
    String? fireflyAssetAccountId,
  }) {
    return TrConfigModel(
      isEnabled: isEnabled ?? this.isEnabled,
      bridgeUrl: bridgeUrl ?? this.bridgeUrl,
      bridgeApiKey: bridgeApiKey ?? this.bridgeApiKey,
      fireflyAssetAccountId: fireflyAssetAccountId ?? this.fireflyAssetAccountId,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'bridgeUrl': bridgeUrl,
      'fireflyAssetAccountId': fireflyAssetAccountId,
    };
  }

  factory TrConfigModel.fromJson(Map<String, dynamic> json, {String bridgeApiKey = ''}) {
    return TrConfigModel(
      isEnabled: json['isEnabled'] as bool? ?? false,
      bridgeUrl: json['bridgeUrl'] as String? ?? '',
      bridgeApiKey: bridgeApiKey,
      fireflyAssetAccountId: json['fireflyAssetAccountId'] as String?,
    );
  }
}
