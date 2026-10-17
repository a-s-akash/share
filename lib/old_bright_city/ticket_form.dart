// import 'dart:async';
// import 'dart:developer';

// import 'package:citizen_complaints_list_web/image_address_append.dart';
// import 'package:citizen_complaints_list_web/region_list.dart';
// import 'package:citizen_complaints_list_web/utils/firestore_controller.dart';
// import 'package:citizen_complaints_list_web/utils/s3image_controller.dart';
// import 'package:citizen_complaints_list_web/utils/ticket_controller.dart';
// import 'package:extended_image/extended_image.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:typed_data';
// import 'dart:convert';
// import 'package:uuid/uuid.dart' as uuid;
// import 'package:image_compression/image_compression.dart';
// import 'package:lottie/lottie.dart';

// class TicketScreationForm extends StatefulWidget {
//   final List<Map<String, dynamic>> regionList;
//   final double? initialLat;
//   final double? initialLong;
//   final String? initialLocationText;
//   final String? createdBy;

//   const TicketScreationForm({
//     required this.regionList,
//     this.initialLat,
//     this.initialLong,
//     this.initialLocationText,
//     super.key,
//     this.createdBy,
//   });

//   @override
//   State<TicketScreationForm> createState() => _TicketScreationFormState();
// }

// class _TicketScreationFormState extends State<TicketScreationForm> {
//   final TextEditingController _regionController = TextEditingController();

//   final TextEditingController _issueController = TextEditingController();
//   final TextEditingController _assetIDController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _commentsController = TextEditingController();
//   TextEditingController _latController = TextEditingController();
//   TextEditingController _longController = TextEditingController();
//   Timer? _debounce;
//   String _choosenRegionId = "";

//   void debounceUpdate(String address, String which) {
//     // Cancel previous timer
//     _debounce?.cancel();

