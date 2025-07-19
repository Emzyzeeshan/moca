class IndexDataModel {
  List<IndexData>? indexData;

  IndexDataModel({this.indexData});

  IndexDataModel.fromJson(Map<String, dynamic> json) {
    if (json['Index Data'] != null) {
      indexData = <IndexData>[];
      json['Index Data'].forEach((v) {
        indexData!.add(new IndexData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.indexData != null) {
      data['Index Data'] = this.indexData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class IndexData {
  String? aRRDELAYDATA;
  String? dEPDELAYDATA;
  String? cURRENTTIME;

  IndexData({this.aRRDELAYDATA, this.dEPDELAYDATA, this.cURRENTTIME});

  IndexData.fromJson(Map<String, dynamic> json) {
    aRRDELAYDATA = json['ARRDELAY_DATA'];
    dEPDELAYDATA = json['DEPDELAY_DATA'];
    cURRENTTIME = json['CURRENT_TIME'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ARRDELAY_DATA'] = this.aRRDELAYDATA;
    data['DEPDELAY_DATA'] = this.dEPDELAYDATA;
    data['CURRENT_TIME'] = this.cURRENTTIME;
    return data;
  }
}
