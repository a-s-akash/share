import 'package:flutter/material.dart';
import 'package:schnell_luminator/attendence_tracking.dart/attendance_record.dart';
import 'package:schnell_luminator/utils/utility.dart';

class SwipeRecordsPage extends StatefulWidget {
  const SwipeRecordsPage({super.key});

  @override
  State<SwipeRecordsPage> createState() => _SwipeRecordsPageState();
}

class _SwipeRecordsPageState extends State<SwipeRecordsPage> {
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    await Utility.refreshAttendanceBox();
    final box = await Utility.openAttendanceBox();
    final sorted = box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) {
      setState(() {
        _records = sorted;
        _loading = false;
      });
    }
  }

  String _formatDateTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final date =
        '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    final time =
        '$hour:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} $amPm';
    return '$date  $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe Records'),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.19),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Theme.of(context).cardColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: IconThemeData(color: Theme.of(context).cardColor),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Text(
                    'No swipe records found.',
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontSize: 15,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final isLogin = record.type == 'login';
                      return _SwipeCard(
                        isLogin: isLogin,
                        dateTime: _formatDateTime(record.timestamp),
                        synced: record.synced,
                        latitude: record.latitude,
                        longitude: record.longitude,
                      );
                    },
                  ),
                ),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.isLogin,
    required this.dateTime,
    required this.synced,
    required this.latitude,
    required this.longitude,
  });

  final bool isLogin;
  final String dateTime;
  final bool synced;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final color = isLogin ? Colors.green : Colors.red;
    final icon = isLogin ? Icons.login : Icons.logout;
    final label = isLogin ? 'Swipe In' : 'Swipe Out';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).dialogTheme.backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            _SyncBadge(synced: synced),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.synced});
  final bool synced;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: synced
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            synced ? Icons.cloud_done : Icons.cloud_upload,
            size: 13,
            color: synced ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            synced ? 'Synced' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: synced ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
