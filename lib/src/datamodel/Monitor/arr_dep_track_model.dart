class ArrDepTrackModel {
  List<VOMMAirportArrivalsAdnDepartures>? vOMMAirportArrivalsAdnDepartures;

  ArrDepTrackModel({this.vOMMAirportArrivalsAdnDepartures});

  ArrDepTrackModel.fromJson(Map<String, dynamic> json) {
    if (json['VOMM Airport Arrivals Adn Departures'] != null) {
      vOMMAirportArrivalsAdnDepartures = <VOMMAirportArrivalsAdnDepartures>[];
      json['VOMM Airport Arrivals Adn Departures'].forEach((v) {
        vOMMAirportArrivalsAdnDepartures!
            .add(new VOMMAirportArrivalsAdnDepartures.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.vOMMAirportArrivalsAdnDepartures != null) {
      data['VOMM Airport Arrivals Adn Departures'] = this
          .vOMMAirportArrivalsAdnDepartures!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class VOMMAirportArrivalsAdnDepartures {
  String? month;
  String? s1year;
  String? s2year;
  String? s3year;

  VOMMAirportArrivalsAdnDepartures(
      {this.month, this.s1year, this.s2year, this.s3year});

  VOMMAirportArrivalsAdnDepartures.fromJson(Map<String, dynamic> json) {
    month = json['month'];
    s1year = json['1year'];
    s2year = json['2year'];
    s3year = json['3year'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['month'] = this.month;
    data['1year'] = this.s1year;
    data['2year'] = this.s2year;
    data['3year'] = this.s3year;
    return data;
  }
}
