import 'dart:developer';

import 'package:hive/hive.dart';

const componenetsChanged = {
  "CCMS": [
    "Components Changed",
    "SMPS",
    "Gateway",
    "Meter Cable",
    "Wire",
    "Meter",
    "Timer",
    "MCB",
    "MCB Resetter",
    "Bypass switch",
    "Load Break switch",
    "Connector",
    "Door Switch",
    "SIM",
    "Antenna"
  ],
  "SLC": [
    "Components Changed",
    "SMPS",
    "Gateway",
    "Meter Cable",
    "Wire",
    "Meter",
    "Timer",
    "MCB",
    "MCB Resetter",
    "Bypass switch",
    "Load Break switch",
    "Connector",
    "Door Switch",
    "SIM",
    "Antenna"
  ],
  "SMSLC": [
    "Components Changed",
    "SMPS",
    "Gateway",
    "Meter Cable",
    "Wire",
    "Meter",
    "Timer",
    "MCB",
    "MCB Resetter",
    "Bypass switch",
    "Load Break switch",
    "Connector",
    "Door Switch",
    "SIM",
    "Antenna"
  ],
  "LAMP": ["Components Changed", "Wire", "Lamp", "SPD"],
  "GW": ["Components Changed", "Gateway", "SIM", "Antenna", "Wire"],
  "SEMC": ["Components Changed", "Gateway", "SIM", "Antenna", "Wire"],
  "ILM": ["Components Changed", "ILM", "Wire"],
  "ILM-4G": ["Components Changed", "ILM-4G", "Wire"],
  "LIGHTPOINT": ["Components Changed", "ILM", "Wire", "Lamp", "SPD"],
  "POLE": ["Components Changed", "Pole"]
};

const issuesIdentified = {
  "CCMS": [
    "Issues Identified",
    "SMPS",
    "Gateway",
    "Meter",
    "Wire",
    "Energy Meter",
    "AC Timer",
    "MCB",
    "MCB Resetter",
    "3-Way switch",
    "Load break switch",
    "Connector",
    "Door Magnet",
    "SIM",
    "Antenna",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "Device Reset",
    "Cable Damaged",
    "No Issue",
    "I dont know",
    "Input Fuse ",
    "SPD",
    "Line filter",
    "Contactor"
  ],
  "SLC": [
    "Issues Identified",
    "SMPS",
    "Gateway",
    "Meter",
    "Wire",
    "Energy Meter",
    "AC Timer",
    "MCB",
    "MCB Resetter",
    "3-Way switch",
    "Load break switch",
    "Connector",
    "Door Magnet",
    "SIM",
    "Antenna",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "Device Reset",
    "Cable Damaged",
    "No Issue",
    "I dont know",
    "Input Fuse ",
    "SPD",
    "Line filter",
    "Contactor"
  ],
  "SMSLC": [
    "Issues Identified",
    "SMPS",
    "Gateway",
    "Meter",
    "Wire",
    "Energy Meter",
    "AC Timer",
    "MCB",
    "MCB Resetter",
    "3-Way switch",
    "Load break switch",
    "Connector",
    "Door Magnet",
    "SIM",
    "Antenna",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "Device Reset",
    "Cable Damaged",
    "No Issue",
    "I dont know",
    "Input Fuse ",
    "SPD",
    "Line filter",
    "Contactor"
  ],
  "LAMP": [
    "Issues Identified",
    "Wire",
    "Lamp",
    "SPD",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "Cable Damaged",
    "No Issue"
  ],
  "GW": [
    "Issues Identified",
    "Gateway",
    "SIM",
    "Antenna",
    "Wire",
    "Device Reset",
    "I dont know",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "No Issue"
  ],
  "SEMC": [
    "Issues Identified",
    "Gateway",
    "SIM",
    "Antenna",
    "Wire",
    "Device Reset",
    "I dont know",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "No Issue"
  ],
  "ILM": [
    "Issues Identified",
    "ILM",
    "Wire",
    "Device Reset",
    "I dont know",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "No Issue"
  ],
  "ILM-4G": [
    "Issues Identified",
    "ILM-4G",
    "Wire",
    "Device Reset",
    "I dont know",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "No Issue"
  ],
  "LIGHTPOINT": [
    "Issues Identified",
    "ILM",
    "Lamp",
    "Wire",
    "SPD",
    "Device Reset",
    "I dont know",
    "Input Power Issue",
    "Circuit or Jumper Fault",
    "No Issue",
  ],
  "POLE": ["Issues Identified", "Pole", "No Issue", "I dont know"]
};

/// Device/Asset Type choices for the offline Ticket Creation dropdown.
/// Values are the lowercase codes TicketProvider._deviceOrAssetType expects;
/// labels are what the field user sees.
const List<Map<String, String>> offlineDeviceTypeOptions = [
  {'value': 'others', 'label': 'Others'},
  {'value': 'ccms', 'label': 'CCMS'},
  {'value': 'smslc', 'label': 'SMSLC'},
  {'value': 'gw', 'label': 'GW'},
  {'value': 'semc', 'label': 'SEMC'},
  {'value': 'ilm', 'label': 'ILM'},
  // {'value': 'ilm-4g', 'label': 'ILM-4G'},
  {'value': 'pole', 'label': 'POLE'},
];

