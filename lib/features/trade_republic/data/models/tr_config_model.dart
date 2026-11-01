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
      'is_enabled': isEnabled,
      'isEnabled': isEnabled,
      'bridge_url': bridgeUrl,
      'bridgeUrl': bridgeUrl,
      'firefly_asset_account_id': fireflyAssetAccountId,
      'fireflyAssetAccountId': fireflyAssetAccountId,
    };
  }

  factory TrConfigModel.fromJson(Map<String, dynamic> json, {String bridgeApiKey = ''}) {
    return TrConfigModel(
      isEnabled: (json['isEnabled'] ?? json['is_enabled']) as bool? ?? false,
      bridgeUrl: (json['bridgeUrl'] ?? json['bridge_url']) as String? ?? '',
      bridgeApiKey: bridgeApiKey,
      fireflyAssetAccountId:
          (json['fireflyAssetAccountId'] ?? json['firefly_asset_account_id'])
              as String?,
    );
  }
}
