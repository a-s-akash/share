import 'dart:developer';
import 'package:flutter/material.dart';

import '../../firebase_setup/firbase_config.dart';
import '../../firebase_setup/firebase_services.dart';

class DuplicateSearchScreen extends StatefulWidget {
  final String region;
  final String currentTicketId;
  final String currentTicketOpenedOn;
  const DuplicateSearchScreen(
      {super.key,
      required this.region,
      required this.currentTicketId,
      required this.currentTicketOpenedOn});

  @override
  State<DuplicateSearchScreen> createState() => _DuplicateSearchScreenState();
}

class _DuplicateSearchScreenState extends State<DuplicateSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _allItems = [];
  List<Map<String, String>> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final prefixDoc = await FirebaseServices.ticketsFirestore
          .collection('utils')
          .doc('prefix')
          .get();

      final prefixes = prefixDoc.data();
      if (prefixes == null || !prefixes.containsKey(widget.region)) {
        log('Region ${widget.region} not configured in prefix utils');
        setState(() => _isLoading = false);
        return;
      }

      final String prefix = prefixes[widget.region] ?? '';
      if (prefix.isEmpty) {
        log('Prefix not found for region ${widget.region}');
        setState(() => _isLoading = false);
        return;
      }

      // 2. Query Tickets by Prefix
      // "Starts with" query: prefix <= ticket_id < prefix + \uf8ff
      final querySnapshot = await FirebaseServices.ticketsFirestore
          .collection(ticketCollectionName)
          .where('ticket_id', isGreaterThanOrEqualTo: prefix)
          .where('ticket_id', isLessThan: '$prefix\uf8ff')
          .where('ticket_id', isNotEqualTo: widget.currentTicketId)
          .get();

      // final tickets = querySnapshot.docs
      //     .where((doc) => (doc['ticket_closed_on'] == null ||
      //         doc['ticket_closed_on'] == ''))
      //     .map((doc) {
      //   return {
      //     'ticket_id': doc['ticket_id'] as String,
      //     'doc_id': doc.id,
      //   };
      // }).toList();

      final tickets = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final closedOn = data['ticket_closed_on'];
        bool isDuplicatedTicket = data['status'] == 'Verified-Duplicate';

        return (closedOn == null ||
                closedOn.toString().isEmpty ||
                DateTime.parse(closedOn)
                    .isAfter(DateTime.parse(widget.currentTicketOpenedOn))) &&
            !isDuplicatedTicket;
      }).map((doc) {
        return {
          'ticket_id': doc['ticket_id'] as String,
          'doc_id': doc.id,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allItems = tickets;
          _filteredItems = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Error fetching tickets: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _allItems
          .where((item) =>
              item['ticket_id']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 400,
        height: 500,
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
                    'Select Duplicate Ticket',
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: _filterItems,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        return ListTile(
                          title: Text(item['ticket_id']!),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm'),
                                content: RichText(
                                  text: TextSpan(
                                    style: DefaultTextStyle.of(context).style,
                                    children: [
                                      const TextSpan(
                                          text:
                                              'Mark this ticket as duplicate of '),
                                      TextSpan(
                                        text: item['ticket_id'].toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: '?'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .unselectedWidgetColor,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context, item);
                                    },
                                    child: Text(
                                      'Yes',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
