// import 'dart:developer';

// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../device_page/telemetry_service.dart';
// import '../survey/connectivity_sync_service.dart';
// import '../utils/utility.dart';

// final TelemetryService _telemetryService = TelemetryService();

// Future<void> showVehicleDetailsDialog(
//   BuildContext context,
//   WidgetRef ref,
// ) async {
//   // Load last-entered values as defaults
//   final prefs = await SharedPreferences.getInstance();
//   final formKey = GlobalKey<FormState>();
//   String? selectedVehicleType = prefs.getString('saved_vehicle_type');
//   final TextEditingController vehicleNumberController = TextEditingController(
//       text: prefs.getString('saved_vehicle_number') ?? '');

//   if (!context.mounted) return;
//   await showDialog(
//     context: context,
//     barrierDismissible: false,
//     barrierColor: Colors.black.withValues(alpha: 0.8),
//     // barrierBlurSigma: 4,
//     builder: (context) {
//       return WillPopScope(
//         onWillPop: () async {
//           return false;
//         },
//         child: Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Container(
//             width: 350,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//             child: Form(
//               key: formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   /// Title
//                   Text(
//                     "Vehicle Details Required",
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                       fontSize: 17,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   /// Vehicle Type Dropdown
//                   DropdownButtonFormField2<String>(
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                       fontSize: 14,
//                     ),
//                     isDense: true,
//                     decoration: InputDecoration(
//                       labelText: "Vehicle Type",
//                       labelStyle: TextStyle(
//                         color: Theme.of(context).primaryColor,
//                         fontSize: 13,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 12,
//                       ),
//                     ),
//                     value: selectedVehicleType,
//                     items: const [
//                       DropdownMenuItem(
//                         value: "2 Wheeler",
//                         child: Text("2 Wheeler"),
//                       ),
//                       DropdownMenuItem(
//                         value: "4 Wheeler",
//                         child: Text("4 Wheeler"),
//                       ),
//                     ],
//                     dropdownStyleData: DropdownStyleData(
//                       elevation: 2,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       selectedVehicleType = value;
//                     },
//                     validator: (value) =>
//                         value == null ? "Select vehicle type" : null,
//                   ),

//                   const SizedBox(height: 16),

//                   /// Vehicle Number
//                   TextFormField(
//                     controller: vehicleNumberController,
//                     // textCapitalization: TextCapitalization.characters,
//                     maxLength: 10,
//                     style: TextStyle(
//                       color: Theme.of(context).primaryColor,
//                       fontSize: 14,
//                     ),
//                     inputFormatters: [
//                       FilteringTextInputFormatter.allow(
//                         RegExp(r'[a-zA-Z0-9 ]'),
//                       ),
//                     ],
//                     decoration: InputDecoration(
//                       counterText: '',
//                       labelText: "Vehicle Number",
//                       labelStyle: TextStyle(
//                         color: Theme.of(context).primaryColor,
//                         fontSize: 13,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 14,
//                       ),
//                     ),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return "Enter vehicle number";
//                       }
//                       return null;
//                     },
//                   ),

//                   const SizedBox(height: 24),

//                   /// Proceed Button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 45,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Theme.of(context).primaryColor,
//                         foregroundColor: Theme.of(context).canvasColor,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         elevation: 2,
//                       ),
//                       onPressed: () async {
//                         if (formKey.currentState!.validate()) {
//                           final vehicleType = selectedVehicleType!;
//                           final vehicleNumber =
//                               vehicleNumberController.text.trim().toUpperCase();

//                           log('vehicleType: $vehicleType, vehicleNo: $vehicleNumber');

//                           // Persist as default for next session
//                           await prefs.setString(
//                               'saved_vehicle_type', vehicleType);
//                           await prefs.setString(
//                               'saved_vehicle_number', vehicleNumber);

//                           final isOnline = await Utility.isConnected();
//                           if (isOnline) {
//                             _telemetryService.pushValuesToUserTelemetry({
//                               'vehicleType': vehicleType,
//                               'vehicleNo': vehicleNumber,
//                             });
//                           } else {
//                             await SimpleSyncService.enqueueTelemetry({
//                               'vehicleType': vehicleType,
//                               'vehicleNo': vehicleNumber,
//                             });
//                           }

//                           if (context.mounted) Navigator.pop(context);
//                         }
//                       },
//                       child: const Text(
//                         "Proceed",
//                         style: TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }
