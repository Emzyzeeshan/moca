class greenInitiativeModel {
  SewageTreatmentPlantDetails? sewageTreatmentPlantDetails;
  DetailsOfEnergyProcurementAndConsumption?
  detailsOfEnergyProcurementAndConsumption;
  StatusOfAchieveingNetZero? statusOfAchieveingNetZero;
  InstallationOfLEDLightsDetails? installationOfLEDLightsDetails;
  StatusOfAchieveingCarbonNeutrality? statusOfAchieveingCarbonNeutrality;
  NetMetering? netMetering;

  greenInitiativeModel(
      {this.sewageTreatmentPlantDetails,
        this.detailsOfEnergyProcurementAndConsumption,
        this.statusOfAchieveingNetZero,
        this.installationOfLEDLightsDetails,
        this.statusOfAchieveingCarbonNeutrality,
        this.netMetering});

  greenInitiativeModel.fromJson(Map<String, dynamic> json) {
    sewageTreatmentPlantDetails = json['Sewage Treatment Plant Details'] != null
        ? new SewageTreatmentPlantDetails.fromJson(
        json['Sewage Treatment Plant Details'])
        : null;
    detailsOfEnergyProcurementAndConsumption =
    json['Details of Energy procurement and consumption'] != null
        ? new DetailsOfEnergyProcurementAndConsumption.fromJson(
        json['Details of Energy procurement and consumption'])
        : null;
    statusOfAchieveingNetZero = json['Status of achieveing Net Zero'] != null
        ? new StatusOfAchieveingNetZero.fromJson(
        json['Status of achieveing Net Zero'])
        : null;
    installationOfLEDLightsDetails =
    json['Installation of LED lights details'] != null
        ? new InstallationOfLEDLightsDetails.fromJson(
        json['Installation of LED lights details'])
        : null;
    statusOfAchieveingCarbonNeutrality =
    json['Status of achieveing Carbon Neutrality'] != null
        ? new StatusOfAchieveingCarbonNeutrality.fromJson(
        json['Status of achieveing Carbon Neutrality'])
        : null;
    netMetering = json['Net Metering'] != null
        ? new NetMetering.fromJson(json['Net Metering'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.sewageTreatmentPlantDetails != null) {
      data['Sewage Treatment Plant Details'] =
          this.sewageTreatmentPlantDetails!.toJson();
    }
    if (this.detailsOfEnergyProcurementAndConsumption != null) {
      data['Details of Energy procurement and consumption'] =
          this.detailsOfEnergyProcurementAndConsumption!.toJson();
    }
    if (this.statusOfAchieveingNetZero != null) {
      data['Status of achieveing Net Zero'] =
          this.statusOfAchieveingNetZero!.toJson();
    }
    if (this.installationOfLEDLightsDetails != null) {
      data['Installation of LED lights details'] =
          this.installationOfLEDLightsDetails!.toJson();
    }
    if (this.statusOfAchieveingCarbonNeutrality != null) {
      data['Status of achieveing Carbon Neutrality'] =
          this.statusOfAchieveingCarbonNeutrality!.toJson();
    }
    if (this.netMetering != null) {
      data['Net Metering'] = this.netMetering!.toJson();
    }
    return data;
  }
}

class SewageTreatmentPlantDetails {
  String? sewageTreatmentCapacity;
  String? targetDate;
  String? stpInstallation;

  SewageTreatmentPlantDetails(
      {this.sewageTreatmentCapacity, this.targetDate, this.stpInstallation});

  SewageTreatmentPlantDetails.fromJson(Map<String, dynamic> json) {
    sewageTreatmentCapacity = json['SewageTreatmentCapacity'];
    targetDate = json['TargetDate'];
    stpInstallation = json['StpInstallation'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SewageTreatmentCapacity'] = this.sewageTreatmentCapacity;
    data['TargetDate'] = this.targetDate;
    data['StpInstallation'] = this.stpInstallation;
    return data;
  }
}

class DetailsOfEnergyProcurementAndConsumption {
  String? conventionalSource;
  String? ofEnergyConsumptionFromRenewableSource;
  String? offSiteCapacity;
  String? perUnitCost;
  String? avgPerUnitCost;
  String? totalEnergy;
  String? totalCapacity;
  String? consumptionFrom;
  String? nonrenewableSourcePer;
  String? onSiteCapacity;
  String? perUnitCostCV;

  DetailsOfEnergyProcurementAndConsumption(
      {this.conventionalSource,
        this.ofEnergyConsumptionFromRenewableSource,
        this.offSiteCapacity,
        this.perUnitCost,
        this.avgPerUnitCost,
        this.totalEnergy,
        this.totalCapacity,
        this.consumptionFrom,
        this.nonrenewableSourcePer,
        this.onSiteCapacity,
        this.perUnitCostCV});

  DetailsOfEnergyProcurementAndConsumption.fromJson(Map<String, dynamic> json) {
    conventionalSource = json['ConventionalSource'];
    ofEnergyConsumptionFromRenewableSource =
    json['% of energy consumption from renewable source'];
    offSiteCapacity = json['OffSiteCapacity'];
    perUnitCost = json['PerUnitCost'];
    avgPerUnitCost = json['AvgPerUnitCost'];
    totalEnergy = json['TotalEnergy'];
    totalCapacity = json['TotalCapacity'];
    consumptionFrom = json['ConsumptionFrom'];
    nonrenewableSourcePer = json['NonrenewableSourcePer'];
    onSiteCapacity = json['OnSiteCapacity'];
    perUnitCostCV = json['PerUnitCostCV'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ConventionalSource'] = this.conventionalSource;
    data['% of energy consumption from renewable source'] =
        this.ofEnergyConsumptionFromRenewableSource;
    data['OffSiteCapacity'] = this.offSiteCapacity;
    data['PerUnitCost'] = this.perUnitCost;
    data['AvgPerUnitCost'] = this.avgPerUnitCost;
    data['TotalEnergy'] = this.totalEnergy;
    data['TotalCapacity'] = this.totalCapacity;
    data['ConsumptionFrom'] = this.consumptionFrom;
    data['NonrenewableSourcePer'] = this.nonrenewableSourcePer;
    data['OnSiteCapacity'] = this.onSiteCapacity;
    data['PerUnitCostCV'] = this.perUnitCostCV;
    return data;
  }
}

class StatusOfAchieveingNetZero {
  String? targetDate;
  String? netZeroAchievingSteps;
  String? pertChart;
  String? remarks;
  String? netZeroStatus;

  StatusOfAchieveingNetZero(
      {this.targetDate,
        this.netZeroAchievingSteps,
        this.pertChart,
        this.remarks,
        this.netZeroStatus});

  StatusOfAchieveingNetZero.fromJson(Map<String, dynamic> json) {
    targetDate = json['TargetDate'];
    netZeroAchievingSteps = json['NetZeroAchievingSteps'];
    pertChart = json['PertChart'];
    remarks = json['Remarks'];
    netZeroStatus = json['NetZeroStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['TargetDate'] = this.targetDate;
    data['NetZeroAchievingSteps'] = this.netZeroAchievingSteps;
    data['PertChart'] = this.pertChart;
    data['Remarks'] = this.remarks;
    data['NetZeroStatus'] = this.netZeroStatus;
    return data;
  }
}

class InstallationOfLEDLightsDetails {
  String? ledLight;
  String? nonLedLight;

  InstallationOfLEDLightsDetails({this.ledLight, this.nonLedLight});

  InstallationOfLEDLightsDetails.fromJson(Map<String, dynamic> json) {
    ledLight = json['LedLight'];
    nonLedLight = json['NonLedLight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['LedLight'] = this.ledLight;
    data['NonLedLight'] = this.nonLedLight;
    return data;
  }
}

class StatusOfAchieveingCarbonNeutrality {
  String? sanctionCapacity;
  String? targetDate;
  String? pertChart;
  String? remarks;
  String? netMeterStatus;

  StatusOfAchieveingCarbonNeutrality(
      {this.sanctionCapacity,
        this.targetDate,
        this.pertChart,
        this.remarks,
        this.netMeterStatus});

  StatusOfAchieveingCarbonNeutrality.fromJson(Map<String, dynamic> json) {
    sanctionCapacity = json['SanctionCapacity'];
    targetDate = json['TargetDate'];
    pertChart = json['PertChart'];
    remarks = json['Remarks'];
    netMeterStatus = json['NetMeterStatus'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SanctionCapacity'] = this.sanctionCapacity;
    data['TargetDate'] = this.targetDate;
    data['PertChart'] = this.pertChart;
    data['Remarks'] = this.remarks;
    data['NetMeterStatus'] = this.netMeterStatus;
    return data;
  }
}

class NetMetering {
  String? sanctionCapacity;
  String? netMeterStatus;
  String? allowedUpto;

  NetMetering({this.sanctionCapacity, this.netMeterStatus, this.allowedUpto});

  NetMetering.fromJson(Map<String, dynamic> json) {
    sanctionCapacity = json['SanctionCapacity'];
    netMeterStatus = json['NetMeterStatus'];
    allowedUpto = json['AllowedUpto'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['SanctionCapacity'] = this.sanctionCapacity;
    data['NetMeterStatus'] = this.netMeterStatus;
    data['AllowedUpto'] = this.allowedUpto;
    return data;
  }
}
