class MenuItemModel {
  final String featureKey;
  final String label;
  final String icon;

  MenuItemModel({
    required this.featureKey,
    required this.label,
    required this.icon,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
        featureKey: json['feature_key'] as String? ??
            json['route_or_feature_key'] as String? ?? '',
        label: json['label'] as String,
        icon: json['icon'] as String? ?? 'home',
      );
}