const Map<String, List<String>> statusTransitionMap = {
  'Open': [
    'Open',
    'Visited-Closed',
    'Visited-Not Closed',
    'Waiting-For-Support'
  ],
  'Assigned': [
    'Assigned',
    'Visited-Closed',
    'Visited-Not Closed',
    'Waiting-For-Support'
  ],
  'Closed': ['Closed'],
  'Visited-Closed': ['Visited-Closed'],
  'Visited-Not Closed': [
    'Visited-Not Closed',
    'Visited-Closed',
    'Waiting-For-Support'
  ],
  'Verified-Opened': ['Verified-Opened', 'Waiting-For-Support'],
  'Verified-Closed': ['Verified-Closed'],
  'Waiting-For-Support': [
    'Waiting-For-Support',
    'Visited-Closed',
    'Visited-Not Closed'
  ],
};

List<String> fetchIssuesIdentified(String deviceOrAssetType) {
  var deviceAssetType = getDeviceAssetType(deviceOrAssetType);

  final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');
  log([
    "Problem Type*",
    ...List<String>.from(
      probIssueBox.get('issues_identified')[deviceAssetType] ?? [],
    )
  ].toString());

  return [
    "Issues Identified",
    ...List<String>.from(
      probIssueBox.get('issues_identified')[deviceAssetType] ?? [],
    )
  ];
}

List<String> fetchProblemTypes(String deviceOrAssetType) {
  var deviceAssetType = getDeviceAssetType(deviceOrAssetType);

  if (deviceAssetType == 'default') {
    return ["Problem Type*"];
  }
  final probIssueBox = Hive.box('problemTypesAndIssuesIdentified');
  log([
    "Problem Type*",
    ...List<String>.from(
      probIssueBox.get('problem_types')[deviceAssetType] ?? [],
    )
  ].toString());

  return [
    "Problem Type*",
    ...List<String>.from(
      probIssueBox.get('problem_types')[deviceAssetType] ?? [],
    )
  ];
}

String getDeviceAssetType(String deviceOrAssetType) {
  switch (deviceOrAssetType) {
    case 'CCMS':
      return 'slc';
    case 'SMSLC':
      return 'slc';
    case 'LAMP':
      return 'lamp';
    case 'GW':
      return 'gw';
    case 'SEMC':
      return 'gw';
    case 'ILM':
      return 'ilm';
    case 'ILM-4G':
      return 'ilm';
    case 'POLE':
      return 'pole';
    case 'OTHERS':
      return 'others';
    case 'DEVICE/ASSET TYPE*':
      return 'default';
    default:
      return deviceOrAssetType.toLowerCase();
  }
}

const problemTypes = {
  "CCMS": [
    "Problem Type*",
    "Lamps not burning",
    "Day time burning",
    "Timing issue",
    "MCB Trip",
    "High Voltage",
    "Low Voltage",
    "High Current",
    "Bypass",
    "Not communicating",
    "Input Power unavailable",
    "Panel Door Open",
    "Preventive Maintenance",
    "RF Signal Rank poor",
    "4G network poor",
    "Others"
  ],
  "SMSLC": [
    "Problem Type*",
    "Lamps not burning",
    "Day time burning",
    "Timing issue",
    "MCB Trip",
    "High Voltage",
    "Low Voltage",
    "High Current",
    "Bypass",
    "Not communicating",
    "Input Power unavailable",
    "Panel Door Open",
    "Preventive Maintenance",
    "RF Signal Rank poor",
    "4G network poor",
    "Others"
  ],
  "LAMP": [
    "Problem Type*",
    "Not burning",
    "Flickering",
    "Day time burning",
    "Others"
  ],
  "GW": [
    "Problem Type*",
    "Not communicating",
    "Input Power unavailable",
    "RF Signal Rank Poor",
    "4G network poor",
    "Others"
  ],
  "SEMC": [
    "Problem Type*",
    "Not communicating",
    "Input Power unavailable",
    "RF Signal Rank Poor",
    "4G network poor",
    "Others"
  ],
  "ILM": [
    "Problem Type*",
    "Not communicating",
    "Input Power unavailable",
    "RF Signal Rank poor",
    "4G network poor",
    "Not burning",
    "Flickering",
    "Day time burning",
    "Others"
  ],
  "ILM-4G": [
    "Problem Type*",
    "Not communicating",
    "Input Power unavailable",
    "RF Signal Rank poor",
    "4G network poor",
    "Not burning",
    "Flickering",
    "Day time burning",
    "Others"
  ],
  "POLE": ["Problem Type*", "Pole damaged", "Others"],
  "OTHERS": ["Problem Type*", "Others"],
  "DEVICE/ASSET TYPE*": ["Problem Type*"]
};

