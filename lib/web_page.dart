import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Assistant extends StatefulWidget {
  const Assistant({super.key});

  @override
  State<Assistant> createState() => _AssistantState();
}

class _AssistantState extends State<Assistant> {
  late InAppWebViewController inAppWebViewController;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest:
                  URLRequest(url: WebUri("http://iotpro.io:9000/")),
              onWebViewCreated: (InAppWebViewController controller) {
                inAppWebViewController = controller;
              },
            )
          ],
        ),
      ),
    );
  }
}
