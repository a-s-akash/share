import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/qr_scan_online.dart';
import 'package:schnell_luminator/survey/background_connectivity_monitoring.dart';
import '../device_controller.dart';
import '../take_photo.dart';

class ScanSelectionPage extends ConsumerWidget {
  const ScanSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var qrViewController = ref
        .watch(ref.watch(isSecondTime) ? qrController2 : qrController)
        .qrViewController;
    return SafeArea(
        child: PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop && qrViewController != null) {
                qrViewController.resumeCamera();
              }
            },
            child: Scaffold(
                appBar: AppBar(
                  leading: Builder(builder: (BuildContext context) {
                    return IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () {
                        // Navigator.of(context).pushNamedAndRemoveUntil(
                        //     homeRoute, (route) => false);
                        Navigator.of(context).pop();
                        if (qrViewController != null) {
                          qrViewController.resumeCamera();
                        }
                      },
                    );
                  }),
                  backgroundColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.19),
                  elevation: 0.0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color,
                    fontSize: 18.0,
                  ),
                  title: Text(
                    "SCAN PAGE",
                    style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                body: ConnectivityBanner(
                  child: Column(children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 3,
                    ),
                    _buildButton(
                      context,
                      onTap: () async {
                        await ref
                            .read(deviceController)
                            .clickEventIsFor("scanLampViaILM");
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ScanQRWithCustomScreen(
                                firstOrSecond: 1,
                                clickEventIsFor: "scanLampViaILM"),
                          ));
                        }
                      },
                      text: "Scan a Lamp",
                      bgcolor: Theme.of(context).hintColor,
                      iccolor: Colors.transparent.withValues(alpha: 0.3),
                      icon: Icons.light,
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    _buildButton(
                      context,
                      onTap: () async {
                        await ref
                            .read(deviceController)
                            .clickEventIsFor("withoutLampViaILM");
                        if (context.mounted) {
                          takePicture(context, ref);
                        }
                      },
                      text: "Install without a lamp",
                      bgcolor: Theme.of(context).primaryColor,
                      iccolor: Colors.transparent.withValues(alpha: 0.3),
                      icon: Icons.location_searching_outlined,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                  ]),
                ))));
  }

  Widget _buildButton(BuildContext context,
      {VoidCallback? onTap,
      required String text,
      Color? bgcolor,
      Color? iccolor,
      required IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Material(
        elevation: 5,
        color: bgcolor,
        borderRadius: BorderRadius.circular(15.0),
        child: MaterialButton(
          height: 55,
          onPressed: onTap,
          child: Stack(alignment: Alignment.center, children: [
            Text(
              text,
              style:
                  TextStyle(color: Theme.of(context).canvasColor, fontSize: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration:
                      BoxDecoration(color: iccolor, shape: BoxShape.circle),
                  child: Icon(
                    icon,
                    color: Theme.of(context).canvasColor,
                  ),
                )
              ],
            )
          ]),
        ),
      ),
    );
  }

  Future<void> takePicture(context, ref) async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    String clickeventIsFor = ref.watch(deviceController).clickeventIsFor;

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
