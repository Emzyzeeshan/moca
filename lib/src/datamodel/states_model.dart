class AllStatesModel {
  String? statecode;
  String? statename;

  AllStatesModel({this.statecode, this.statename});

  AllStatesModel.fromJson(Map<String, dynamic> json) {
    statecode = json['statecode'];
    statename = json['statename'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['statecode'] = this.statecode;
    data['statename'] = this.statename;
    return data;
  }
}
