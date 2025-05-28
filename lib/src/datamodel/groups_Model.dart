class GroupsModel {
  int? slno;
  String? groupHeading;
  String? apiUrl;
  String? collapseStatus;
  String? graphApplicable;
  String? materType;
  String? lastUpdatedDate;

  GroupsModel(
      {this.slno,
        this.groupHeading,
        this.apiUrl,
        this.collapseStatus,
        this.graphApplicable,
        this.materType,
        this.lastUpdatedDate});

  GroupsModel.fromJson(Map<String, dynamic> json) {
    slno = json['Slno'];
    groupHeading = json['GroupHeading'];
    apiUrl = json['ApiUrl'];
    collapseStatus = json['CollapseStatus'];
    graphApplicable = json['GraphApplicable'];
    materType = json['MaterType'];
    lastUpdatedDate = json['LastUpdatedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Slno'] = this.slno;
    data['GroupHeading'] = this.groupHeading;
    data['ApiUrl'] = this.apiUrl;
    data['CollapseStatus'] = this.collapseStatus;
    data['GraphApplicable'] = this.graphApplicable;
    data['MaterType'] = this.materType;
    data['LastUpdatedDate'] = this.lastUpdatedDate;
    return data;
  }
}
