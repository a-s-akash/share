import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';

import 'utils/asset_folder.dart';

final qrController = ChangeNotifierProvider<QRProvider>((ref) => QRProvider());
final qrController2 = ChangeNotifierProvider<QRProvider>((ref) => QRProvider());

class QRProvider extends ChangeNotifier {
  QRViewController? qrViewController;
  void setControllerForQr(QRViewController controller) {
    qrViewController = controller;
    notifyListeners();
  }
}

class ScanQRWithCustomScreen extends ConsumerWidget {
  int firstOrSecond;
  String clickEventIsFor;
  ScanQRWithCustomScreen(
      {Key? key, required this.firstOrSecond, required this.clickEventIsFor})
      : super(key: key);
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
// dynamic x = ref.watch(isSecondTime);
    bool secondQrCondition = firstOrSecond != 1 ||
        clickEventIsFor == "scanLampViaILM" ||
        clickEventIsFor == "addILM";
    var qrViewController = (secondQrCondition)
        ? ref.watch(qrController2).qrViewController
        : ref.watch(qrController).qrViewController;
    log("clickEvent : $clickEventIsFor, firstOrsec :  $firstOrSecond");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isSecondTime.notifier).state = secondQrCondition ? true : false;
    });
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;
    String lampOrILMscanForReplace =
        ref.watch(deviceController).lampOrILMscanForReplace;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(isSecondTime.notifier).state =
              secondQrCondition ? false : true;
        });
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).secondaryHeaderColor,
              height: MediaQuery.of(context).size.height / 2.70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => showGifDialog(context),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: Icon(
                                  Icons.info,
                                  size: 25,
                                  color: Theme.of(context).canvasColor,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: Image.file(Assets.ilmOutsideGif)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        (clickEventIsFor == "lampOnlyReplace" ||
                                (clickEventIsFor == "lamp+ilmReplace" &&
                                    lampOrILMscanForReplace == "lamp"))
                            ? const Padding(
                                padding: EdgeInsets.only(top: 40.0, left: 8),
                                child: SizedBox(
                                  width: 100,
                                  height: 40,
                                ),
                              )
                            : GestureDetector(
                                onTap: () async {
                                  await qrViewController!.toggleFlash();
                                },
                                child: Text(
                                  "FLASH",
                                  style: TextStyle(
                                      color: Theme.of(context).canvasColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                        (clickEventIsFor == "lampOnlyReplace" ||
                                (clickEventIsFor == "lamp+ilmReplace" &&
                                    lampOrILMscanForReplace == "lamp"))
                            ? GestureDetector(
                                onTap: () {
                                  ref
                                      .read(secondQrCondition
                                          ? qrController2
                                          : qrController)
                                      .setControllerForQr(qrViewController!);
                                  ref.read(deviceController).scanDevice(ref,
                                      context, firstOrSecond, clickEventIsFor,
                                      scannedResponse: "");
                                  qrViewController.pauseCamera();
                                },
                                child: Text(
                                  "SKIP",
                                  style: TextStyle(
                                      color: Theme.of(context).canvasColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    ref.read(isSecondTime.notifier).state =
                                        secondQrCondition ? false : true;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 15.0),
                                  child: Text(
                                    "CANCEL",
                                    style: TextStyle(
                                        color: Theme.of(context).canvasColor,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.file(
                          height: 165, width: 140, Assets.panelscannerImage),
                      Image.file(
                          height: 165, width: 140, Assets.ilmScannerImage2),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: (QRViewController qrview) {
                  ref
                      .read(secondQrCondition ? qrController2 : qrController)
                      .setControllerForQr(qrview);
                  qrview.scannedDataStream.listen((scanData) async {
                    qrview.pauseCamera();
                    // print('qr view after pause $qrview');
                    if (clickEventIsFor == 'scanLampViaILM' ||
                        clickEventIsFor == "addLampInMaintenance") {
                      if (context.mounted) {
                        ref.read(deviceController).scanLamp(
                            ref, context, firstOrSecond, clickEventIsFor,
                            scannedResponse: scanData.code.toString());
                      }
                    } else if (clickEventIsFor == "addLamp") {
                      if (context.mounted) {
                        ref.read(deviceController).scanLampAsset(
                            ref, context, firstOrSecond, clickEventIsFor,
                            scannedResponse: scanData.code.toString());
                      }
                    } else {
                      if (clickEventIsFor == "ebMeterReplace") {
                        bool isValid = await ref
                            .read(deviceController)
                            .validateEbMeter(
                                ref, context, scanData.code.toString().trim());
                        if (isValid) {
                          if (context.mounted) {
                            ref.read(deviceController).scanDevice(
                                ref, context, firstOrSecond, clickEventIsFor,
                                scannedResponse:
                                    scanData.code.toString().trim());
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ref.read(deviceController).scanDevice(
                              ref, context, firstOrSecond, clickEventIsFor,
                              scannedResponse: scanData.code.toString().trim());
                        }
                      }
                    }
                  });
                },
                overlay: QrScannerOverlayShape(
                    borderColor: Theme.of(context).hintColor,
                    borderRadius: 0,
                    borderLength: 30,
                    borderWidth: 7,
                    cutOutSize: scanArea),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
