import 'package:flutter/material.dart';

class ScrollIndicator extends StatefulWidget {
  final ScrollController controller;

  const ScrollIndicator({super.key, required this.controller});

  @override
  ScrollIndicatorState createState() => ScrollIndicatorState();
}

class ScrollIndicatorState extends State<ScrollIndicator> {
  final ValueNotifier<bool> directionNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasScrollNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  void _scrollListener() {
    if (widget.controller.offset >=
            widget.controller.position.maxScrollExtent &&
        !widget.controller.position.outOfRange) {
      directionNotifier.value = true;
    }
    if (widget.controller.offset <=
            widget.controller.position.minScrollExtent &&
        !widget.controller.position.outOfRange) {
      directionNotifier.value = false;
    }
  }

  void _checkScrollability() {
    if (!widget.controller.hasClients) return;
    hasScrollNotifier.value = widget.controller.position.maxScrollExtent > 0;
  }

  void _moveUp() {
    widget.controller.animateTo(
      widget.controller.position.minScrollExtent, // Scroll to top
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _moveDown() {
    widget.controller.animateTo(
      widget.controller.position.maxScrollExtent, // Scroll to bottom
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: hasScrollNotifier,
      builder: (context, hasScroll, child) {
        if (!hasScroll) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: directionNotifier,
          builder: (context, direction, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Visibility(
                  visible: direction,
                  maintainSize: false,
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).canvasColor,
                    mini: true,
                    onPressed: _moveUp,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: !direction,
                  maintainSize: false,
                  child: FloatingActionButton(
                    backgroundColor: Theme.of(context).canvasColor,
                    mini: true,
                    onPressed: _moveDown,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Icon(
                        Icons.chevron_left,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
