import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:citizen_complaints_list_web/firebase_setup/firbase_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class PeriodicTicketWatcher {
  PeriodicTicketWatcher({
    required this.customerId,
    required this.region,
    required this.start,
    required this.end,
    this.refreshInterval = const Duration(minutes: 55),
  }) {
    _outController = StreamController<List<Ticket>>.broadcast();
    _connect(); // open the first SSE connection immediately
    _timer = Timer.periodic(refreshInterval, (_) {
      debugPrint(
        '[TicketWatcher] Timer fired — refreshing SSE connection '
        '(every ${refreshInterval.inMinutes} min, server TTL ~5 min)',
      );
      _reconnect();
    });
  }

  final String customerId;
  final String region;
  final String start;
  final String end;

  final Duration refreshInterval;

  late final StreamController<List<Ticket>> _outController;
  late final Timer _timer;

  http.Client? _activeClient;

  List<Ticket>? _lastData;

  Stream<List<Ticket>> get stream => _outController.stream;

  void _connect() {
    if (_outController.isClosed) return;

    final client = http.Client();
    _activeClient = client;

    final uri = Uri.parse(fetchTicketUrl).replace(
      queryParameters: {
        'customerId': customerId,
        'region': region,
        'start': start,
        'end': end,
      },
    );

    client.send(http.Request('GET', uri)).then((response) {
      if (_outController.isClosed) {
        client.close();
        return;
      }

      if (response.statusCode != 200) {
        if (!_outController.isClosed) {
          _outController.addError(Exception('HTTP ${response.statusCode}'));
        }
        client.close();
        return;
      }

      final buffer = StringBuffer();

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (_outController.isClosed) return;

          if (line.startsWith('data:')) {
            buffer.write(line.substring(5).trim());
          } else if (line.isEmpty) {
            if (buffer.isEmpty) return;
            try {
              final jsonData = jsonDecode(buffer.toString());
              final tickets = (jsonData as List)
                  .map((e) => Ticket.fromJson(Map<String, dynamic>.from(e)))
                  .toList();
              _lastData = tickets; // cache for reconnect continuity
              _outController.add(tickets);
            } catch (e) {
              if (!_outController.isClosed) _outController.addError(e);
            }
            buffer.clear();
          }
        },
        onDone: () {
          client.close();
          if (_activeClient == client) _activeClient = null;
        },
        onError: (e) {
          if (!_outController.isClosed) _outController.addError(e);
          client.close();
          if (_activeClient == client) _activeClient = null;
        },
        cancelOnError: false,
      );
    }).catchError((e) {
      if (!_outController.isClosed) _outController.addError(e);
      client.close();
      if (_activeClient == client) _activeClient = null;
    });
  }

  void _reconnect() {
    _activeClient?.close();
    _activeClient = null;

    if (_lastData != null && !_outController.isClosed) {
      _outController.add(_lastData!);
    }

    _connect();
  }

  void dispose() {
    _timer.cancel();
    _activeClient?.close();
    _activeClient = null;
    if (!_outController.isClosed) _outController.close();
  }
}

class Ticket {
  final String firestoreId;
  final String ticketId;
  final String status;
  final String region;
  final Map<String, dynamic> data;

  Ticket({
    required this.firestoreId,
    required this.ticketId,
    required this.status,
    required this.region,
    required this.data,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      firestoreId: json["_firestore_id"] ?? "",
      ticketId: json["ticket_id"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      region: json["region"]?.toString() ?? "",
      data: json,
    );
  }
}

Stream<List<Ticket>> watchTickets({
  required String baseUrl,
  required String customerId,
  required String region,
  required String start,
  required String end,
  Duration refreshInterval = const Duration(minutes: 55),
}) {
  final watcher = PeriodicTicketWatcher(
    customerId: customerId,
    region: region,
    start: start,
    end: end,
    refreshInterval: refreshInterval,
  );

  late StreamSubscription<List<Ticket>> sub;
  final relay = StreamController<List<Ticket>>(
    onCancel: () {
      sub.cancel();
      watcher.dispose();
    },
  );

  sub = watcher.stream.listen(
    relay.add,
    onError: relay.addError,
    onDone: relay.close,
  );

  return relay.stream;
}
