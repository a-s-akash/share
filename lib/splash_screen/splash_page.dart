import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/env.dart';
import 'package:schnell_luminator/splash_screen/splash_controller.dart';
import 'package:schnell_luminator/utils/asset_folder.dart';
import 'package:schnell_luminator/utils/constants.dart';
import '../utils/custom_loading.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Tween<double> scaleTween = Tween<double>(begin: 0.05, end: 0.50);
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: FutureBuilder(
          future: ref.read(splashController).checkAppVersion(context, ref),
          builder: (context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {}
            return SafeArea(
              child: Scaffold(
                body: Column(
                  children: [
                    SizedBox(
                      height: height / 15,
                    ),
                    TweenAnimationBuilder(
                      tween: scaleTween,
                      duration: const Duration(milliseconds: 10),
                      builder: (ctx, double scale, child) {
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Image.asset(logoImage),
                    ),
                    SizedBox(
                      height: height / 60,
                    ),
                    Text(appName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(
                      height: height / 10,
                    ),
                    spinkit,
                    Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          baseURL.contains('iotpro')
                              ? 'Version: $appVersion - Beta'
                              : 'Version: $appVersion',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        )),
                    StreamBuilder<double>(
                      stream: Assets.progressStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final progress = snapshot.data!;

                          return Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 70.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Installing Updates',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
