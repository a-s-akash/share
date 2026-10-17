import 'base_survey_model.dart';

class SpSurveyModel extends BaseSurveyModel {
  final String? spNo;
  final String? spType;
  final String? rrNo;
  final String? spTransformerNo;
  final String? spId;
  final String? spMeter;
  final String? spconnectedLoad;
  final String? spMeterNo;
  final String? spMeterType;
  final String? spMeterMake;
  final String? spMeterPhase;
  final String? spCondition;
  final String? spEarthingCondition;
  final bool? earthingAvailable;
  final String? earthingReason;

  SpSurveyModel({
    String? roadType,
    String? trafficDensity,
    String? trafficSpeed,
    String? assetType,
    double? latitude,
    double? longitude,
    double? altitude,
    String? accuracy,
    String? landmark,
    String? uuidFileName1,
    String? uuidFileName2,
    String? uuidFileName3,
    String? installedOn,
    String? installedBy,
    String? region,
    String? zone,
    String? ward,
    String? wardId,
    String? customerId,
    String? manualEnteredLocation,
    String? roadCategory,
    String? roadWidth,
    String? vehicleAccess,
    String? comments,
    String? carrierName,
    int? signalStrengthLevel,
    bool isUploaded = false,
    this.spNo,
    this.spType,
    this.rrNo,
    this.spTransformerNo,
    this.spId,
    this.spMeter,
    this.spconnectedLoad,
    this.spMeterNo,
    this.spMeterType,
    this.spMeterMake,
    this.spMeterPhase,
    this.spCondition,
    this.spEarthingCondition,
    this.earthingAvailable,
    this.earthingReason,
  }) : super(
          roadType: roadType,
          trafficDensity: trafficDensity,
          trafficSpeed: trafficSpeed,
          assetType: assetType,
          latitude: latitude,
          longitude: longitude,
          landmark: landmark,
          accuracy: accuracy,
          altitude: altitude,
          uuidFileName1: uuidFileName1,
          uuidFileName2: uuidFileName2,
          uuidFileName3: uuidFileName3,
          installedOn: installedOn,
          installedBy: installedBy,
          region: region,
          zone: zone,
          ward: ward,
          wardId: wardId,
          customerId: customerId,
          manualEnteredLocation: manualEnteredLocation,
          roadCategory: roadCategory,
          roadWidth: roadWidth,
          vehicleAccess: vehicleAccess,
          comments: comments,
          carrierName: carrierName,
          signalStrengthLevel: signalStrengthLevel,
          isUploaded: isUploaded,
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      ...baseToMap(),
      'spNo': spNo,
      'spType': spType,
      'rrNo': rrNo,
      'spTransformerNo': spTransformerNo,
      'spId': spId,
      'spMeter': spMeter,
      "spconnectedLoad": spconnectedLoad,
      "spMeterNo": spMeterNo,
      "spMeterType": spMeterType,
      "spMeterMake": spMeterMake,
      "spMeterPhase": spMeterPhase,
      "spCondition": spCondition,
      "spEarthingCondition": spEarthingCondition,
      "earthingAvailable": earthingAvailable,
      "earthingReason": earthingReason,
    };
  }

  factory SpSurveyModel.fromMap(Map<dynamic, dynamic> map) {
    return SpSurveyModel(
      roadType: map['roadType'],
      trafficDensity: map['trafficDensity'],
      trafficSpeed: map['trafficSpeed'],
      assetType: map['assetType'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
      accuracy: map['accuracy'],
      landmark: map['landmark'],
      uuidFileName1: map['uuidFileName1'],
      uuidFileName2: map['uuidFileName2'],
      uuidFileName3: map['uuidFileName3'],
      installedOn: map['installedOn'],
      installedBy: map['installedBy'],
      region: map['region'],
      zone: map['zone'],
      ward: map['ward'],
      wardId: map['wardId'],
      customerId: map['customerId'],
      spNo: map['spNo'],
      spType: map['spType'],
      rrNo: map['rrNo'],
      spTransformerNo: map['spTransformerNo'],
      spId: map['spId'],
      spMeter: map['spMeter'],
      spconnectedLoad: map['spconnectedLoad'],
      spMeterNo: map['spMeterNo'],
      spMeterType: map['spMeterType'],
      spMeterMake: map['spMeterMake'],
      spMeterPhase: map['spMeterPhase'],
      spCondition: map['spCondition'],
      spEarthingCondition: map['spEarthingCondition'],
      earthingAvailable: map['earthingAvailable'],
      earthingReason: map['earthingReason'],
      manualEnteredLocation: map['manualEnteredLocation'],
      roadCategory: map['roadCategory'],
      roadWidth: map['roadWidth'],
      vehicleAccess: map['vehicleAccess'],
      comments: map['comments'],
      carrierName: map['carrierName'],
      signalStrengthLevel: map['signalStrengthLevel'],
      isUploaded: map['isUploaded'] ?? false,
    );
  }
}
