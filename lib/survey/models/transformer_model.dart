import 'base_survey_model.dart';

class TransformerSurveyModel extends BaseSurveyModel {
  final String? transformerNo;
  final String? transCapacity;

  TransformerSurveyModel({
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
    this.transformerNo,
    this.transCapacity,
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
      'transformerNo': transformerNo,
      'transCapacity': transCapacity
    };
  }

  factory TransformerSurveyModel.fromMap(Map<dynamic, dynamic> map) {
    return TransformerSurveyModel(
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
      transformerNo: map['transformerNo'],
      transCapacity: map['transCapacity'],
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
