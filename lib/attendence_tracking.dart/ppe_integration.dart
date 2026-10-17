import 'dart:io';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';

class PpeTakePictureScreen extends ConsumerStatefulWidget {
  const PpeTakePictureScreen({super.key});

  @override
  ConsumerState<PpeTakePictureScreen> createState() =>
      _PpeTakePictureScreenState();
}

class _PpeTakePictureScreenState extends ConsumerState<PpeTakePictureScreen> {
  String? _capturedImagePath;
  late ValueNotifier<SensorConfig> _sensorConfig;

  @override
  void initState() {
    super.initState();
    _sensorConfig = ValueNotifier(
      SensorConfig.single(
        sensor: Sensor.position(SensorPosition.back),
        flashMode: FlashMode.none,
        aspectRatio: CameraAspectRatios.ratio_4_3,
        zoom: 0.0,
      ),
    );
  }

  Future<String> _getImagePath(Sensor sensor) async {
    final Directory extDir = await getTemporaryDirectory();
    final Directory testDir =
        await Directory('${extDir.path}/camerawesome').create(recursive: true);
    return '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async => false, // disable back
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Take your Full Picture',
              style: TextStyle(color: Theme.of(context).canvasColor),
            ),
            backgroundColor: Theme.of(context).secondaryHeaderColor,
            actions: [
              IconButton(
                onPressed: () => logoutPop(context, ref),
                icon: Icon(
                  Icons.logout_outlined,
                  color: Theme.of(context).canvasColor,
                ),
              ),
            ],
          ),
          body: _capturedImagePath == null
              ? CameraAwesomeBuilder.awesome(
                  sensorConfig: _sensorConfig.value,
                  saveConfig: SaveConfig.photo(
                    pathBuilder: (sensors) async {
                      final path = await _getImagePath(sensors.first);
                      return SingleCaptureRequest(path, sensors.first);
                    },
                  ),
                  onMediaCaptureEvent: (event) {
                    if (event.status == MediaCaptureStatus.success &&
                        event.isPicture) {
                      final path = event.captureRequest.when(
                        single: (single) => single.file?.path,
                        multiple: (_) => null,
                      );
                      if (path != null) {
                        setState(() {
                          _capturedImagePath = path;
                        });
                      }
                    }
                  },
                  previewFit: CameraPreviewFit.contain,
                  previewAlignment: Alignment.center,
                  enablePhysicalButton: true,
                  // aspectRatio: CameraAspectRatios.ratio_4_3,
                  // Customize the UI to hide flash and aspect ratio buttons
                  theme: AwesomeTheme(
                    bottomActionsBackgroundColor: Colors.transparent,
                    buttonTheme: AwesomeButtonTheme(
                      iconSize: 25,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  bottomActionsBuilder: (state) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AwesomeCameraSwitchButton(
                            state: state,
                            iconBuilder: () => const Icon(
                              Icons.cameraswitch,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          AwesomeCaptureButton(state: state),
                          AwesomeFlashButton(state: state),
                        ],
                      ),
                    );
                  },
                  // Hide top buttons (flash, aspect ratio, etc.)
                  topActionsBuilder: (state) => Container(),
                  // topActionsBuilder: (state) {
                  //   if (state is PhotoCameraState) {
                  //     return Padding(
                  //       padding: const EdgeInsets.only(
                  //           top: 20.0), // top instead of bottom
                  //       child: Row(
                  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  //         children: [
                  //           AwesomeFlashButton(state: state),
                  //           AwesomeAspectRatioButton(state: state),
                  //         ],
                  //       ),
                  //     );
                  //   } else {
                  //     return const SizedBox.shrink();
                  //   }
                  // },
                  // Disable middle buttons that may appear
                  middleContentBuilder: (state) => Container(),
                )
              : _buildPreview(context),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Image.file(
              File(_capturedImagePath!),
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "retake",
                  backgroundColor: Theme.of(context).cardColor,
                  child: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _capturedImagePath = null;
                    });
                  },
                ),
                const SizedBox(width: 35),
                FloatingActionButton(
                  heroTag: "confirm",
                  backgroundColor: Theme.of(context).cardColor,
                  child: const Icon(Icons.check),
                  onPressed: () async {
                    EasyLoading.show(status: 'Uploading...');
                    await ref
                        .read(userTrackingController)
                        .ppeImageUpload(ref, context, _capturedImagePath);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
