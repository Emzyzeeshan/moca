class peak_period_model {
  String? peakMonthOfYear;
  String? peakHoursOfDay;

  peak_period_model({this.peakMonthOfYear, this.peakHoursOfDay});

  peak_period_model.fromJson(Map<String, dynamic> json) {
    peakMonthOfYear = json['Peak Month of Year'];
    peakHoursOfDay = json['Peak Hours of Day'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Peak Month of Year'] = this.peakMonthOfYear;
    data['Peak Hours of Day'] = this.peakHoursOfDay;
    return data;
  }
}
