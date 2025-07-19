class TopAirlinesModel {
  List<TopAirlines>? topAirlines;

  TopAirlinesModel({this.topAirlines});

  TopAirlinesModel.fromJson(Map<String, dynamic> json) {
    if (json['Top Airlines'] != null) {
      topAirlines = <TopAirlines>[];
      json['Top Airlines'].forEach((v) {
        topAirlines!.add(new TopAirlines.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.topAirlines != null) {
      data['Top Airlines'] = this.topAirlines!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopAirlines {
  String? airlineImgUrl;
  String? oPERATOR;
  String? sAPCODE;
  String? cOUNT;

  TopAirlines({this.airlineImgUrl, this.oPERATOR, this.sAPCODE, this.cOUNT});

  TopAirlines.fromJson(Map<String, dynamic> json) {
    airlineImgUrl = json['airlineImgUrl'];
    oPERATOR = json['OPERATOR'];
    sAPCODE = json['SAPCODE'];
    cOUNT = json['COUNT'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airlineImgUrl'] = this.airlineImgUrl;
    data['OPERATOR'] = this.oPERATOR;
    data['SAPCODE'] = this.sAPCODE;
    data['COUNT'] = this.cOUNT;
    return data;
  }
}
