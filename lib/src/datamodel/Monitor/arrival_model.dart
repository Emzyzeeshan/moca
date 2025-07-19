class ArrivalModel {
  List<Arrivals>? arrivals;

  ArrivalModel({this.arrivals});

  ArrivalModel.fromJson(Map<String, dynamic> json) {
    if (json['Arrivals'] != null) {
      arrivals = <Arrivals>[];
      json['Arrivals'].forEach((v) {
        arrivals!.add(new Arrivals.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.arrivals != null) {
      data['Arrivals'] = this.arrivals!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Arrivals {
  String? airport;
  String? mTYPE;
  String? dATE;
  String? oPERATORCD;
  String? rEGNO;
  String? fLIGHTNO;
  String? dEPLOCATION;
  String? lOCATIONTYPE;
  String? aIRCRAFTTYPECD;
  String? nATURE;
  String? aRRGCD;
  String? rOUTECD;
  String? sTA;
  String? iSTATA;
  String? dTIME;

  Arrivals(
      {this.airport,
        this.mTYPE,
        this.dATE,
        this.oPERATORCD,
        this.rEGNO,
        this.fLIGHTNO,
        this.dEPLOCATION,
        this.lOCATIONTYPE,
        this.aIRCRAFTTYPECD,
        this.nATURE,
        this.aRRGCD,
        this.rOUTECD,
        this.sTA,
        this.iSTATA,
        this.dTIME});

  Arrivals.fromJson(Map<String, dynamic> json) {
    airport = json['airport'];
    mTYPE = json['MTYPE'];
    dATE = json['DATE'];
    oPERATORCD = json['OPERATOR_CD'];
    rEGNO = json['REG_NO'];
    fLIGHTNO = json['FLIGHT_NO'];
    dEPLOCATION = json['DEP_LOCATION'];
    lOCATIONTYPE = json['LOCATION_TYPE'];
    aIRCRAFTTYPECD = json['AIRCRAFTTYPE_CD'];
    nATURE = json['NATURE'];
    aRRGCD = json['ARR_GCD'];
    rOUTECD = json['ROUTE_CD'];
    sTA = json['STA'];
    iSTATA = json['IST_ATA'];
    dTIME = json['DTIME'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airport'] = this.airport;
    data['MTYPE'] = this.mTYPE;
    data['DATE'] = this.dATE;
    data['OPERATOR_CD'] = this.oPERATORCD;
    data['REG_NO'] = this.rEGNO;
    data['FLIGHT_NO'] = this.fLIGHTNO;
    data['DEP_LOCATION'] = this.dEPLOCATION;
    data['LOCATION_TYPE'] = this.lOCATIONTYPE;
    data['AIRCRAFTTYPE_CD'] = this.aIRCRAFTTYPECD;
    data['NATURE'] = this.nATURE;
    data['ARR_GCD'] = this.aRRGCD;
    data['ROUTE_CD'] = this.rOUTECD;
    data['STA'] = this.sTA;
    data['IST_ATA'] = this.iSTATA;
    data['DTIME'] = this.dTIME;
    return data;
  }
}
