import 'base_survey_model.dart';

class PoleSurveyModel extends BaseSurveyModel {
  final String? poleType;
  final String? poleHeight;
  final String? poleSpan;
  final String? poleCondition;
  final String? goodArmCount;
  final String? badArmCount;
  final String? missingArmCount;
  final String? armCount;
  final String? armLength;
  final bool? clampRequired;
  final bool? bracketRequired;
  final bool? earthingRequired;
  final bool? controlWireStatus;
  final String? manualSwitchControl;
  final String? workingCount;
  final String? notWorkingCount;
  final String? missingCount;
  final String? poleNumber;
  final String? switchPointNo;
  final String? poleTransformerNo;
  final String? exCorpPoleNo;
  final String? escomPoleNumber;
  final String? lampType;
  final String? lampWatts;
  final List<Map<String, dynamic>>? selectedLamps;
  final String? incomingTransLine;
  final String? incomingTransType;
  final String? clampType;
  final int? clampTypeLength;
  final int? clampTypeWidth;
  final String? clampTypeUnits;
  final String? bracketMountingHeight;
  final String? motorRating;
  final String? motorMake;
  final String? motorModel;
  final String? winchCondition;
  final String? ropeCondition;
  final String? motorCondition;

  PoleSurveyModel(
      {String? roadType,
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
      this.poleType,
      this.poleHeight,
      this.poleSpan,
      this.poleCondition,
      this.goodArmCount,
      this.badArmCount,
      this.missingArmCount,
      this.armCount,
      this.armLength,
      this.clampRequired,
      this.bracketRequired,
      this.earthingRequired,
      this.controlWireStatus,
      this.manualSwitchControl,
      this.workingCount,
      this.notWorkingCount,
      this.missingCount,
      this.poleNumber,
      this.switchPointNo,
      this.poleTransformerNo,
      this.exCorpPoleNo,
      this.escomPoleNumber,
      this.lampType,
      this.lampWatts,
      this.selectedLamps,
      this.incomingTransLine,
      this.incomingTransType,
      this.clampType,
      this.clampTypeLength,
      this.clampTypeWidth,
      this.clampTypeUnits,
      this.bracketMountingHeight,
      this.motorRating,
      this.motorMake,
      this.motorModel,
      this.winchCondition,
      this.ropeCondition,
      this.motorCondition})
      : super(
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
      "poleType": poleType,
      "poleHeight": poleHeight,
      "poleSpan": poleSpan,
      "poleCondition": poleCondition,
      "goodArmCount": goodArmCount,
      "badArmCount": badArmCount,
      "missingArmCount": missingArmCount,
      "armCount": armCount,
      "armLength": armLength,
      "clampRequired": clampRequired,
      "bracketRequired": bracketRequired,
      "earthingRequired": earthingRequired,
      "controlWireStatus": controlWireStatus,
      "manualSwitchControl": manualSwitchControl,
      "workingCount": workingCount,
      "notWorkingCount": notWorkingCount,
      "missingCount": missingCount,
      "poleNumber": poleNumber,
      "switchPointNo": switchPointNo,
      "poleTransformerNo": poleTransformerNo,
      "exCorpPoleNo": exCorpPoleNo,
      "escomPoleNumber": escomPoleNumber,
      "lampType": lampType,
      "lampWatts": lampWatts,
      "selectedLamps": selectedLamps,
      'incomingTransLine': incomingTransLine,
      'incomingTransType': incomingTransType,
      'clampType': clampType,
      'clampTypeLength': clampTypeLength,
      'clampTypeWidth': clampTypeWidth,
      'clampTypeUnits': clampTypeUnits,
      'bracketMountingHeight': bracketMountingHeight,
      'motorRating': motorRating,
      'motorModel': motorModel,
      'motorMake': motorMake,
      'winchCondition': winchCondition,
      'ropeCondition': ropeCondition,
      'motorCondition': motorCondition,
      // 'customBracketHeight': customBracketHeight,
    };
  }

  factory PoleSurveyModel.fromMap(Map<dynamic, dynamic> map) {
    return PoleSurveyModel(
      roadType: map['roadType'],
      trafficDensity: map['trafficDensity'],
      trafficSpeed: map['trafficSpeed'],
      assetType: map['assetType'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      landmark: map['landmark'],
      poleType: map['poleType'],
      poleHeight: map['poleHeight'],
      poleSpan: map['poleSpan'],
      poleCondition: map['poleCondition'],
      goodArmCount: map['goodArmCount'],
      badArmCount: map['badArmCount'],
      missingArmCount: map['missingArmCount'],
      armCount: map['armCount'],
      armLength: map['armLength'],
      clampRequired: map['clampRequired'],
      bracketRequired: map['bracketRequired'],
      earthingRequired: map['earthingRequired'],
      controlWireStatus: map['controlWireStatus'],
      manualSwitchControl: map['manualSwitchControl'],
      workingCount: map['workingCount'],
      notWorkingCount: map['notWorkingCount'],
      missingCount: map['missingCount'],
      poleNumber: map['poleNumber'],
      switchPointNo: map['switchPointNo'],
      poleTransformerNo: map['poleTransformerNo'],
      exCorpPoleNo: map['exCorpPoleNo'],
      escomPoleNumber: map['escomPoleNumber'],
      lampType: map['lampType'],
      lampWatts: map['lampWatts'],
      selectedLamps: map['selectedLamps'],
      // != null
      //     ? List<Map<String, String>>.from(
      //         map['selectedLamps'].map((x) => Map<String, String>.from(x)))
      //     : null,
      uuidFileName1: map['uuidFileName1'],
      uuidFileName2: map['uuidFileName2'],
      uuidFileName3: map['uuidFileName3'],
      installedOn: map['installedOn'],
      installedBy: map['installedBy'],
      region: map['region'],
      zone: map['zone'],
      ward: map['ward'],
      isUploaded: map['isUploaded'] ?? false,
      wardId: map['wardId'],
      customerId: map['customerId'],
      accuracy: map['accuracy'],
      altitude: map['altitude'],
      manualEnteredLocation: map['manualEnteredLocation'],
      roadCategory: map['roadCategory'],
      roadWidth: map['roadWidth'],
      vehicleAccess: map['vehicleAccess'],
      incomingTransLine: map['incomingTransLine'],
      incomingTransType: map['incomingTransType'],
      clampType: map['clampType'],
      clampTypeLength: map['clampTypeLength'],
      clampTypeWidth: map['clampTypeWidth'],
      clampTypeUnits: map['clampTypeUnits'],
      bracketMountingHeight: map['bracketMountingHeight'],
      carrierName: map['carrierName'],
      signalStrengthLevel: map['signalStrengthLevel'],
      comments: map['comments'],
      motorRating: map['motorRating'],
      motorMake: map['motorMake'],
      motorModel: map['motorModel'],
      winchCondition: map['winchCondition'],
      ropeCondition: map['ropeCondition'],
      motorCondition: map['motorCondition'],
    );
  }
}
