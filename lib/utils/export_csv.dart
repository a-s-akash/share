import 'dart:convert';
import 'dart:js_interop';

import 'package:csv/csv.dart';
import 'package:web/web.dart' as web;

Future<void> exportCsv(List<List<dynamic>> rows, String fileName) async {
  final csvData = const ListToCsvConverter().convert(rows);

  final bytes = utf8.encode('\uFEFF$csvData');

  final blob = web.Blob([bytes.toJS].toJS);

  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;

  anchor.click();

  web.URL.revokeObjectURL(url);
}
