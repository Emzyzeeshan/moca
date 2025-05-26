class GroupsModel {
  int? slno;
  String? groupHeading;
  String? apiUrl;
  String? collapseStatus;

  GroupsModel({this.slno, this.groupHeading, this.apiUrl, this.collapseStatus});

  GroupsModel.fromJson(Map<String, dynamic> json) {
    slno = json['slno'];
    groupHeading = json['groupHeading'];
    apiUrl = json['apiUrl'];
    collapseStatus = json['collapseStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['slno'] = this.slno;
    data['groupHeading'] = this.groupHeading;
    data['apiUrl'] = this.apiUrl;
    data['collapseStatus'] = this.collapseStatus;
    return data;
  }
}
