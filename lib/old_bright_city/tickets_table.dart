// import 'dart:convert';

// import 'package:citizen_complaints_list_web/ticket_form.dart';
// import 'package:dio/dio.dart';
// import 'package:extended_image/extended_image.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import 'package:cool_alert/cool_alert.dart';
// import 'package:syncfusion_flutter_datagrid/datagrid.dart';
// import 'package:auto_size_text/auto_size_text.dart';
// import 'utils/constants.dart';
// import 'dart:developer';
// import 'package:extended_image/extended_image.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:geolocator/geolocator.dart';

// class FilteredComplaintsTable extends StatefulWidget {
//   final String? region;
//   final String? createdBy;
//   const FilteredComplaintsTable({super.key, this.region, this.createdBy});
//   @override
//   FilteredComplaintsTableState createState() => FilteredComplaintsTableState();
// }

// class FilteredComplaintsTableState extends State<FilteredComplaintsTable>
//     with SingleTickerProviderStateMixin {
//   String searchQuery = '';
//   List<Map<String, dynamic>> complaints = [];
//   List<Map<String, dynamic>> filteredComplaints = [];
//   bool isSearchActive = false;
//   final Dio dio = Dio();
//   late ComplaintDataSource complaintDataSource;

//   // TabController to manage tab switching
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the TabController with 2 tabs (Open and Closed)
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         scrolledUnderElevation: 0,
//         backgroundColor: backgroundColor,
//         title: isSearchActive
//             ? TextField(
//                 autofocus: true,
//                 onChanged: (value) {
//                   setState(() {
//                     searchQuery = value;
//                     _filterComplaints();
//                   });
//                 },
//                 decoration: const InputDecoration(
//                   hintText: 'Search Tickets',
//                   border: InputBorder.none,
//                 ),
//               )
//             : Text(
//                 widget.region == null
//                     ? 'All Complaints'
//                     : '${widget.region} Complaints',
//                 style: const TextStyle(
//                   fontSize: 16,
//                 ),
//               ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 40.0),
//             child: IconButton(
//               icon: Icon(isSearchActive ? Icons.close : Icons.search),
//               onPressed: () {
//                 setState(() {
//                   isSearchActive = !isSearchActive;
//                   if (!isSearchActive) {
//                     searchQuery = '';
//                     _filterComplaints();
//                   }
//                 });
//               },
//             ),
//           )
//         ],
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48.0),
//           child: Row(
//             children: [
//               TabBar(
//                 controller: _tabController,
//                 tabs: const [
//                   Tab(text: 'Open Tickets'),
//                   Tab(text: 'Closed Tickets'),
//                 ],
//                 onTap: (index) {
//                   _filterComplaints();
//                 },
//                 labelStyle: const TextStyle(
//                     fontFamily: 'Roboto', fontWeight: FontWeight.w800),
//                 dividerColor: Colors.white,
//                 unselectedLabelColor: Colors.grey,
//                 indicatorColor: const Color(0xFF1D7569),
//                 labelColor: Colors.black,
//                 isScrollable: true,
//                 tabAlignment: TabAlignment.start,
//                 labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
//               ),
//               const Spacer(),
//               GestureDetector(
//                 onTap: () async {
//                   EasyLoading.show(maskType: EasyLoadingMaskType.black);

//                   // Request location permission
//                   LocationPermission permission =
//                       await Geolocator.checkPermission();
//                   if (permission == LocationPermission.denied ||
//                       permission == LocationPermission.deniedForever) {
//                     permission = await Geolocator.requestPermission();
//                   }

//                   double? lat;
//                   double? long;
//                   String? fullLocation;

//                   // Fetch current location if allowed
//                   if (permission == LocationPermission.always ||
//                       permission == LocationPermission.whileInUse) {
//                     try {
//                       final pos = await Geolocator.getCurrentPosition(
//                         desiredAccuracy: LocationAccuracy.high,
//                       );
//                       lat = double.parse(pos.latitude.toStringAsFixed(7));
//                       long = double.parse(pos.longitude.toStringAsFixed(7));

//                       try {
//                         final url =
//                             "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$long";
//                         final response = await http.get(
//                           Uri.parse(url),
//                           headers: {"User-Agent": "bright-city-web-app/1.0"},
//                         );
//                         if (response.statusCode == 200) {
//                           final data = jsonDecode(response.body);

