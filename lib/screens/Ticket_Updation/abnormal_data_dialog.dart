import 'dart:developer';
import 'package:citizen_complaints_list_web/utils/constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbnormalDataDialog extends StatefulWidget {
  final String ticketId;
  const AbnormalDataDialog({super.key, required this.ticketId});

  @override
  State<AbnormalDataDialog> createState() => _DuplicateSearchScreenState();
}

class _DuplicateSearchScreenState extends State<AbnormalDataDialog> {
  Map<String, dynamic> setPkt = {};
  Map<String, dynamic> latestPkt = {};
  Map<String, dynamic> clearPkt = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAbnormalData();
  }

  Future<void> _fetchAbnormalData() async {
    Dio dio = Dio();

    try {
      Response response = await dio.get(
        '$baseURL/api/alarm/info/${widget.ticketId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final details = response.data['details'] as Map<String, dynamic>;
        final fetchedSetPkt = details['set_pkt'] as Map<String, dynamic>? ?? {};
        final fetchedLatestPkt =
            details['latest_pkt'] as Map<String, dynamic>? ?? {};
        final fetchedClearPkt =
            details['clear_pkt'] as Map<String, dynamic>? ?? {};

        if (!mounted) return;

        setState(() {
          setPkt = fetchedSetPkt;
          latestPkt = fetchedLatestPkt;
          clearPkt = fetchedClearPkt;
          _isLoading = false;
        });
      }
      return;
    } catch (e) {
      log('Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 430,
        height: 230,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Abnormal Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).canvasColor,
                    ),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final rows = [
      if (setPkt.isNotEmpty) _buildPacketRow(context, 'Set', setPkt),
      if (latestPkt.isNotEmpty) _buildPacketRow(context, 'Latest', latestPkt),
      if (clearPkt.isNotEmpty) _buildPacketRow(context, 'Clear', clearPkt),
    ];

    if (rows.isEmpty) {
      return const Center(
          child: Text(
        'No data',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ));
    }

    return Table(
      columnWidths: const {
        0: FixedColumnWidth(70),
        1: FixedColumnWidth(160),
        2: FixedColumnWidth(100),
        3: FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          children: const [
            _HeaderCell('Packet'),
            _HeaderCell('MRTS'),
            _HeaderCell('kWh Open'),
            _HeaderCell('kWh Close'),
          ],
        ),
        ...rows,
      ],
    );
  }
}

TableRow _buildPacketRow(
    BuildContext context, String label, Map<String, dynamic> pkt) {
  final mrts = pkt['mrts'];
  final mrtsStr = mrts != null
      ? DateFormat('dd-MM-yyyy HH:mm:ss')
          .format(DateTime.fromMillisecondsSinceEpoch((mrts as int) * 1000))
      : '-';
  return TableRow(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
    ),
    children: [
      _DataCell(label, bold: true),
      _DataCell(mrtsStr),
      _DataCell(
          '${pkt['kwhOpen'] != null ? (pkt['kwhOpen'] / 1000).toStringAsFixed(2) : '-'}'),
      _DataCell(
          '${pkt['kwhClose'] != null ? (pkt['kwhClose'] / 1000).toStringAsFixed(2) : '-'}'),
    ],
  );
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool bold;
  const _DataCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        text,
        style: bold ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
    );
  }
}
