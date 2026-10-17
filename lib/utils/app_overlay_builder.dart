import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

Widget appOverlayBuilder(BuildContext context, Widget? child) {
  final Widget inner = EasyLoading.init()(context, child);
  return ValueListenableBuilder<bool>(
    valueListenable: sessionExpiredNotifier,
    builder: (context, expired, _) {
      if (!expired) return inner;
      return Stack(
        children: [
          inner,
          Positioned(
            top: 10,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).tabBarTheme.indicatorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        color: Theme.of(context).canvasColor, size: 20),
                    const SizedBox(width: 15),
                    Text(
                      'Session Expired',
                      style: TextStyle(
                        color: Theme.of(context).canvasColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