//                           final address =
//                               data["display_name"] ?? "Address not found";
//                           fullLocation = address;
//                         } else {
//                           fullLocation = "Address not found";
//                         }
//                       } catch (e) {
//                         fullLocation = "Address not found";
//                       }
//                     } catch (e) {
//                       print("Location fetch error: $e");
//                     }
//                   }

//                   // Fetch region list
//                   final snap = await FirebaseFirestore.instance
//                       .collection('utils')
//                       .doc('region_list')
//                       .get();

//                   List<Map<String, dynamic>> regionList  = [];
//                   if (snap.exists && snap.data() != null) {
//                     final data = snap.data() as Map<String, dynamic>;
//                     if (data.containsKey('regions') && data['regions'] is List) {
//                       regionList = List.from(data['regions']);
//                     }
//                   }

//                   EasyLoading.dismiss();

//                   showDialog(
//                     context: context,
//                     builder: (context) {
//                       return Dialog(
//                         insetPadding: const EdgeInsets.all(20),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: SizedBox(
//                           width: MediaQuery.of(context).size.width / 2.5,
//                           child: TicketScreationForm(
//                             regionList: regionList,
//                             initialLat: lat,
//                             initialLong: long,
//                             initialLocationText: fullLocation,
//                             createdBy: widget.createdBy,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//                 child: Container(
//                   padding: const EdgeInsets.all(8.0),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1D7569),
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(
//                         Icons.add,
//                         color: Colors.white,
//                       ),
//                       Text(
//                         "Add Ticket",
//                         style: TextStyle(
//                           color: Colors.white,
//                         ),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 15),
//             ],
//           ),
//         ),
//       ),
//       body: Container(
//         color: backgroundColor,
//         child: StreamBuilder<QuerySnapshot>(
//           stream: widget.region == null
//               ? FirebaseFirestore.instance
//                   .collection('complaints')
//                   .where('ticket_status',
//                       isEqualTo: _tabController.index == 0 ? 'OPEN' : 'CLOSED')
//                   .snapshots()
//               : FirebaseFirestore.instance
//                   .collection('complaints')
//                   .where('region',
//                       isEqualTo: widget.region.toString().toLowerCase())
//                   .where('ticket_status',
//                       isEqualTo: _tabController.index == 0 ? 'OPEN' : 'CLOSED')
//                   .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             }

//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             complaints = snapshot.data?.docs.map((doc) {
//                   return doc.data() as Map<String, dynamic>;
//                 }).toList() ??
//                 [];

//             complaints.sort((a, b) {
//               String idA = a['id'] ?? '';
//               String idB = b['id'] ?? '';
//               return idB.compareTo(idA);
//             });

//             filteredComplaints = complaints;
//             if (searchQuery.isNotEmpty) {
//               filteredComplaints = complaints.where((complaint) {
//                 return complaint.values.any((value) {
//                   return value
//                       .toString()
//                       .toLowerCase()
//                       .contains(searchQuery.toLowerCase());
//                 });
//               }).toList();
//             }

//             if (filteredComplaints.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 16),
//                     Text(
//                       'No ${_tabController.index == 0 ? 'Opened' : 'Closed'} Tickets Found',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.grey[600],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }

//             complaintDataSource = ComplaintDataSource(
//               complaints: filteredComplaints,
//               onCloseTicket: _closeTicket,
//               onViewDetails: _viewDetails,
//               context: context,
//               searchQuery: searchQuery,
//               region: widget.region,
//               ticketStatus: _tabController.index == 0
//                   ? 'OPEN'
//                   : 'CLOSED', // Filter based on selected tab
//             );

//             if (filteredComplaints.isEmpty) {
//               return const Center(child: Text('No Complaints found'));
//             }

//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 2),
//               child: SizedBox(
//                 width: MediaQuery.of(context).size.width,
//                 child: SfDataGrid(
//                   source: complaintDataSource,
//                   allowSorting: true,
//                   columnWidthMode: ColumnWidthMode.fill,
//                   rowHeight: 75.0,
//                   gridLinesVisibility: GridLinesVisibility.horizontal,
//                   headerGridLinesVisibility: GridLinesVisibility.horizontal,
//                   columns: [
//                     GridColumn(
//                       columnName: 'sno',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'S.No',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 1,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByColumnName,
//                     ),
//                     GridColumn(
//                       columnName: 'ticketId',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Ticket No',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 2,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.auto,
//                     ),
//                     GridColumn(
//                       columnName: 'issue',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Issue',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 1,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.auto,
//                     ),
//                     GridColumn(
//                       columnName: 'location',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Location',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 1,
//                         ),
//                       ),
//                     ),
//                     GridColumn(
//                       columnName: 'phoneNumber',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Phone No',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 2,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByCellValue,
//                     ),
//                     GridColumn(
//                       columnName: 'status',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Status',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 1,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByColumnName,
//                     ),
//                     GridColumn(
//                       columnName: 'openedDate',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Opened Date',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 2,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByColumnName,
//                     ),
//                     GridColumn(
//                       columnName: 'closedDate',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Closed Date',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 2,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByColumnName,
//                     ),
//                     GridColumn(
//                       columnName: 'actions',
//                       label: Container(
//                         alignment: Alignment.center,
//                         child: AutoSizeText(
//                           'Actions',
//                           style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color: tableColumnHeading),
//                           maxLines: 1,
//                         ),
//                       ),
//                       columnWidthMode: ColumnWidthMode.fitByColumnName,
//                       allowSorting: false,
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // Filter complaints based on the search query and the selected tab
//   void _filterComplaints() {
//     filteredComplaints = complaints.where((complaint) {
//       // Filter by search query
//       bool matchesSearchQuery = complaint.values.any((value) {
//         return value
//             .toString()
//             .toLowerCase()
//             .contains(searchQuery.toLowerCase());
//       });

//       // Filter by ticket status based on the selected tab
//       bool matchesStatus = complaint['ticket_status'] ==
//           (_tabController.index == 0 ? 'OPEN' : 'CLOSED');

//       return matchesSearchQuery && matchesStatus;
//     }).toList();
//     setState(() {});
//   }

//   void _closeTicket(Map<String, dynamic> data) async {
//     DateTime now = DateTime.now();
//     String datetime = now.toString();
//     try {
//       await FirebaseFirestore.instance
//           .collection('complaints')
//           .doc(data['id'])
//           .update({'ticket_status': 'CLOSED', 'ticket_closedOn': datetime});
//       setState(() {
//         data['ticket_status'] = 'CLOSED';
//         data['ticket_closedOn'] = datetime;
//       });
//       dio.get(
//         'http://iotpro.io:8079/api/sms/send/',
//         queryParameters: {
//           'uname': 'schnelltr',
//           'pass': 'V@r~V)d3',
//           'send': 'SCHNEL',
//           'dest': '91${data['phone_number']}',
//           'msg':
//               'Your complaint ticket no. ${data['id']} has been resolved. Thank you for your help in keeping the city lit. -SEEPL',
//         },
//       );

//       CoolAlert.show(
//         context: context,
//         type: CoolAlertType.success,
//         text: "Ticket has been resolved! SMS sent to ${data['phone_number']}.",
//       );
//     } catch (e) {
//       CoolAlert.show(
//         context: context,
//         type: CoolAlertType.error,
//         text: "Error closing ticket or sending SMS: $e",
//       );
//     }
//   }

//   void _viewDetails(BuildContext context, Map<String, dynamic> data) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//               "${data['id'] ?? '-'} - ${data['problem_description'] ?? '-'}"),
//           content: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Ticket id: ${data['id'] ?? '-'}"),
//                 Text("Phone Number: ${data['phone_number'] ?? '-'}"),
//                 Text("Issue: ${data['problem_description'] ?? '-'}"),
//                 Text("Comments: ${data['comments'] ?? '-'}"),
//                 Text("Location: ${data['location'] ?? '-'}"),
//                 Text("Latitude: ${data['latitude'] ?? '-'}"),
//                 Text("Longitude: ${data['longitude'] ?? '-'}"),
//                 Text("Pole/Panel id: ${data['device'] ?? '-'}"),
//                 Text("Region: ${data['region'] ?? '-'}"),
//                 Text("Status of the Ticket: ${data['ticket_status'] ?? '-'}"),
//                 Text("Ticket Raised on ${data['ticket_opened_on'] ?? '-'}"),
//                 Text("Ticket Resolved on ${data['ticket_closedOn'] ?? '-'}"),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (data['image_path'] != null &&
//                         data['image_path'] != 'None' &&
//                         data['image_path'] != 'N/A')
//                       ExtendedImage.network(
//                         data['image_path']!,
//                         fit: BoxFit.cover,
//                         cache: true,
//                         enableLoadState: true,
//                         loadStateChanged: (ExtendedImageState state) {
//                           switch (state.extendedImageLoadState) {
//                             case LoadState.loading:
//                               return const Center(
//                                   child: CircularProgressIndicator());
//                             case LoadState.completed:
//                               return null;
//                             case LoadState.failed:
//                               log(state.toString());
//                               return const Center(
//                                   child: Icon(Icons.error, color: Colors.red));
//                           }
//                         },
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// class ComplaintDataSource extends DataGridSource {
//   List<DataGridRow> _complaintRows = [];
//   final Function(Map<String, dynamic>) onCloseTicket;
//   final Function(BuildContext, Map<String, dynamic>) onViewDetails;
//   final BuildContext context;
//   final String searchQuery;
//   final String? region;
//   String ticketStatus;

//   ComplaintDataSource({
//     required List<Map<String, dynamic>> complaints,
//     required this.onCloseTicket,
//     required this.onViewDetails,
//     required this.context,
//     required this.searchQuery,
//     required this.region,
//     required this.ticketStatus,
//   }) {
//     _complaintRows = complaints.map((data) {
//       return DataGridRow(
//         cells: [
//           DataGridCell<int>(
//               columnName: 'sno', value: complaints.indexOf(data) + 1),
//           DataGridCell<String>(
//               columnName: 'ticketId', value: data['id'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'issue', value: data['problem_description'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'location', value: data['location'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'phoneNumber', value: data['phone_number'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'status', value: data['ticket_status'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'openedDate', value: data['ticket_opened_on'] ?? '-'),
//           DataGridCell<String>(
//               columnName: 'closedDate', value: data['ticket_closedOn'] ?? '-'),
//           DataGridCell<Widget>(
//             columnName: 'actions',
//             value: Center(
//               child: PopupMenuButton<String>(
//                 icon: const Icon(Icons.more_vert, color: Colors.grey, size: 24),
//                 onSelected: (value) {
//                   if (value == 'copy') {
//                     Clipboard.setData(ClipboardData(text: data.toString()));
//                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                       content: Text('Complaint JSON copied to clipboard!'),
//                     ));
//                   } else if (value == 'close') {
//                     if (data['ticket_status'] == 'OPEN') {
//                       onCloseTicket(data);
//                     }
//                   } else if (value == 'view') {
//                     onViewDetails(context, data);
//                   }
//                 },
//                 itemBuilder: (context) => [
//                   const PopupMenuItem<String>(
//                     value: 'copy',
//                     child: Row(
//                       children: [
//                         Icon(Icons.copy, color: Colors.black, size: 20),
//                         SizedBox(width: 8),
//                         Text('Copy JSON'),
//                       ],
//                     ),
//                   ),
//                   PopupMenuItem<String>(
//                     value: 'close',
//                     child: Row(
//                       children: [
//                         Icon(
//                           data['ticket_status'] == 'OPEN'
//                               ? Icons.check_circle_outline_outlined
//                               : Icons.check_circle,
//                           color: data['ticket_status'] == 'OPEN'
//                               ? Colors.green
//                               : Colors.grey,
//                           size: 20,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text('Close Ticket'),
//                       ],
//                     ),
//                   ),
//                   const PopupMenuItem<String>(
//                     value: 'view',
//                     child: Row(
//                       children: [
//                         Icon(Icons.info_outline, color: Colors.blue, size: 20),
//                         SizedBox(width: 8),
//                         Text('View Info'),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     }).toList();
//   }

//   @override
//   List<DataGridRow> get rows {
//     if (region == null && searchQuery.isEmpty) {
//       return _complaintRows.sublist(0, _complaintRows.length - 1);
//     } else {
//       return _complaintRows;
//     }
//   }

//   @override
//   DataGridRowAdapter buildRow(DataGridRow row) {
//     return DataGridRowAdapter(
//       cells: row.getCells().map<Widget>((cell) {
//         if (cell.columnName == 'actions' && cell.value is Widget) {
//           return cell.value;
//         }
//         if (cell.columnName == 'ticketId' ||
//             cell.columnName == 'issue' ||
//             cell.columnName == 'location') {
//           return Container(
//             alignment: Alignment.centerLeft,
//             padding: const EdgeInsets.symmetric(horizontal: 6.0),
//             child: Text(cell.value.toString()),
//           );
//         }
//         return Container(
//           alignment: Alignment.center,
//           padding: const EdgeInsets.symmetric(horizontal: 6.0),
//           child: Text(cell.value.toString()),
//         );
//       }).toList(),
//     );
//   }
// }
