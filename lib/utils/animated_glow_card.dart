import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

// Provide the TickerProvider
final tickerProvider = Provider<TickerProvider>((ref) {
  return MyTickerProvider();
});

// Provide the AnimationController
final animationControllerProvider = Provider<AnimationController>((ref) {
  final ticker = ref.watch(tickerProvider);
  final controller = AnimationController(
    vsync: ticker,
    duration: const Duration(milliseconds: 1000),
  );

  controller.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      controller.reverse();
    } else if (status == AnimationStatus.dismissed) {
      controller.forward();
    }
  });

  controller.forward();
  ref.onDispose(controller.dispose);
  return controller;
});
