import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CustomAnimation extends EasyLoadingAnimation {
  CustomAnimation();

  @override
  Widget buildWidget(
    Widget child,
    AnimationController controller,
    AlignmentGeometry alignment,
  ) {
    return Opacity(
      opacity: controller.value,
      child: RotationTransition(
        turns: controller,
        child: child,
      ),
    );
  }
}

const spinkit = SpinKitThreeBounce(
  color: Color.fromARGB(248, 64, 124, 161),
  size: 30.0,
);

const loginLoader = SpinKitRing(
  color: Color.fromARGB(248, 64, 124, 161),
  size: 30.0,
);
