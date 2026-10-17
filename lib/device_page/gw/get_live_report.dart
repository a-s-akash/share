import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../utils/dialog_box.dart';
import '../../utils/error_messages.dart';
import 'panel_actions_controller.dart';

void showLiveDataDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: const LiveDataReport(),
      );
    },
  );
}

class LiveDataReport extends ConsumerWidget {
  const LiveDataReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryData = ref.watch(panelController).telemetryData;
    String currentTimestamp =
        DateFormat("dd-MM-yyyy HH:mm:ss").format(DateTime.now());
    DateTime? receivedTime = telemetryData?.systime != null
        ? DateTime.fromMillisecondsSinceEpoch((telemetryData!.systime) * 1000)
        : null;

    String formattedTime = receivedTime != null
        ? DateFormat("dd-MM-yyyy, HH:mm:ss").format(receivedTime)
        : "-";

    String mode = telemetryData?.relayStatus != null
        ? (telemetryData!.relayStatus) > 1
            ? 'Manual'
            : 'Auto'
        : '-';
    String rVolt = telemetryData?.rv != null
        ? ((telemetryData!.rv) / 1000).toStringAsFixed(2)
        : '-';

    String yVolt = telemetryData?.yv != null
        ? ((telemetryData!.yv) / 1000).toStringAsFixed(2)
        : '-';

    String bVolt = telemetryData?.bv != null
        ? ((telemetryData!.bv) / 1000).toStringAsFixed(2)
        : '-';

    String rCurr = telemetryData?.ri != null
        ? ((telemetryData!.ri) / 1000).toStringAsFixed(2)
        : '-';
    String bCurr = telemetryData?.bi != null
        ? ((telemetryData!.bi) / 1000).toStringAsFixed(2)
        : '-';
    String yCurr = telemetryData?.yi != null
        ? ((telemetryData!.yi) / 1000).toStringAsFixed(2)
        : '-';

    String rPow = telemetryData?.rkw != null
        ? ((telemetryData!.rkw) / 1000).toStringAsFixed(2)
        : '-';
    String bPow = telemetryData?.bkw != null
        ? ((telemetryData!.bkw) / 1000).toStringAsFixed(2)
        : '-';
    String yPow = telemetryData?.ykw != null
        ? ((telemetryData!.ykw) / 1000).toStringAsFixed(2)
        : '-';

    String relayStatus = "";
    if (telemetryData?.relayStatus != null) {
      if (telemetryData!.relayStatus == 0) {
        relayStatus = 'off';
      } else if (telemetryData!.relayStatus == 1) {
        relayStatus = 'On';
      } else if (telemetryData!.relayStatus == 2) {
        if (double.parse(rPow) >= 0.01 ||
            double.parse(yPow) >= 0.01 ||
            double.parse(bPow) >= 0.01) {
          relayStatus = 'BP-On';
        } else {
          relayStatus = 'BP-Off';
        }
      } else {
        relayStatus = 'Unknown';
      }
    }

    String? onTime = telemetryData?.tbtOpen != null
        ? ((telemetryData!.tbtClose / 3600) - (telemetryData!.tbtClose / 3600))
            .toStringAsFixed(2)
        : null;

    String decodeFault(int faultValue, int pktValue) {
      List<String> faultTypes = [
        'RVL',
        'RVH',
        'YVL',
        'YVH',
        'BVL',
        'BVH',
        'RCL',
        'RCH',
        'YCL',
        'YCH',
        'BCL',
        'BCH',
        'RPL',
        'RPH',
        'YPL',
        'YPH',
        'BPL',
        'BPH',
        'MTR',
        'RTC',
        'RIC',
        'YIC',
        'BIC',
        'ROC',
        'YOC',
        'BOC',
        'TPR',
        'RCF',
        'YCF',
        'BCF',
        'MCB',
        'BPS'
      ];

      String faultStr = '';
      for (int faultCode = 0; faultCode <= 31; faultCode++) {
        if ((faultValue & (1 << faultCode)) != 0) {
          faultStr += '${faultTypes[faultCode]} / ';
        }
      }

      if (faultStr.isNotEmpty) {
        faultStr = faultStr.substring(0, faultStr.length - 3);
      }

      if (pktValue == 9 && faultStr == 'MTR') {
        return '';
      }

      return faultStr;
    }

    String? fault = telemetryData?.fault != null && telemetryData?.pkt != null
        ? decodeFault(telemetryData!.fault, telemetryData!.fault)
        : '-';

    return Container(
      height: MediaQuery.of(context).size.height / 1.18,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .dialogTheme
                    .backgroundColor!
                    .withValues(alpha: 0.6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Live Data Report",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      // GestureDetector(
                      //     onTap: () async {
                      //       EasyLoading.show(
                      //         status: '',
                      //         dismissOnTap: false,
                      //       );
                      //       await ref
                      //           .read(panelController)
                      //           .updateTelemetryData(ref, context);
                      //     },
                      //     child: Material(
                      //       color: Colors.transparent,
                      //       child: InkWell(
                      //         // onTap: onTap,
                      //         borderRadius: BorderRadius.circular(50),
                      //         child: Container(
                      //           width: 36,
                      //           height: 36,
                      //           decoration: BoxDecoration(
                      //             color: Theme.of(context)
                      //                 .primaryColor
                      //                 .withOpacity(0.08),
                      //             shape: BoxShape.circle,
                      //           ),
                      //           child: Icon(
                      //             Icons.refresh_rounded,
                      //             size: 21,
                      //             color: Theme.of(context).primaryColor,
                      //           ),
                      //         ),
                      //       ),
                      //     )),
                      // const SizedBox(width: 10),
                      GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              // onTap: onTap,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 21,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ],
              )),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .dialogTheme
                    .backgroundColor!
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Timestamp Text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Data Last Received At",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentTimestamp,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () async {
                      // EasyLoading.show(
                      //   status: '',
                      //   dismissOnTap: false,
                      // );
                      await successTick(
                          context, ErrorMessages.dataRequestedSuccessfully);
                      await ref
                          .read(panelController)
                          .updateTelemetryData(ref, context);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 21,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 10,
            children: [
              // InfoCard(title: "Timestamp", value: currentTimestamp),
              // InfoCard(title: "Received Time", value: formattedTime),
              InfoCard(title: "Mode", value: mode),
              InfoCard(title: "Relay Status", value: relayStatus),
              InfoCard(title: "R-Volt (V)", value: rVolt),
              InfoCard(title: "Y-Volt (V)", value: yVolt),
              InfoCard(title: "B-Volt (V)", value: bVolt),
              InfoCard(title: "R-Pow (kW)", value: rPow),
              InfoCard(title: "B-Pow (kW)", value: bPow),
              InfoCard(title: "Y-Pow (kW)", value: yPow),
              InfoCard(title: "R-Cur (A)", value: rCurr),
              InfoCard(title: "Y-Cur (A)", value: yCurr),
              InfoCard(title: "B-Cur (A)", value: bCurr),
              InfoCard(title: "On Time (hr)", value: onTime.toString()),
              InfoCard(
                  title: "Alert",
                  value: fault.toString().isEmpty ? '-' : fault.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .dialogTheme
              .backgroundColor!
              .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.contain,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
