class Building {
  final int? id;
  final int? stationId;
  final String name;
  final double buyPrice;
  final double additionalRent;
  final bool isPurchased;

  const Building({
    this.id,
    this.stationId,
    required this.name,
    this.buyPrice = 0.0,
    this.additionalRent = 0.0,
    this.isPurchased = false,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as int?,
      stationId: json['stationId'] as int?,
      name: json['name'] as String,
      buyPrice: (json['buyPrice'] as num).toDouble(),
      additionalRent: (json['additionalRent'] as num).toDouble(),
      isPurchased: json['isPurchased'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'stationId': stationId,
    'name': name,
    'buyPrice': buyPrice,
    'additionalRent': additionalRent,
    'isPurchased': isPurchased,
  };

  Building copyWith({
    int? id,
    int? stationId,
    String? name,
    double? buyPrice,
    double? additionalRent,
    bool? isPurchased,
  }) {
    return Building(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      name: name ?? this.name,
      buyPrice: buyPrice ?? this.buyPrice,
      additionalRent: additionalRent ?? this.additionalRent,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
