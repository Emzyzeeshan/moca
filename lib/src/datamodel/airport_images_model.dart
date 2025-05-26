class AllAirportsImagesModel {
  List<dynamic>? imagePath;

  AllAirportsImagesModel({this.imagePath});

  AllAirportsImagesModel.fromJson(Map<String, dynamic> json) {
    imagePath = json['imagePath'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['imagePath'] = this.imagePath;
    return data;
  }
}