//     // Wait 500ms after last keystroke
//     _debounce = Timer(const Duration(milliseconds: 500), () async {
//       if (which == "location") {
//         try {
//           final url =
//               "https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1";
//           final response = await http.get(
//             Uri.parse(url),
//             headers: {"User-Agent": "bright-city-web-app/1.0"},
//           );
//           if (response.statusCode == 200) {
//             final data = jsonDecode(response.body);
//             if (data is List && data.isNotEmpty) {
//               setState(() {
//                 _latController.text = data[0]["lat"];
//                 _longController.text = data[0]["lon"];
//               });
//               log("Latitude: ${_latController.text}, Longitude: ${_longController.text}");
//             }
//           } else {
//             setState(() {
//               _latController.text = '0.0';
//               _longController.text = '0.0';
//             });
//             log("Latitude: ${_latController.text}, Longitude: ${_longController.text}");
//           }
//         } catch (e) {
//           log(e.toString());
//           setState(() {
//             _latController.text = "0.0";
//             _longController.text = "0.0";
//           });
//           log("Latitude: ${_latController.text}, Longitude: ${_longController.text}");
//         }
//       } else if (which == "coordinates") {
//         try {
//           final url =
//               "https://nominatim.openstreetmap.org/reverse?format=json&lat=${_latController.text}&lon=${_longController.text}";
//           final response = await http.get(
//             Uri.parse(url),
//             headers: {"User-Agent": "bright-city-web-app/1.0"},
//           );
//           if (response.statusCode == 200) {
//             final data = jsonDecode(response.body);
//             final address = data["display_name"] ?? "Address not found";
//             _locationController.text = address;
//           } else {
//             _locationController.text = "Address not found";
//           }
//         } catch (e) {
//           _locationController.text = "Address not found";
//         }
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Uint8List? _pickedImageBytes;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.initialLocationText != null) {
//       _locationController.text = widget.initialLocationText!;
//     }
//     _latController.text = widget.initialLat.toString();
//     _longController.text = widget.initialLong.toString();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Center(
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black26,
//                 blurRadius: 12,
//                 offset: Offset(0, 4),
//               )
//             ],
//           ),
//           child: ScrollConfiguration(
//             behavior: const ScrollBehavior().copyWith(scrollbars: false),
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Text(
//                         "Create Ticket",
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         icon: const Icon(Icons.close),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   const Row(
//                     children: [
//                       Text("Region "),
//                       Text("*", style: TextStyle(color: Colors.red)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   InkWell(
//                     onTap: () async {
//                       final region = await showDialog(
//                         context: context,
//                         builder: (_) =>
//                             RegionSelectorDialog(regionList: widget.regionList),
//                       );

//                       if (region != null) {
//                         setState(() {
//                           _regionController.text = region['name'];
//                           _choosenRegionId = region['id'];
//                         });
//                       }
//                     },
//                     child: TextField(
//                       enabled: false,
//                       style: const TextStyle(color: Colors.black),
//                       controller: _regionController,
//                       decoration: const InputDecoration(
//                         hintText: "Select Region",
//                         disabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.black),
//                         ),
//                         suffixIcon: Icon(
//                           Icons.arrow_drop_down,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const Row(
//                     children: [
//                       Text("Issue "),
//                       Text("*", style: TextStyle(color: Colors.red)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   DropdownButtonFormField<String>(
//                     value: _issueController.text.isEmpty
//                         ? null
//                         : _issueController.text,
//                     items: [
//                       'Day time burning',
//                       'Lamps not burning',
//                       'Flickering',
//                       'Panel damaged',
//                       'Panel door opened',
//                       'Pole damaged',
//                       'Others'
//                     ]
//                         .map((e) => DropdownMenuItem(value: e, child: Text(e)))
//                         .toList(),
//                     onChanged: (value) {
//                       setState(() {
//                         _issueController.text = value ?? "";
//                       });
//                     },
//                     decoration: const InputDecoration(
//                         hintText: "Select issue",
//                         focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.black)),
//                         enabledBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.black))),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text("Pole or Panel ID"),
//                   const SizedBox(height: 10),
//                   TextField(
//                     controller: _assetIDController,
//                     decoration: const InputDecoration(
//                       focusedBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.black)),
//                       enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.black)),
//                       hintText: "Enter Pole or Panel ID",
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const Row(
//                     children: [
//                       Text("Location "),
//                       Text("*", style: TextStyle(color: Colors.red)),
//                       // Text(
//                       //     " (Lat : ${lat.toString()} , Long : ${long.toString()})",
//                       //     style: const TextStyle(fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Row(children: [
//                     Flexible(
//                       child: TextField(
//                         onChanged: (value) {
//                           debounceUpdate(value, "coordinates");
//                         },
//                         controller: _latController,
//                         decoration: const InputDecoration(
//                           labelText: "Latitude",
//                           labelStyle: TextStyle(color: Colors.black),
//                           floatingLabelBehavior: FloatingLabelBehavior.auto,
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.black),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Colors.black)),
//                           hintText: "Enter Latitude",
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Flexible(
//                       child: TextField(
//                         onChanged: (value) {
//                           debounceUpdate(value, "coordinates");
//                         },
//                         controller: _longController,
//                         decoration: const InputDecoration(
//                           labelText: "Longitude",
//                           labelStyle: TextStyle(color: Colors.black),
//                           floatingLabelBehavior: FloatingLabelBehavior.auto,
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(color: Colors.black),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                               borderSide: BorderSide(color: Colors.black)),
//                           hintText: "Enter Longitude",
//                         ),
//                       ),
//                     ),
//                   ]),
//                   const SizedBox(height: 10),
//                   TextField(
//                     onChanged: (value) {
//                       debounceUpdate(value, "location");
//                     },
//                     controller: _locationController,
//                     decoration: const InputDecoration(
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(color: Colors.black),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                           borderSide: BorderSide(color: Colors.black)),
//                       hintText: "Enter location",
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     children: [
//                       const Text("Comments "),
//                       if (_issueController.text.toLowerCase() == "others")
//                         const Text("*", style: TextStyle(color: Colors.red)),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey),
//                     ),
//                     child: TextField(
//                       controller: _commentsController,
//                       maxLines: 5,
//                       decoration: const InputDecoration(
//                         hintText: "Any additional comments",
//                         border: InputBorder.none,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   _pickedImageBytes == null
//                       ? GestureDetector(
//                           onTap: () async {
//                             final ImagePicker picker = ImagePicker();
//                             final XFile? img = await picker.pickImage(
//                                 source: ImageSource.gallery);
//                             if (img != null) {
//                               EasyLoading.show();

//                               final appender = ImageAddressAppender();
//                               final originalBytes = await img.readAsBytes();
//                               await Future.delayed(Duration(milliseconds: 50));

//                               final stampedBytes =
//                                   await appender.appendAddressToImage(
//                                 originalBytes,
//                                 widget.initialLocationText ??
//                                     "Unknown Location",
//                                 _latController.text,
//                                 _longController.text,
//                               );
//                               setState(() {
//                                 _pickedImageBytes = stampedBytes;
//                                 EasyLoading.dismiss();
//                               });
//                             }
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: const Color.fromARGB(50, 29, 117, 105),
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(color: Colors.grey.shade400),
//                             ),
//                             child: const Center(
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.cloud_upload_outlined,
//                                       size: 30, color: Color(0xFF1D7569)),
//                                   SizedBox(width: 10),
//                                   Text(
//                                     "Upload Image",
//                                     style: TextStyle(fontSize: 16),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         )
//                       : Stack(
//                           children: [
//                             SizedBox(
//                               height: 500,
//                               width: double.infinity,
//                               child: Image.memory(
//                                 _pickedImageBytes!,
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                             Positioned(
//                               top: 8,
//                               right: 8,
//                               child: InkWell(
//                                 onTap: () async {
//                                   final ImagePicker picker = ImagePicker();
//                                   final XFile? img = await picker.pickImage(
//                                       source: ImageSource.gallery);
//                                   if (img != null) {
//                                     EasyLoading.show();

//                                     final appender = ImageAddressAppender();
//                                     final originalBytes =
//                                         await img.readAsBytes();
//                                     await Future.delayed(
//                                         Duration(milliseconds: 50));

//                                     final stampedBytes =
//                                         await appender.appendAddressToImage(
//                                       originalBytes,
//                                       _locationController.text.isEmpty
//                                           ? "NULL"
//                                           : _locationController.text,
//                                       _latController.text,
//                                       _longController.text,
//                                     );
//                                     setState(() {
//                                       _pickedImageBytes = stampedBytes;
//                                       EasyLoading.dismiss();
//                                     });
//                                   }
//                                 },
//                                 child: Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: const BoxDecoration(
//                                     color: Colors.black54,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: const Column(
//                                     children: [
//                                       Icon(
//                                         Icons.replay,
//                                         color: Colors.white,
//                                         size: 20,
//                                       ),
//                                       Text(
//                                         "ReUpload",
//                                         style: TextStyle(
//                                             color: Colors.white, fontSize: 8),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                   const SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.black,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: const Text("  Cancel  ",
//                               style:
//                                   TextStyle(color: Colors.white, fontSize: 16)),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       GestureDetector(
//                         onTap: () async {
//                           if (_regionController.text.isNotEmpty &&
//                               _issueController.text.isNotEmpty &&
//                               _locationController.text.isNotEmpty &&
//                               (_issueController.text.toLowerCase() !=
//                                       "others" ||
//                                   (_issueController.text.toLowerCase() ==
//                                           "others" &&
//                                       _commentsController.text.isNotEmpty))) {
//                             EasyLoading.show(
//                                 status: 'Submitting your Ticket...',
//                                 dismissOnTap: false,
//                                 maskType: EasyLoadingMaskType.black);

//                             var fileName = "None";
//                             if (_pickedImageBytes != null) {
//                               ImageFile inputImageFile = ImageFile(
//                                 rawBytes: _pickedImageBytes!,
//                                 filePath: "picked_image.jpg",
//                               );

//                               ImageFileConfiguration input =
//                                   ImageFileConfiguration(
//                                 config: const Configuration(jpgQuality: 90),
//                                 input: inputImageFile,
//                               );

//                               final compressedImage = compress(input);
//                               fileName = const uuid.Uuid().v1();
//                               log(fileName.toString());

//                               String deviceImage =
//                                   base64Encode(compressedImage.rawBytes);
//                               s3imageUpload(context, deviceImage, fileName);
//                             }
//                             void showSuccessAlert(
//                                 BuildContext context, String ticketID) {
//                               showDialog(
//                                 context: context,
//                                 barrierDismissible: false,
//                                 builder: (BuildContext context) {
//                                   return PopScope(
//                                     canPop: false,
//                                     child: AlertDialog(
//                                       shape: const RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.all(
//                                             Radius.circular(20)),
//                                       ),
//                                       backgroundColor:
//                                           Theme.of(context).cardColor,
//                                       contentPadding: const EdgeInsets.all(0),
//                                       content: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           Container(
//                                             decoration: const BoxDecoration(
//                                               borderRadius:
//                                                   const BorderRadius.only(
//                                                 topLeft: Radius.circular(20),
//                                                 topRight: Radius.circular(20),
//                                               ),
//                                             ),
//                                             width: double.infinity,
//                                             child: Lottie.asset(
//                                               'assets/animation/tick.json',
//                                               height: 150,
//                                               width: 150,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 15),
//                                           Text(
//                                             'Success', // Title
//                                             style: TextStyle(
//                                               color: Theme.of(context)
//                                                   .primaryColorDark,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 20,
//                                             ),
//                                             textAlign: TextAlign.center,
//                                           ),
//                                           const SizedBox(height: 15),
//                                           Text(
//                                             "Ticket Created Successfully!\nTicket ID : $ticketID",
//                                             textAlign: TextAlign.center,
//                                             style: TextStyle(
//                                                 color: Theme.of(context)
//                                                     .primaryColor),
//                                           ),
//                                           const SizedBox(height: 15),
//                                         ],
//                                       ),
//                                       actions: <Widget>[
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             OutlinedButton(
//                                               style: OutlinedButton.styleFrom(
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           20.0),
//                                                 ),
//                                                 side: BorderSide(
//                                                     color: Theme.of(context)
//                                                         .primaryColor),
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 50),
//                                                 backgroundColor:
//                                                     Theme.of(context)
//                                                         .primaryColor,
//                                               ),
//                                               onPressed: () async {
//                                                 Navigator.pop(context);
//                                               },
//                                               child: Text(
//                                                 "OK",
//                                                 style: TextStyle(
//                                                     color: Theme.of(context)
//                                                         .cardColor),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               );
//                             }

//                             String? ticketId =
//                                 await addComplaintToFireStoreDatabase(
//                               _regionController.text,
//                               _issueController.text,
//                               _locationController.text,
//                               _latController.text,
//                               _longController.text,
//                               fileName,
//                               _commentsController.text.toString(),
//                               _assetIDController.text,
//                             );

//                             if (ticketId != null) {
//                               await createTicketDetails(
//                                   context,
//                                   _choosenRegionId,
//                                   _issueController.text,
//                                   _locationController.text,
//                                   _latController.text,
//                                   _longController.text,
//                                   _commentsController.text,
//                                   ticketId,
//                                   widget.createdBy);
//                               EasyLoading.dismiss();
//                               Navigator.pop(context);
//                               showSuccessAlert(context, ticketId);
//                             }
//                           } else {
//                             EasyLoading.showInfo(
//                                 "Please fill all required fields");
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF1D7569),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: const Text("  Submit Ticket  ",
//                               style:
//                                   TextStyle(color: Colors.white, fontSize: 16)),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