const assetTypes = ["Switch Point", "Pole", "Transformer"];
const poleTypes = [
  'RCC',
  'Tubular',
  'Post Top',
  'Octagonal',
  'High Mast(HM)',
  'Mini Mast(MM)',
  'Metal',
  'Spun',
  'Others'
];

List<String> poleHeightOptions = [
  '7 m',
  '8 m',
  '9 m',
  '10 m',
  '12 m',
  '16 m',
  '20 m',
  'Others',
];

const poleSpan = [
  'Less than 20 m',
  '20 m',
  '25 m',
  '30 m',
  '35 m',
  '40 m',
  'More than 40 m',
];

const poleConditions = ['Good', 'Bad', 'Missing'];

// Sample lamp types and their corresponding wattages
final List<String> lampTypes = [
  'Lamp Type',
  'Tube light',
  'SVL',
  'CFL',
  'LED',
  'T5',
  'BULB'
];

final Map<String, List<String>> lampWattages = {
  'Lamp Type': ['Lamp Wattage'],
  'Tube light': [
    '40 W',
  ],
  'SVL': [
    '150 W',
    '250 W',
    '400 W',
  ],
  'CFL': [
    '25 W',
    '36 W',
    '65 W',
    '72 W',
    '85 W',
  ],
  'LED': [
    '20 W',
    '40 W',
    '60 W',
    '70 W',
    '90 W',
    '120 W',
    '150 W',
    '200 W',
  ],
  'T5': [
    '96 W',
    '120 W',
    '220 W',
  ],
  'BULB': ['10 W'],
};

List<Map<String, String>> selectedLamps = [
  {
    'type': 'Lamp Type',
    'watts': 'Lamp Wattage',
  },
];

List<String> incomingTransLineOptions = [
  'Under Ground',
  'Conductor',
  'Overhead',
  'Missing',
  'ABC',
];

const incomingTransTypeOptions = [
  'Dedicated for Streetlight',
  'Taping from CommonLine',
];

List<String> bracketMountingHeightOptions = [
  'Not Required',
  '6 m',
  '7 m',
  '8 m',
  '9 m',
  '12 m',
  '16 m',
  'Others'
];

const manualSwitchControlOptions = [
  'Exists - Good Condition',
  'Exists - Bad Condition',
  'Exists - Not working',
  'Not Exists'
];

Map<String, List<String>> lampWattageOptions = {
  'Tube light': ['40 W'],
  'SVL': ['150 W', '250 W', '400 W'],
  'CFL': ['25 W', '36 W', '65 W', '72 W', '85 W'],
  'LED': ['20 W', '40 W', '60 W', '70 W', '90 W', '120 W', '150 W', '200 W'],
  'T5': ['96 W', '120 W', '220 W'],
  'BULB': ['10 W'],
  'MH': ['150 W', '250 W', '400 W']
};

const clampTypeOptions = [
  'Clamp Type Not Required',
  '6 x 3 inch',
  '7 x 3 inch',
  '8 x 4 inch',
  '11 x 3 inch',
  '12 x 4 inch',
  'Others',
];

List<String> armCountOptions = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  '11',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18',
  '19',
  '20'
];

final Map<String, List<String>> roadTypeOptions = {
  'A1': ['Main Road', 'Bridge'],
  'A2': ['Main Road', 'Bridge'],
  'B1': ['Service Road'],
  'B2': ['Service Road'],
  'Park': ['Park Road'],
};

final Map<String, List<String>> roadWidthOptions = {
  'Main Road': ['above 9m', '7m-9m'],
  'Bridge': ['above 9m', '7m-9m'],
  'Service Road': ['upto 5m', '5m-7m'],
  'Park Road': ['others'],
};

final Map<String, List<String>> vehicleAccessOptions = {
  'above 9m': ['Long Truck'],
  '7m-9m': ['mini Truck'],
  '5m-7m': ['Jeep/Bada Dosth'],
  'upto 5m': ['Tata Ace', 'Narrower than Tata Ace'],
  'others': ['Tata Ace'],
};

const trafficDensityOptions = ['High', 'Low'];
const trafficSpeedOptions = ['Slow Moving', 'Fast Moving'];

List<String> units = ['cm', 'inch', 'mm'];

const switchPointTypeOptions = ['Feeder Pillar', 'HRC Fuse', 'Timer Box'];
const sPMeterOptions = ['Working', 'Not Working', 'Missing'];
const spConditionOptions = ['Working', 'Not Working'];
const spEarthingConditionOptions = ['Good', 'Bad', 'N.A'];
const spMeterTypeOptions = ['Digital', 'Analogue', 'DP/Manual'];
const spPhaseOptions = ['1', '3'];
const spMakeOptions = ['L&T', 'Others'];

const poleMotorRatingUnitsOptions = ['hp', 'kW'];
const poleWinchConditionOptions = ['Good', 'Faulty'];
const poleRopeConditionOptions = ['Working', 'Not Working'];
const motorConditionOptions = ['Good', 'Bad', 'Missing'];
