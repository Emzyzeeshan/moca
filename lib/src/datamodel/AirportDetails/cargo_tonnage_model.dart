class CargoTonnageModel {
  List<FinancialData>? financialData;

  CargoTonnageModel({this.financialData});

  CargoTonnageModel.fromJson(Map<String, dynamic> json) {
    if (json['financialData'] != null) {
      financialData = <FinancialData>[];
      json['financialData'].forEach((v) {
        financialData!.add(new FinancialData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.financialData != null) {
      data['financialData'] =
          this.financialData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FinancialData {
  String? financialYear;
  int? domestic;
  int? total;
  int? international;

  FinancialData(
      {this.financialYear, this.domestic, this.total, this.international});

  FinancialData.fromJson(Map<String, dynamic> json) {
    financialYear = json['financialYear'];
    domestic = json['domestic'];
    total = json['total'];
    international = json['international'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['financialYear'] = this.financialYear;
    data['domestic'] = this.domestic;
    data['total'] = this.total;
    data['international'] = this.international;
    return data;
  }
}
