import 'package:citizen_complaints_list_web/s3_bucket/s3_config.dart';
import 'package:citizen_complaints_list_web/screens/Tickets_List/tickets_list_controller.dart';
import 'package:flutter/material.dart';

class AuditTrailDialog extends StatefulWidget {
  final String ticketId;
  final List<dynamic> auditTrail;

  const AuditTrailDialog({
    super.key,
    required this.ticketId,
    required this.auditTrail,
  });

  @override
  State<AuditTrailDialog> createState() => _AuditTrailDialogState();
}

class _AuditTrailDialogState extends State<AuditTrailDialog> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _timeAgo(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return '';

    try {
      final dt = DateTime.parse(dateTimeStr);
      final diff = DateTime.now().difference(dt);

      String unit(int v, String u) => '$v $u${v == 1 ? '' : 's'} ago';

      if (diff.inDays <= 7) {
        if (diff.inDays > 0) return unit(diff.inDays, 'day');
        if (diff.inHours > 0) return unit(diff.inHours, 'hour');
        if (diff.inMinutes > 0) return unit(diff.inMinutes, 'min');
        return 'Just now';
      }

      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ap = dt.hour >= 12 ? 'PM' : 'AM';

      return '${m[dt.month - 1]} ${dt.day}, ${dt.year} '
          '${h.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')} $ap';
    } catch (_) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedTrail = List.from(widget.auditTrail)
      ..sort((a, b) => (b['on'] ?? '').compareTo(a['on'] ?? ''));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: Theme.of(context).primaryColor,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Audit Trail - ${widget.ticketId}",
                      style: TextStyle(
                        fontSize: 20,
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
            ),
            Flexible(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  // Padding moved to ListView to allow scrollbar to be at the edge
                  child: sortedTrail.isEmpty
                      ? const Center(child: Text("No history available"))
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          trackVisibility: false,
                          thickness: 5,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context)
                                .copyWith(scrollbars: false),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              shrinkWrap: true,
                              itemCount: sortedTrail.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final item = sortedTrail[index];
                                final String by = item['by'] ?? 'Unknown';
                                final String on = item['on'] ?? '';
                                final dynamic actionRaw = item['actions'];
                                final String attachment =
                                    item['attachment'] ?? '';

                                List<String> actions = [];
                                if (actionRaw is List) {
                                  actions = actionRaw
                                      .map((e) => e.toString())
                                      .toList();
                                } else if (actionRaw is String) {
                                  actions = [actionRaw];
                                }
                                if (item['comment'] != null &&
                                    item['comment'].toString().isNotEmpty) {
                                  actions.add("Commented: ${item['comment']}");
                                }

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "$by - ${_timeAgo(on)}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            if (actions.isNotEmpty)
                                              ...actions.map(
                                                (action) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    bottom: 4.0,
                                                  ),
                                                  child: Text("• $action"),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (attachment.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12.0),
                                          child: InkWell(
                                            onTap: () =>
                                                launchAttachment(attachment),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              '${S3Config.s3Endpoint}/$attachment',
                                              width: 100,
                                              height: 100,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.description,
                                                  color: Theme.of(
                                                    context,
                                                  ).highlightColor,
                                                  size: 30,
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      if (attachment.isEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12.0),
                                          child: Text(
                                            "No attachment",
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(
                                                context,
                                              ).unselectedWidgetColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
