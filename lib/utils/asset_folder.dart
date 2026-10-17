import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final assetsController = ChangeNotifierProvider<Assets>((ref) => Assets());

const logoImage = 'assets/images/logo.png';

Map<String, File> imageLocation = {
  "ilm": Assets.lightpoint,
  "lumiNode": Assets.lightpoint,
  "ilm-4g": Assets.lightpoint,
  "gw": Assets.gateway,
  "nic": Assets.gateway,
  "lightPoint": Assets.lightpoint,
  "ccms": Assets.ccmsPanel,
  "smslc": Assets.ccmsPanel,
  "hub": Assets.hub,
  "lamp": Assets.lampSearch,
  "pole": Assets.pole,
  "eb": Assets.ebMeter,
  "semc": Assets.ebMeter,
  "others": Assets.warning
};

class Assets extends ChangeNotifier {
  static late File ccmsPanel;
  static late File ilmDeviceWithBg;
  static late File lampSearch;
  static late File lightpoint;
  static late File ccmsScannerImage;
  static late File gatewayMap;
  static late File gateway;
  static late File gMapPointer;
  static late File gMapLocation;
  static late File hub;
  static late File ilmScannerImage;
  static late File ilmDeviceWithoutBg;
  static late File lampAndILm;
  static late File lamp;
  static late File lampInstallation;
  static late File lampSampleImages1;
  static late File lampSampleImages2;
  static late File gMapPointerWaterMark;
  static late File panelscannerImage;
  static late File panelMap;
  static late File pole;
  static late File ilmScannerImage2;
  static late File shortingCap;
  static late File tickets;
  static late File wifi;
  static late File warning;
  static late File userAlertLottie;
  static late File successtickLottie;
  static late File expiredLottie;
  static late File logoutLottie;
  static late File wardRequiredLottie;
  static late File ilmInsideGif;
  static late File ilmOutsideGif;
  static late File ccmsPanelGif;
  static late File lumiHubInsideGif;
  static late File lumiHubOutsideGif;
  static late File poleInstalltransparent;
  static late File ebMeter;
  static late File meterReading;
  static late File panelSampleImage1;
  static late File panelSampleImage2;
  static late File panelSampleImage3;

  static List<String> fileNames = [
    'userAlert.json',
    'tick.json',
    'expired.json',
    'logout.json',
    'wardRequired.json',
    'ilmInside.gif',
    'ilmOutside.gif',
    'lumiHubOutside.gif',
    'ccmsPanel.gif',
    'lumiHubInside.gif',
    'ccmsSearch.png',
    'ILMDevice.jpg',
    'LampSearch.png',
    'LightPointMap.png',
    'ccmsSearch.png',
    'gatewayMap.png',
    'gatewaySearch.jpg',
    'gmap.png',
    'googleMapLocation.png',
    'hubSearch.png',
    'ilmCameraImage.png',
    'ilmWithoutBckgrnd.png',
    'lamp&ILM.png',
    'lamp.png',
    'lampInstallation.png',
    'lampSchematic1.jpg',
    'lampSchematic2.jpg',
    'locationPointer.png',
    'panelILMImage.jpg',
    'panelMap.png',
    'poleSearch.jpeg',
    'qrILMImage.png',
    'shorting_cap.png',
    'tickets.png',
    'wifi.png',
    'warning.png',
    'poleIcontransparent.png',
    'meterReading.png',
    'ebMeter.jpg',
    'panelSampleImage1.jpeg',
    'panelSampleImage2.jpeg',
    'panelSampleImage3.jpeg'
  ];
  static final _progressController = StreamController<double>.broadcast();
  static Stream<double> get progressStream => _progressController.stream;

  static int totalFiles = 51;
  static int _downloadedFiles = 0;

  static Future<bool> checkFileExists(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    File file = File('${dir.path}/$fileName');
    if (!await file.exists()) {
      log('Missing file: $fileName');
      return false;
    }
    return true;
  }

