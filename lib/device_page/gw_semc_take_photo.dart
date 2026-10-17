import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart' as loc;
import '../survey/background_connectivity_monitoring.dart';
import '../survey/survey_controller.dart';
import '../utils/asset_folder.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import '../utils/error_messages.dart';
import 'device_controller.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:schnell_luminator/device_page/take_photo.dart';

class GwSemcCaptureThreeImagesScreen extends ConsumerStatefulWidget {
  final String clickeventIsFor;
  final int requiredImageCount;
  const GwSemcCaptureThreeImagesScreen(
      {super.key, required this.clickeventIsFor, this.requiredImageCount = 3});

  @override
  ConsumerState<GwSemcCaptureThreeImagesScreen> createState() =>
      _GwSemcCaptureThreeImagesScreenState();
}

class _GwSemcCaptureThreeImagesScreenState
    extends ConsumerState<GwSemcCaptureThreeImagesScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  late final List<XFile?> _capturedImages;
  final Set<int> _capturedIndexes = <int>{};
  int _nextImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _capturedImages = List<XFile?>.filled(widget.requiredImageCount, null);
    _initializeCamera();
    ref.read(deviceController).getTitleBasedOnActivity(widget.clickeventIsFor);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final controller =
          CameraController(_cameras.first, ResolutionPreset.medium);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      log('Camera init error: $e');
    }
  }

  Future<void> _captureImageAtIndex(int index) async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    _capturedIndexes.add(index);
    try {
      final photo = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImages[index] = photo;
        int next = _capturedImages.indexWhere((img) => img == null);
        _nextImageIndex = next == -1 ? widget.requiredImageCount : next;
      });
    } catch (e) {
      log('Capture error: $e');
    }
  }

  Future<void> _releaseCamera({bool fromDispose = false}) async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      if (!fromDispose && mounted) {
        setState(() => _isCameraInitialized = false);
      } else {
        _isCameraInitialized = false;
      }
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream().catchError((_) {});
      }
      if (!fromDispose) {
        await controller.dispose();
      } else {
        controller.dispose();
      }
    } catch (e) {
      log('Camera release error: $e');
    } finally {
      _cameraController = null;
    }
  }

  @override
  void dispose() {
    _releaseCamera(fromDispose: true);
    super.dispose();
  }

  Widget _buildCurrentReferenceImage(String deviceType, String hubOrCcms) {
    final bool isGwOrSemc =
        ((deviceType == 'GW' && hubOrCcms == 'ccms') || (deviceType == 'SEMC'));
    final double carouselHeight = isGwOrSemc ? 400 : 250;
    final List<File> samples = isGwOrSemc
        ? [
            Assets.panelSampleImage1,
            Assets.panelSampleImage2,
            Assets.panelSampleImage3
          ]
        : [
            Assets.lampSampleImages1,
            Assets.lampSampleImages2,
          ];

    final List<String> titles = isGwOrSemc
        ? [
            "SLC installation photo",
            "Authority energy meter data with service connection details",
            "Panel earthing photo"
          ]
        : [
            "Lamp installation photo",
            "Asset identification photo",
          ];

    final File current = samples[_nextImageIndex.clamp(0, samples.length - 1)];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => Dialog(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: carouselHeight,
                    width: double.maxFinite,
                    child: FlutterCarousel.builder(
                      options: FlutterCarouselOptions(
                        height: carouselHeight,
                        showIndicator: true,
                        slideIndicator: CircularSlideIndicator(
                          slideIndicatorOptions: SlideIndicatorOptions(
                            currentIndicatorColor:
                                Theme.of(context).primaryColor,
                            indicatorRadius: 5,
                          ),
                        ),
                      ),
                      itemCount: samples.length,
                      itemBuilder:
                          (BuildContext context, int index, int itemCount) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              Text(
                                titles[index],
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Image.file(samples[index],
                                    fit: BoxFit.contain),
                              ),
                              const SizedBox(height: 35),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Icon(
              Icons.info,
              size: 25,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: SizedBox(
              height: 30,
              width: 30,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(current, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(int index) {
    final image = _capturedImages[index];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Colors.black12,
      ),
      child: Stack(
        children: [
          if (image != null)
            Positioned.fill(
              child: Image.file(File(image.path), fit: BoxFit.cover),
            )
          else
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _captureImageAtIndex(index),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          if (image != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (ctx) => Dialog(
                      child: GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Image.file(File(image.path), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.visibility,
                      color: Colors.white, size: 17),
                ),
              ),
            ),
          if (image != null)
            Positioned(
              top: 34,
              right: 4,
              child: GestureDetector(
                onTap: () => _captureImageAtIndex(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 17),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _proceed() async {
    String poleLocation = ref.watch(deviceController).poleLocation;
    String lpLandmark = ref.watch(deviceController).lpLandmark;
    String firstDeviceType = ref.watch(deviceController).firstDeviceType;
    String ccmsLandmark = ref.watch(deviceController).ccmsLandmark;
    String hubLandmark = ref.watch(deviceController).hubLandmark;
    String newLmpType = ref.watch(deviceController).newLmpType;
    String newLmpWattage = ref.watch(deviceController).newLmpWattage;
    String finalNewLmpName = ref.watch(deviceController).finalNewLmpName;
    EasyLoading.show(status: 'loading...', dismissOnTap: false);
    try {
      await _releaseCamera();
      if (!mounted) return;

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
            landMark =
                await ref.read(surveyController).getUserLocation(lat, long);
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
            landMark =
                await ref.read(surveyController).getUserLocation(lat, long);
          } else {
            landMark = lpLandmark;
          }
        } else {
          landMark = poleLocation;
        }
      }
      if (!mounted) return;
      EasyLoading.dismiss();
      // _controller.pausePreview();
      log('values for $finalNewLmpName: $newLmpType and $newLmpWattage');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(
            imagePaths: _capturedImages
                .where((img) => img != null)
                .map((img) => img!.path)
                .toList(),
            landMark: landMark,
          ),
        ),
      );
    } catch (e) {
      EasyLoading.dismiss();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            homeRoute, (Route<dynamic> route) => false);
      }
      if (context.mounted) {
        await snackBar(context, ErrorMessages.networkErrorTitle,
            ErrorMessages.networkErrorMessage);
      }

      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = ref.watch(deviceController).isButtonEnabled;
    final deviceType = ref.watch(deviceController).firstDeviceType;
    final hubOrCcms = ref.watch(deviceController).assetType;
    final allCaptured = _capturedImages.every((img) => img != null);

    final bool isGwOrSemc =
        ((deviceType == 'GW' && hubOrCcms == 'ccms') || (deviceType == 'SEMC'));
    final List<String> titles = isGwOrSemc
        ? [
            "SLC installation photo",
            "Authority energy meter data with service connection details",
            "Panel earthing photo"
          ]
        : [
            "Lamp installation photo",
            "Asset identification photo",
          ];

    return PopScope(
      canPop: true,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).cardColor,
              ),
              onPressed: () {
                Navigator.pop(context);
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
              "TAKE PICTURE",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
            actions: [
              _buildCurrentReferenceImage(deviceType, hubOrCcms),
            ],
          ),
          body: _isCameraInitialized && _cameraController != null
              ? ConnectivityBanner(
                  child: Column(
                    children: [
                      Expanded(
                        child: CameraPreview(_cameraController!),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            widget.requiredImageCount,
                            (index) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: _buildImageGrid(index),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      titles[index.clamp(0, titles.length - 1)],
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor:
                                  const Color.fromARGB(248, 54, 89, 109),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              fixedSize: const Size(54, 54),
                            ),
                            onPressed: allCaptured && isButtonEnabled
                                ? _proceed
                                : null,
                            child: const Icon(Icons.send, size: 35),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
