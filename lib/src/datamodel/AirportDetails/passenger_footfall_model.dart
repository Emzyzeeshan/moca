class PassengerFootFallModel {
  final List<FinancialData> financialData;

  const PassengerFootFallModel({required this.financialData});

  factory PassengerFootFallModel.fromJson(Map<String, dynamic> json) {
    return PassengerFootFallModel(
      financialData: (json['financialData'] as List<dynamic>? ?? [])
          .map((e) => FinancialData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialData': financialData.map((v) => v.toJson()).toList(),
    };
  }
}

class FinancialData {
  final String financialYear;
  final int domestic;
  final int international;
  final int total;

  const FinancialData({
    required this.financialYear,
    required this.domestic,
    required this.international,
    required this.total,
  });

  factory FinancialData.fromJson(Map<String, dynamic> json) {
    return FinancialData(
      financialYear: json['financialYear'] as String? ?? '',
      domestic: json['domestic'] as int? ?? 0,
      international: json['international'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'financialYear': financialYear,
      'domestic': domestic,
      'international': international,
      'total': total,
    };
  }
}