  Future<File> downloadFile(String fileName) async {
    final storage = FirebaseStorage.instance.ref('/images');

    late File file;
    final dir = await getApplicationDocumentsDirectory();
    final fileList = await dir.list().toList();
    final fileCount = fileList.whereType<File>().length;

    try {
      final totalFirebaseFiles = await storage.listAll();
      int totalFirebaseFilesCount = totalFirebaseFiles.items.length;
      final result = storage.child("/$fileName");
      log('total firebase file count - $result, downloaded file count - $fileCount, percentage - ${fileCount / double.parse(totalFirebaseFilesCount.toString()) * 100}');

      final filePath = '${dir.path}/$fileName';
      file = File(filePath);
      await result.writeToFile(file);
      log('File stored successfully: $filePath');

      _downloadedFiles++;
      _progressController.add(_downloadedFiles / totalFiles);
      return file;
    } catch (e) {
      log('Error downloading files: $e');
      return File('path');
    }
  }

  Future<void> initializeAssets() async {
    _downloadedFiles = 0;
    final dir = await getApplicationDocumentsDirectory();
    userAlertLottie = await checkFileExists('userAlert.json')
        ? File('${dir.path}/userAlert.json')
        : await downloadFile('userAlert.json');

    successtickLottie = await checkFileExists('tick.json')
        ? File('${dir.path}/tick.json')
        : await downloadFile('tick.json');

    expiredLottie = await checkFileExists('expired.json')
        ? File('${dir.path}/expired.json')
        : await downloadFile('expired.json');

    logoutLottie = await checkFileExists('logout.json')
        ? File('${dir.path}/logout.json')
        : await downloadFile('logout.json');

    wardRequiredLottie = await checkFileExists('wardRequired.json')
        ? File('${dir.path}/wardRequired.json')
        : await downloadFile('wardRequired.json');

    ilmInsideGif = await checkFileExists('ilmInside.gif')
        ? File('${dir.path}/ilmInside.gif')
        : await downloadFile('ilmInside.gif');

    ilmOutsideGif = await checkFileExists('ilmOutside.gif')
        ? File('${dir.path}/ilmOutside.gif')
        : await downloadFile('ilmOutside.gif');

    lumiHubOutsideGif = await checkFileExists('lumiHubOutside.gif')
        ? File('${dir.path}/lumiHubOutside.gif')
        : await downloadFile('lumiHubOutside.gif');

    ccmsPanelGif = await checkFileExists('ccmsPanel.gif')
        ? File('${dir.path}/ccmsPanel.gif')
        : await downloadFile('ccmsPanel.gif');

    lumiHubInsideGif = await checkFileExists('lumiHubInside.gif')
        ? File('${dir.path}/lumiHubInside.gif')
        : await downloadFile('lumiHubInside.gif');

    ccmsPanel = await checkFileExists('ccmsSearch.png')
        ? File('${dir.path}/ccmsSearch.png')
        : await downloadFile('ccmsSearch.png');

    ilmDeviceWithBg = await checkFileExists('ILMDevice.jpg')
        ? File('${dir.path}/ILMDevice.jpg')
        : await downloadFile('ILMDevice.jpg');

    lampSearch = await checkFileExists('LampSearch.png')
        ? File('${dir.path}/LampSearch.png')
        : await downloadFile('LampSearch.png');

    lightpoint = await checkFileExists('LightPointMap.png')
        ? File('${dir.path}/LightPointMap.png')
        : await downloadFile('LightPointMap.png');

    ccmsScannerImage = await checkFileExists('ccmsCameraImage.png')
        ? File('${dir.path}/ccmsCameraImage.png')
        : await downloadFile('ccmsCameraImage.png');

    gatewayMap = await checkFileExists('gatewayMap.png')
        ? File('${dir.path}/gatewayMap.png')
        : await downloadFile('gatewayMap.png');

    gateway = await checkFileExists('gatewaySearch.jpg')
        ? File('${dir.path}/gatewaySearch.jpg')
        : await downloadFile('gatewaySearch.jpg');

    gMapPointer = await checkFileExists('gmap.png')
        ? File('${dir.path}/gmap.png')
        : await downloadFile('gmap.png');

    gMapLocation = await checkFileExists('googleMapLocation.png')
        ? File('${dir.path}/googleMapLocation.png')
        : await downloadFile('googleMapLocation.png');

    hub = await checkFileExists('hubSearch.png')
        ? File('${dir.path}/hubSearch.png')
        : await downloadFile('hubSearch.png');

    poleInstalltransparent = await checkFileExists('poleIcontransparent.png')
        ? File('${dir.path}/poleIcontransparent.png')
        : await downloadFile('poleIcontransparent.png');

    ilmScannerImage = await checkFileExists('ilmCameraImage.png')
        ? File('${dir.path}/ilmCameraImage.png')
        : await downloadFile('ilmCameraImage.png');

    ilmDeviceWithoutBg = await checkFileExists('ilmWithoutBckgrnd.png')
        ? File('${dir.path}/ilmWithoutBckgrnd.png')
        : await downloadFile('ilmWithoutBckgrnd.png');

    lampAndILm = await checkFileExists('lamp&ILM.png')
        ? File('${dir.path}/lamp&ILM.png')
        : await downloadFile('lamp&ILM.png');

    lamp = await checkFileExists('lamp.png')
        ? File('${dir.path}/lamp.png')
        : await downloadFile('lamp.png');

    lampInstallation = await checkFileExists('lampInstallation.png')
        ? File('${dir.path}/lampInstallation.png')
        : await downloadFile('lampInstallation.png');

    lampSampleImages1 = await checkFileExists('lampSchematic1.jpg')
        ? File('${dir.path}/lampSchematic1.jpg')
        : await downloadFile('lampSchematic1.jpg');

    lampSampleImages2 = await checkFileExists('lampSchematic2.jpg')
        ? File('${dir.path}/lampSchematic2.jpg')
        : await downloadFile('lampSchematic2.jpg');

    gMapPointerWaterMark = await checkFileExists('locationPointer.png')
        ? File('${dir.path}/locationPointer.png')
        : await downloadFile('locationPointer.png');

    panelscannerImage = await checkFileExists('panelILMImage.jpg')
        ? File('${dir.path}/panelILMImage.jpg')
        : await downloadFile('panelILMImage.jpg');

    panelMap = await checkFileExists('panelMap.png')
        ? File('${dir.path}/panelMap.png')
        : await downloadFile('panelMap.png');

    pole = await checkFileExists('poleSearch.jpeg')
        ? File('${dir.path}/poleSearch.jpeg')
        : await downloadFile('poleSearch.jpeg');

    ilmScannerImage2 = await checkFileExists('qrILMImage.jpg')
        ? File('${dir.path}/qrILMImage.jpg')
        : await downloadFile('qrILMImage.jpg');

    shortingCap = await checkFileExists('shorting_cap.png')
        ? File('${dir.path}/shorting_cap.png')
        : await downloadFile('shorting_cap.png');

    tickets = await checkFileExists('tickets.png')
        ? File('${dir.path}/tickets.png')
        : await downloadFile('tickets.png');

    wifi = await checkFileExists('wifi.png')
        ? File('${dir.path}/wifi.png')
        : await downloadFile('wifi.png');

    warning = await checkFileExists('warning.png')
        ? File('${dir.path}/warning.png')
        : await downloadFile('warning.png');

    ebMeter = await checkFileExists('ebMeter.jpg')
        ? File('${dir.path}/ebMeter.jpg')
        : await downloadFile('ebMeter.jpg');

    meterReading = await checkFileExists('meterReading.png')
        ? File('${dir.path}/meterReading.png')
        : await downloadFile('meterReading.png');

    panelSampleImage1 = await checkFileExists('panelSampleImage1.jpeg')
        ? File('${dir.path}/panelSampleImage1.jpeg')
        : await downloadFile('panelSampleImage1.jpeg');

    panelSampleImage2 = await checkFileExists('panelSampleImage2.jpeg')
        ? File('${dir.path}/panelSampleImage2.jpeg')
        : await downloadFile('panelSampleImage2.jpeg');

    panelSampleImage3 = await checkFileExists('panelSampleImage3.jpeg')
        ? File('${dir.path}/panelSampleImage3.jpeg')
        : await downloadFile('panelSampleImage3.jpeg');

    _progressController.close();
  }
}
