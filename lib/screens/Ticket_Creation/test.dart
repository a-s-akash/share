import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FunctionStreamer extends StatefulWidget {
  @override
  _FunctionStreamerState createState() => _FunctionStreamerState();
}

class _FunctionStreamerState extends State<FunctionStreamer> {
  final List<String> _receivedItems = [];

  void _startCloudFunctionStream() async {
    // Replace with your actual deployed Firebase Function URL
    final url =
        Uri.parse('https://streamfirestoredata-nz6bd4kzlq-uc.a.run.app');

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      // This is the crucial header that tells the v2 function to accept streaming
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({"data": {}}); // Your function payload wrapper

    final response = await http.Client().send(request);

    // Listen to the stream byte-by-byte, converting to UTF-8 lines
    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      if (line.startsWith('data:')) {
        // Clean up the SSE protocol "data: " prefix
        final jsonString = line.replaceFirst('data:', '').trim();
        final parsedData = jsonDecode(jsonString);
        log(jsonString);

        setState(() {
          // Pull out whatever your function chunk structure is
          _receivedItems.add(parsedData['ticket_id'] ?? 'Processing...');
        });
      }
    }, onDone: () => print("Stream completed!"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cloud Function Stream")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startCloudFunctionStream,
            child: Text("Fetch & Stream via Function"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _receivedItems.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_receivedItems[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
