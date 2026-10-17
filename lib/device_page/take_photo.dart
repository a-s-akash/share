import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:schnell_luminator/device_page/image_address_append.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/survey_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/utility.dart';
import 'package:schnell_luminator/utils/image_compression_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:animated_hint_textfield/animated_hint_textfield.dart';
import 'package:uuid/uuid.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../utils/asset_folder.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import 'gw_semc_take_photo.dart';

class TakePictureScreen extends ConsumerStatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
    required this.clickeventIsFor,
  });

  final CameraDescription camera;
  final String clickeventIsFor;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends ConsumerState<TakePictureScreen> {
  ImageAddressAppender appender = ImageAddressAppender();
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;
  late Position position;
  String long = "", lat = "", acc = '';
  double finacc = 10;
  late StreamSubscription<Position> positionStream;
  final container = ProviderContainer();
  checkpermission() async {
    var camerastatus = await Permission.camera.status;
    if (camerastatus.isDenied) {
      Permission.camera.request();
    }
  }

  List<Widget> getSampleImagesBasedOnprocess(clickeventIsFor) {
    switch (clickeventIsFor) {
      case 'addILM': //
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'addILMViaPole':
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'addLamp':
      case 'recordExistingLamp':
        return [
          Image.file(Assets.lampSampleImages1),
          Image.file(Assets.lampSampleImages2),
        ];

      case '1':
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'ilmReplace': //
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'lampOnlyReplace': //
        return [
          Image.file(Assets.lampSampleImages1),
          Image.file(Assets.lampSampleImages2),
        ];
      case 'lamp+ilmReplace': //
        return [
          Image.file(Assets.lampSampleImages1),
          Image.file(Assets.lampSampleImages2),
        ];
      case 'gwReplace':
      case 'semcReplace':
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'ilmRemove': //
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'scanLampViaILM': //
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'withoutLampViaILM': //
        return [
          Container(
            height: 115,
            width: 100,
            decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).hoverColor)),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.file(Assets.ilmScannerImage),
            ),
          ),
          Container(
              height: 115,
              width: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).hoverColor)),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Image.file(Assets.ccmsScannerImage),
              )),
        ];
      case 'removeLamp': //
        return [
          Image.file(Assets.lampSampleImages1),
          Image.file(Assets.lampSampleImages2),
        ];

      case 'addLampInMaintenance': //
        return [
          Image.file(Assets.lampSampleImages1),
          Image.file(Assets.lampSampleImages2),
        ];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium,
        enableAudio: false);
    _initializeControllerFuture = _controller.initialize();
    ref.read(deviceController).getTitleBasedOnActivity(widget.clickeventIsFor);
  }

  // @override
  // void deactivate() {
  //   // Extra safety: release camera when widget is removed from tree
  //   _controller.dispose();
  //   super.deactivate();
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> images = getSampleImagesBasedOnprocess(widget.clickeventIsFor);
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    String poleLocation = ref.watch(deviceController).poleLocation;
    String lpLandmark = ref.watch(deviceController).lpLandmark;
    String firstDeviceType = ref.watch(deviceController).firstDeviceType;
    String ccmsLandmark = ref.watch(deviceController).ccmsLandmark;
    String hubLandmark = ref.watch(deviceController).hubLandmark;
    String newLmpType = ref.watch(deviceController).newLmpType;
    String newLmpWattage = ref.watch(deviceController).newLmpWattage;
    String finalNewLmpName = ref.watch(deviceController).finalNewLmpName;

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          if (qrViewController != null) {
            qrViewController.resumeCamera();
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).cardColor,
              ),
              onPressed: () {
                Navigator.pop(context);
                if (qrViewController != null) {
                  qrViewController.resumeCamera();
                }
              },
            ),
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.19),
            elevation: 0.0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 18.0,
            ),
            title: Text(
              "TAKE A PICTURE",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
            // actions: [
            //   if (images.isNotEmpty)
            //     Padding(
            //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
            //       child: GestureDetector(
            //         onTap: () {
            //           showDialog(
            //             context: context,
            //             barrierDismissible: true,
            //             builder: (BuildContext context) {
            //               return Dialog(
            //                 child: Stack(
            //                   children: [
            //                     Padding(
            //                       padding: const EdgeInsets.all(20.0),
            //                       child: Column(
            //                         mainAxisSize: MainAxisSize.min,
            //                         children: [
            //                           const Text('Sample Images',
            //                               style: TextStyle(
            //                                   fontWeight: FontWeight.bold,
            //                                   fontSize: 18)),
            //                           const SizedBox(height: 15),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceEvenly,
            //                             children: [
            //                               ...images,
            //                             ],
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                     Positioned(
            //                       top: 5,
            //                       right: 5,
            //                       child: GestureDetector(
            //                         onTap: () => Navigator.of(context).pop(),
            //                         child: Container(
            //                           decoration: const BoxDecoration(
            //                             color: Colors.black54,
            //                             shape: BoxShape.circle,
            //                           ),
            //                           padding: const EdgeInsets.all(5),
            //                           child: const Icon(Icons.close,
            //                               color: Colors.white, size: 20),
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               );
            //             },
            //           );
            //         },
            //         child: Row(
            //           mainAxisSize: MainAxisSize.min,
            //           children: [
            //             Icon(
            //               Icons.info,
            //               size: 25,
            //               color: Theme.of(context).cardColor,
            //             ),
            //             const SizedBox(width: 5),
            //             SizedBox(
            //               height: 30,
            //               width: 30,
            //               child: ClipRRect(
            //                 borderRadius: BorderRadius.circular(4),
            //                 child: FittedBox(
            //                   fit: BoxFit.cover,
            //                   child: images.first,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            // ],
          ),
          body: ConnectivityBanner(
            child: Container(
              color: Theme.of(context).dialogTheme.backgroundColor,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ...images,
                      ],
                    )),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 15.0,
                    right: 15.0,
                  ),
                  child: FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_controller);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                ),
              ]),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              height: 70.0,
              width: 70.0,
              child: FittedBox(
                child: Semantics(
                  label: 'camera_capture_fab',
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).cardColor,
                    onPressed: () async {
                      EasyLoading.show(
                          status: 'loading...', dismissOnTap: false);
                      try {
                        await _initializeControllerFuture;
                        final image = await _controller.takePicture();
                        _controller.pausePreview();

                        loc.Location location = loc.Location();

                        bool serviceEnabled;
                        loc.PermissionStatus permissionGranted;
                        loc.LocationData locationData;

                        serviceEnabled = await location.serviceEnabled();
                        if (!serviceEnabled) {
                          serviceEnabled = await location.requestService();
                          if (!serviceEnabled) {
                            return;
                          }
                        }

                        String landMark = '';

                        if (firstDeviceType == "GW") {
                          if (ccmsLandmark.isEmpty) {
                            if (hubLandmark.isEmpty) {
                              locationData = await location.getLocation();
                              double lat = locationData.latitude!;
                              double long = locationData.longitude!;
                              landMark = await ref
                                  .read(surveyController)
                                  .getUserLocation(lat, long);
                            } else {
                              landMark = hubLandmark;
                            }
                          } else {
                            landMark = ccmsLandmark;
                          }
                        } else {
                          if (poleLocation.isEmpty) {
                            if (lpLandmark.isEmpty) {
                              locationData = await location.getLocation();
                              double lat = locationData.latitude!;
                              double long = locationData.longitude!;
                              landMark = await ref
                                  .read(surveyController)
                                  .getUserLocation(lat, long);
                            } else {
                              landMark = lpLandmark;
                            }
                          } else {
                            landMark = poleLocation;
                          }
                        }
                        // String landMark = firstDeviceType == "GW"
                        //     ? ccmsLandmark.isEmpty
                        //         ? (hubLandmark.isEmpty
                        //             ? await getUserLocation(lat, long)
                        //             : hubLandmark)
                        //         : ccmsLandmark
                        //     : poleLocation.isEmpty
                        //         ? (lpLandmark.isEmpty
                        //             ? await getUserLocation(lat, long)
                        //             : lpLandmark)
                        //         : poleLocation;

                        if (!mounted) return;
                        EasyLoading.dismiss();
                        _controller.pausePreview();
                        log('values for $finalNewLmpName: $newLmpType and $newLmpWattage');

                        if (context.mounted) {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DisplayPictureScreen(
                                imagePaths: [image.path],
                                landMark: landMark,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        EasyLoading.dismiss();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              homeRoute, (Route<dynamic> route) => false);
                        }
                        if (context.mounted) {
                          await snackBar(
                              context,
                              ErrorMessages.networkErrorTitle,
                              ErrorMessages.networkErrorMessage);
                        }

                        log(e.toString());
                      }
                    },
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DisplayPictureScreen extends ConsumerStatefulWidget {
  final List<String> imagePaths;
  final String landMark;

  const DisplayPictureScreen({
    super.key,
    required this.imagePaths,
    required this.landMark,
  });

  @override
  ConsumerState<DisplayPictureScreen> createState() =>
      _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends ConsumerState<DisplayPictureScreen> {
  final TextEditingController locationAddress = TextEditingController();
  final TextEditingController newMeterReadingValue = TextEditingController();
  final TextEditingController oldMeterReadingValue = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    locationAddress.dispose();
    newMeterReadingValue.dispose();
    oldMeterReadingValue.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.imagePaths.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey.shade400,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    var deviceType = ref.watch(deviceController).firstDeviceType;
    String lampAssetType = ref.watch(deviceController).lampAssetType;
    String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;
    bool isButtonEnabled = ref.watch(deviceController).isButtonEnabled;
    int firstOrSecondDevice = ref.watch(deviceController).firstOrSecondDevice;
    String fetchedLong = ref.watch(deviceController).fetchedLong;
    String fetchedLat = ref.watch(deviceController).fetchedLat;
    String ccmsLat = ref.watch(deviceController).ccmsLat;
    String ccmsLong = ref.watch(deviceController).ccmsLong;
    String hubLat = ref.watch(deviceController).hubLat;
    String hubLong = ref.watch(deviceController).hubLong;
    String lpLat = ref.watch(deviceController).lpLat;
    String lpLong = ref.watch(deviceController).lpLong;
    String poleLat = ref.watch(deviceController).poleLat;
    String poleLong = ref.watch(deviceController).poleLong;
    bool isLocationFetched = ref.watch(deviceController).isLocationFetched;
    ImageAddressAppender appender = ImageAddressAppender();
    String region = ref.watch(deviceController).selectedRegion;
    String zone = ref.watch(deviceController).selectedZone;
    String ward = ref.watch(deviceController).selectedWard;
    String lpRegion = ref.watch(deviceController).lpregion;
    String lpzone = ref.watch(deviceController).lpzone;
    String lpward = ref.watch(deviceController).lpward;
    String deviceNameForImgAppend =
        ref.watch(deviceController).deviceNameForImgAppend;
    File mapIconPath = ref.watch(deviceController).mapIconPath;

    String getActivity() {
      if (clickeventIsFor == 'addILM' ||
          clickeventIsFor == 'addILMViaPole' ||
          clickeventIsFor == 'scanLampViaILM' ||
          clickeventIsFor == 'withoutLampViaILM' ||
          clickeventIsFor == 'addLamp' ||
          clickeventIsFor == 'recordExistingLamp' ||
          clickeventIsFor == '1') {
        return 'INSTALL';
      } else if (clickeventIsFor == 'ilmReplace' ||
          clickeventIsFor == 'lampOnlyReplace' ||
          clickeventIsFor == 'lamp+ilmReplace' ||
          clickeventIsFor == 'ebMeterReplace' ||
          clickeventIsFor == 'gwReplace') {
        return 'REPLACE';
      } else if (clickeventIsFor == 'ilmRemove' ||
          clickeventIsFor == 'removeLamp') {
        return 'REMOVE';
      }
      return '';
    }

    Future<void> handleComplete(List<String> imagePath) async {
      log('imagePath: $imagePath');
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      // validates whether the location is fetched
      if (!isLocationFetched &&
          (clickeventIsFor == "1" ||
              clickeventIsFor == "withoutLampViaILM" ||
              clickeventIsFor == "scanLampViaILM")) {
        await warningAlert(ref, context, 'Location is fetching');
        return;
      }
      ref.read(deviceController).disableButton();
      EasyLoading.show(status: 'loading...', dismissOnTap: false);

      Utility.isConnected().then((value) async {
        if (value) {
          var uuid = const Uuid();
          var manualEntered = locationAddress.text;
          if (context.mounted) {
            await ref.read(deviceController).addUserInputValue(
                ref,
                context,
                manualEntered,
                newMeterReadingValue.text,
                oldMeterReadingValue.text);
          }
          String manualEnteredAddress =
              manualEntered.isEmpty ? '' : '$manualEntered, ';
          String projectContext = lpRegion.isEmpty
              ? '$region / $zone / $ward'
              : '$lpRegion / $lpzone / $lpward';
          File file = mapIconPath;
          Uint8List iconData = file.readAsBytesSync();

          await appender.appendAddressToImage(
            ref,
            imagePath,
            manualEnteredAddress,
            widget.landMark,
            iconData,
            projectContext,
            deviceNameForImgAppend,
          );
          List<String> compressedFilePaths = [];
          List<String> fileNames = [];

          for (String path in imagePath) {
            var fileName = uuid.v1();
            final filePath = await ImageCompressionUtil.compressAndSaveImage(
              originalImagePath: path,
              fileName: fileName,
            );
            compressedFilePaths.add(filePath);
            fileNames.add(fileName);
          }

          if (context.mounted) {
            if (compressedFilePaths.length == 1) {
              log('captured device image during activity: ${compressedFilePaths[0]}');
              log('generated uid: ${fileNames[0]}');
              ref.read(deviceController).s3imageUpload(
                  ref,
                  context,
                  compressedFilePaths[0],
                  firstOrSecondDevice,
                  fileNames[0],
                  getActivity());
            } else {
              log('captured multiple device images');
              ref
                  .read(deviceController)
                  .s3ThreeImagesUpload(compressedFilePaths, fileNames);
            }
          }
          var luminareData = {
            "deviceImage": imagePath[0],
            "landmark": widget.landMark
          };
          var gwdata = {
            "deviceImage": imagePath[0],
            "location": widget.landMark
          };

          //installation
          if (firstOrSecondDevice == 1) {
            //addLamp
            if (clickeventIsFor == "addLamp" ||
                clickeventIsFor == "recordExistingLamp" ||
                clickeventIsFor == "addLampInMaintenance") {
              if (context.mounted) {
                await ref.read(deviceController).lampInstallation(
                    ref, context, luminareData, clickeventIsFor);
              }
            } else {
              if (context.mounted) {
                await ref.read(deviceController).deviceInstallation(
                    ref,
                    context,
                    deviceType == "ILM" ||
                            deviceType == "LUMINODE" ||
                            deviceType == 'ILM-4G' ||
                            lampAssetType == "LAMP"
                        ? luminareData
                        : gwdata,
                    clickeventIsFor);
              }
            }
            //replace
          } else if (firstOrSecondDevice == 2) {
            if (clickeventIsFor == "lampOnlyReplace") {
              if (context.mounted) {
                await ref
                    .read(deviceController)
                    .lampOnlyReplace(ref, context, luminareData);
              }
            } else if (clickeventIsFor == "lamp+ilmReplace") {
              if (context.mounted) {
                await ref
                    .read(deviceController)
                    .lampAndILMReplace(ref, context, luminareData);
              }
            } else {
              if (context.mounted) {
                await ref.read(deviceController).deviceReplace(
                    ref,
                    context,
                    deviceType == "ILM" ||
                            deviceType == "LUMINODE" ||
                            deviceType == 'ILM-4G'
                        ? luminareData
                        : gwdata);
              }
            }
            //remove
          } else {
            //removeLamp
            if (clickeventIsFor == "removeLamp") {
              if (context.mounted) {
                await ref.read(deviceController).lampRemove(ref, context, {});
              }
            } else {
              if (context.mounted) {
                await ref.read(deviceController).deviceRemove(ref, context, {});
              }
            }
          }
          // }
        } else {
          if (context.mounted) {
            await snackBar(context, ErrorMessages.offlineErrorTitle,
                ErrorMessages.offlineErrorMessage);
          }
        }
      });
    }

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          extendBody: false,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 60,
                child: FittedBox(
                  child: FloatingActionButton(
                    heroTag: const Text("btn2"),
                    backgroundColor: Theme.of(context).primaryColor,
                    onPressed: () async {
                      final cameras = await availableCameras();
                      final firstCamera = cameras.first;
                      String clickeventIsFor =
                          ref.watch(deviceController).clickeventIsFor;
                      final hubOrCcms = ref.watch(deviceController).assetType;

                      String firstDeviceType =
                          ref.watch(deviceController).firstDeviceType;

                      if (((firstDeviceType == 'GW' && hubOrCcms == 'ccms') ||
                              (firstDeviceType == "SEMC")) ||
                          clickeventIsFor == "addLamp") {
                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GwSemcCaptureThreeImagesScreen(
                                      clickeventIsFor: clickeventIsFor,
                                      requiredImageCount:
                                          clickeventIsFor == "addLamp" ? 3 : 3),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TakePictureScreen(
                                camera: firstCamera,
                                clickeventIsFor: clickeventIsFor,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Icon(
                      Icons.restart_alt,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                height: 70,
                child: FittedBox(
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check,
                      size: 20,
                    ),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: isButtonEnabled
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dialogTheme.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                    ),
                    onPressed: isButtonEnabled
                        ? () async {
                            await handleComplete(widget.imagePaths);
                          }
                        : null,
                    // onPressed: isButtonEnabled
                    //     ? () async {
                    //         SystemChannels.textInput
                    //             .invokeMethod('TextInput.hide');

                    //         // validates whether the location is fetched
                    //         if (!isLocationFetched &&
                    //             (clickeventIsFor == "1" ||
                    //                 clickeventIsFor == "withoutLampViaILM" ||
                    //                 clickeventIsFor == "scanLampViaILM")) {
                    //           await warningAlert(
                    //               ref, context, 'Location is fetching');
                    //           return;
                    //         }
                    //         ref.read(deviceController).disableButton();
                    //         EasyLoading.show(
                    //             status: 'loading...', dismissOnTap: false);

                    //         Utility.isConnected().then((value) async {
                    //           if (value) {
                    //             var uuid = const Uuid();
                    //             var manualEntered = locationAddress.text;
                    //             if (context.mounted) {
                    //               await ref
                    //                   .read(deviceController)
                    //                   .addUserInputValue(
                    //                       ref,
                    //                       context,
                    //                       manualEntered,
                    //                       newMeterReadingValue.text,
                    //                       oldMeterReadingValue.text);
                    //             }
                    //             String manualEnteredAddress =
                    //                 manualEntered.isEmpty
                    //                     ? ''
                    //                     : '$manualEntered, ';
                    //             String projectContext = lpRegion.isEmpty
                    //                 ? '$region / $zone / $ward'
                    //                 : '$lpRegion / $lpzone / $lpward';
                    //             File file = mapIconPath;
                    //             Uint8List iconData = file.readAsBytesSync();

                    //             await appender.appendAddressToImage(
                    //               ref,
                    //               [imagePath],
                    //               manualEnteredAddress,
                    //               landMark,
                    //               iconData,
                    //               projectContext,
                    //               deviceNameForImgAppend,
                    //             );
                    //             var fileName = uuid.v1();
                    //             final filePath =
                    //                 await Utility.activityCompressImage(
                    //                     imagePath, fileName);
                    //             log('captured device image during activity: $filePath');
                    //             log('generated uid: $fileName');
                    //             if (context.mounted) {
                    //               ref.read(deviceController).s3imageUpload(
                    //                   ref,
                    //                   context,
                    //                   filePath,
                    //                   firstOrSecondDevice,
                    //                   fileName,
                    //                   getActivity());
                    //             }
                    //             var luminareData = {
                    //               "deviceImage": imagePath,
                    //               "landmark": landMark
                    //             };
                    //             var gwdata = {
                    //               "deviceImage": imagePath,
                    //               "location": landMark
                    //             };

                    //             //installation
                    //             if (firstOrSecondDevice == 1) {
                    //               //addLamp
                    //               if (clickeventIsFor == "addLamp" ||
                    //                   clickeventIsFor == "recordExistingLamp" ||
                    //                   clickeventIsFor ==
                    //                       "addLampInMaintenance") {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .lampInstallation(ref, context,
                    //                           luminareData, clickeventIsFor);
                    //                 }
                    //               } else {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .deviceInstallation(
                    //                           ref,
                    //                           context,
                    //                           deviceType == "ILM" ||
                    //                                   deviceType ==
                    //                                       "LUMINODE" ||
                    //                                   deviceType == 'ILM-4G' ||
                    //                                   lampAssetType == "LAMP"
                    //                               ? luminareData
                    //                               : gwdata,
                    //                           clickeventIsFor);
                    //                 }
                    //               }
                    //               //replace
                    //             } else if (firstOrSecondDevice == 2) {
                    //               if (clickeventIsFor == "lampOnlyReplace") {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .lampOnlyReplace(
                    //                           ref, context, luminareData);
                    //                 }
                    //               } else if (clickeventIsFor ==
                    //                   "lamp+ilmReplace") {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .lampAndILMReplace(
                    //                           ref, context, luminareData);
                    //                 }
                    //               } else {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .deviceReplace(
                    //                           ref,
                    //                           context,
                    //                           deviceType == "ILM" ||
                    //                                   deviceType ==
                    //                                       "LUMINODE" ||
                    //                                   deviceType == 'ILM-4G'
                    //                               ? luminareData
                    //                               : gwdata);
                    //                 }
                    //               }
                    //               //remove
                    //             } else {
                    //               //removeLamp
                    //               if (clickeventIsFor == "removeLamp") {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .lampRemove(ref, context, {});
                    //                 }
                    //               } else {
                    //                 if (context.mounted) {
                    //                   await ref
                    //                       .read(deviceController)
                    //                       .deviceRemove(ref, context, {});
                    //                 }
                    //               }
                    //             }
                    //             // }
                    //           } else {
                    //             if (context.mounted) {
                    //               await snackBar(
                    //                   context,
                    //                   ErrorMessages.offlineErrorTitle,
                    //                   ErrorMessages.offlineErrorMessage);
                    //             }
                    //           }
                    //         });
                    //       }
                    //     : null,
                    onLongPress: null, // Disable long press
                  ),
                ),
              ),
            ],
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: SizedBox(
              // color: Theme.of(context).canvasColor,
              width: MediaQuery.of(context).size.width / 1,
              child: Center(
                child: Text(
                  ref
                      .read(deviceController)
                      .getTitleBasedOnActivity(clickeventIsFor),
                  style: const TextStyle(
                      color: Color.fromARGB(248, 32, 61, 78), fontSize: 13),
                ),
              ),
            ),
            backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
          ),
          body: ConnectivityBanner(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context)
                        .viewInsets
                        .bottom), // Push content up when keyboard appears

                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: widget.imagePaths.length > 1
                          ? Column(
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 1.85,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: widget.imagePaths.length,
                                    onPageChanged: (index) =>
                                        setState(() => _currentPage = index),
                                    itemBuilder: (context, index) {
                                      return Image.file(
                                          File(widget.imagePaths[index]),
                                          fit: BoxFit.cover);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildDotIndicator(),
                              ],
                            )
                          : Container(
                              color:
                                  Theme.of(context).tabBarTheme.indicatorColor,
                              height: MediaQuery.of(context).size.height / 1.85,
                              child: Image.file(File(widget.imagePaths[0]))),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 15.0, right: 5.0, left: 5.0),
                      child: Column(
                        children: [
                          if (clickeventIsFor == 'ebMeterReplace')
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: oldMeterReadingValue,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    style: TextStyle(
                                        fontSize: 12,
                                        overflow: TextOverflow.clip,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    decoration: InputDecoration(
                                        labelText: 'Old Meter Reading',
                                        labelStyle: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                          fontSize: 13,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        counterText: '',
                                        prefixIcon: Transform.scale(
                                          scale: 0.5,
                                          child:
                                              Image.file(Assets.meterReading),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(16.0),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.20),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  248, 64, 124, 161),
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        )),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: newMeterReadingValue,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    style: TextStyle(
                                        fontSize: 12,
                                        overflow: TextOverflow.clip,
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    decoration: InputDecoration(
                                        labelText: 'New Meter Reading',
                                        labelStyle: TextStyle(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                          fontSize: 13,
                                        ),
                                        counterText: '',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.always,
                                        prefixIcon: Transform.scale(
                                          scale: 0.5,
                                          child:
                                              Image.file(Assets.meterReading),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(16.0),
                                        filled: true,
                                        fillColor: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.20),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: const BorderSide(
                                              color: Color.fromARGB(
                                                  248, 64, 124, 161),
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          if (clickeventIsFor == 'ebMeterReplace')
                            const SizedBox(
                              height: 8,
                            ),
                          AnimatedTextField(
                            animationType: Animationtype.typer,
                            keyboardType: TextInputType
                                .visiblePassword, // to remove emoji from the keyboard
                            maxLength: 100,
                            controller: locationAddress,
                            hintTexts: const [
                              'Provide additional landmark information if any',
                            ],
                            style: TextStyle(
                                color: Theme.of(context).secondaryHeaderColor),
                            hintTextStyle: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .secondaryHeaderColor
                                    .withValues(alpha: 0.8)),

                            decoration: InputDecoration(
                                counterText: '',
                                prefixIcon: Icon(Icons.location_on_outlined,
                                    color: Theme.of(context)
                                        .secondaryHeaderColor
                                        .withValues(alpha: 0.8)),
                                contentPadding: const EdgeInsets.all(16.0),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.20),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                      color: Color.fromARGB(248, 64, 124, 161),
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.0),
                                  borderRadius: BorderRadius.circular(8.0),
                                )),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          !isLocationFetched && clickeventIsFor == "1"
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 15.0,
                                      width: 15.0,
                                      child: CircularProgressIndicator(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 7,
                                    ),
                                    Text(
                                      'Fetching Location...',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).primaryColor),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    widget.landMark.isNotEmpty
                                        ? Text(
                                            widget.landMark,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold),
                                          )
                                        : Container(),
                                    const SizedBox(
                                      height: 2,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        const Text(
                                          'Latitude : ',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          deviceType == "GW"
                                              ? ccmsLat.isEmpty
                                                  ? (hubLat.isEmpty
                                                      ? fetchedLat
                                                      : hubLat)
                                                  : ccmsLat
                                              : poleLat.isEmpty
                                                  ? (lpLat.isEmpty
                                                      ? fetchedLat
                                                      : lpLat)
                                                  : poleLat,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text(
                                          'Longitude : ',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          deviceType == "GW"
                                              ? ccmsLong.isEmpty
                                                  ? (hubLong.isEmpty
                                                      ? fetchedLong
                                                      : hubLong)
                                                  : ccmsLong
                                              : poleLong.isEmpty
                                                  ? (lpLong.isEmpty
                                                      ? fetchedLong
                                                      : lpLong)
                                                  : poleLong,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )
                                  ],
                                )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
