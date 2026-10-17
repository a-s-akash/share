// import 'package:flutter/material.dart';

// class RegionSelectorDialog extends StatefulWidget {
//   final List<Map<String, dynamic>> regionList;
//   const RegionSelectorDialog({required this.regionList, super.key});

//   @override
//   State<RegionSelectorDialog> createState() => _RegionSelectorDialogState();
// }

// class _RegionSelectorDialogState extends State<RegionSelectorDialog> {
//   List<Map<String, dynamic>> baseRegions = [];
//   List<Map<String, dynamic>> filtered = [];

//   @override
//   void initState() {
//     super.initState();
//     baseRegions = widget.regionList;
//     filtered = baseRegions;
//   }

//   void _filter(String q) {
//     setState(() {
//       if (q.isEmpty) {
//         filtered = baseRegions;
//       } else {
//         filtered = baseRegions
//             .where((e) => e['name'].toLowerCase().contains(q.toLowerCase()))
//             .toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       insetPadding: const EdgeInsets.all(20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         width: 450,
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Select Region",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(height: 15),

//             TextField(
//               onChanged: _filter,
//               decoration: InputDecoration(
//                 hintText: "Search Region",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 15),

//             /// LIST
//             SizedBox(
//               height: 300,
//               child: filtered.isEmpty
//                   ? const Center(
//                       child: Text(
//                         "No Region Found",
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   : ListView.builder(
//                       itemCount: filtered.length,
//                       itemBuilder: (context, index) {
//                         final region = filtered[index];
//                         return ListTile(
//                           title: Text(region['name']),
//                           onTap: () => Navigator.pop(context, region),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
