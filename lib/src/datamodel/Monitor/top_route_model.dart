class TopRouteModel {
  List<TopRoutes>? topRoutes;

  TopRouteModel({this.topRoutes});

  TopRouteModel.fromJson(Map<String, dynamic> json) {
    if (json['Top Routes'] != null) {
      topRoutes = <TopRoutes>[];
      json['Top Routes'].forEach((v) {
        topRoutes!.add(new TopRoutes.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.topRoutes != null) {
      data['Top Routes'] = this.topRoutes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TopRoutes {
  String? lOCATION;
  String? lOCATIONTYPE;
  String? cOUNT;
  String? locationImgUrl;

  TopRoutes(
      {this.lOCATION, this.lOCATIONTYPE, this.cOUNT, this.locationImgUrl});

  TopRoutes.fromJson(Map<String, dynamic> json) {
    lOCATION = json['LOCATION'];
    lOCATIONTYPE = json['LOCATION_TYPE'];
    cOUNT = json['COUNT'];
    locationImgUrl = json['locationImgUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['LOCATION'] = this.lOCATION;
    data['LOCATION_TYPE'] = this.lOCATIONTYPE;
    data['COUNT'] = this.cOUNT;
    data['locationImgUrl'] = this.locationImgUrl;
    return data;
  }
}
