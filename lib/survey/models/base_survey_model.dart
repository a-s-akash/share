abstract class BaseSurveyModel {
  final String? roadType;
  final String? trafficDensity;
  final String? trafficSpeed;
  final String? assetType;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final String? accuracy;
  final String? landmark;
  final String? uuidFileName1;
  final String? uuidFileName2;
  final String? uuidFileName3;
  final String? installedOn;
  final String? installedBy;
  final String? region;
  final String? zone;
  final String? ward;
  final String? wardId;
  final String? customerId;
  final String? manualEnteredLocation;
  final String? roadCategory;
  final String? roadWidth;
  final String? vehicleAccess;
  final String? comments;
  final String? carrierName;
  final int? signalStrengthLevel;

  bool isUploaded;

  BaseSurveyModel({
    this.roadType,
    this.trafficDensity,
    this.trafficSpeed,
    this.assetType,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.landmark,
    this.uuidFileName1,
    this.uuidFileName2,
    this.uuidFileName3,
    this.installedOn,
    this.installedBy,
    this.region,
    this.zone,
    this.ward,
    this.wardId,
    this.customerId,
    this.manualEnteredLocation,
    this.roadCategory,
    this.roadWidth,
    this.vehicleAccess,
    this.comments,
    this.carrierName,
    this.signalStrengthLevel,
    this.isUploaded = false,
  });

  Map<String, dynamic> baseToMap() {
    return {
      'roadType': roadType,
      'trafficDensity': trafficDensity,
      'trafficSpeed': trafficSpeed,
      'assetType': assetType,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'landmark': landmark,
      'uuidFileName1': uuidFileName1,
      'uuidFileName2': uuidFileName2,
      'uuidFileName3': uuidFileName3,
      'installedOn': installedOn,
      'installedBy': installedBy,
      'region': region,
      'zone': zone,
      'ward': ward,
      'wardId': wardId,
      'customerId': customerId,
      'roadCategory': roadCategory,
      'roadWidth': roadWidth,
      'manualEnteredLocation': manualEnteredLocation,
      'vehicleAccess': vehicleAccess,
      "comments": comments,
      "carrierName": carrierName,
      "signalStrengthLevel": signalStrengthLevel,
      'isUploaded': isUploaded,
    };
  }

  Map<String, dynamic> toMap();
}
