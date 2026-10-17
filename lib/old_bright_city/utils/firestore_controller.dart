// import 'dart:developer';

// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'constants.dart';

// Future<dynamic> addComplaintToFireStoreDatabase(
//   String problemRegion,
//   String problemDescription,
//   String location,
//   String latitude,
//   String longitude,
//   String imagePath, [
//   String comments = '',
//   String device = "",
// ]) async {
//   // var dio = Dio();
//   CollectionReference users =
//       FirebaseFirestore.instance.collection('complaints');
//   //get the number of tickets
//   DocumentSnapshot ticketDoc = await FirebaseFirestore.instance
//       .collection('complaints')
//       .doc('ticket_counter')
//       .get();
//   //increment to create new ticket
//   int currentTicketCount = ticketDoc['ticket_count'] + 1;
//   String ticketId =
//       "PGA${currentTicketCount.toString().padLeft(6, '0')}"; //for PGA000000 pattern
//   DateTime now = DateTime.now();
//   String datetime = '${now.year}-'
//       '${now.month.toString().padLeft(2, '0')}-'
//       '${now.day.toString().padLeft(2, '0')} '
//       '${now.hour.toString().padLeft(2, '0')}:'
//       '${now.minute.toString().padLeft(2, '0')}:'
//       '${now.second.toString().padLeft(2, '0')}';
//   try {
//     //upload ticket to firestore database
//     await users.doc(ticketId).set({
//       "customer": customer,
//       "problem_description": problemDescription,
//       "location": location,
//       "latitude": latitude,
//       "longitude": longitude,
//       "comments": comments,
//       "device": device,
//       "id": ticketId,
//       "image_path":
//           imagePath == 'None' ? 'None' : '$s3BucketPath$imagePath.jpg',
//       "ticket_status": 'OPEN',
//       "ticket_opened_on": datetime,
//       "ticket_closedOn": '',
//       "region": problemRegion,
//     });
//     log("User Added");

//     await FirebaseFirestore.instance
//         .collection('complaints')
//         .doc('ticket_counter')
//         .update(
//             {'ticket_count': currentTicketCount});
//     return ticketId;
//   } catch (error) {
//     log("Failed to add user: $error");
//     return null;
//   }
// }

// Future<dynamic> updateFireStoreDatabase(dynamic data) async {
//   List<dynamic> data = [
//     {'name': 'Ambasamudram', 'id': '7d0ef370-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Ambur', 'id': '74861940-6109-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Anandpur', 'id': '133a3870-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Arani', 'id': 'f36c1730-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Arcot', 'id': '6ad8ed20-edbc-11ee-b37d-779a0c6cc934'},
//     {'name': 'Attur', 'id': ''},
//     {'name': 'Avadi', 'id': '009bf1f0-383b-11ee-8781-831a4b0b9a73'},
//     {'name': 'Ayodhya', 'id': '093d9a80-d074-11ee-bd33-5b7d398c3921'},
//     {'name': 'Balangir', 'id': '7bdbb9a0-f8c4-11ee-8458-0386ae2081a4'},
//     {'name': 'Balasore', 'id': '7505dc20-f0b1-11ee-b37d-779a0c6cc934'},
//     {'name': 'Baliguda', 'id': 'ee771a20-f8c6-11ee-8458-0386ae2081a4'},
//     {'name': 'Barbil', 'id': '186e2900-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Baripada', 'id': '314cbcc0-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Basudevpur', 'id': '5ed111f0-f8d0-11ee-8458-0386ae2081a4'},
//     {'name': 'Bhadrak', 'id': '8aa0ee80-f8d1-11ee-8458-0386ae2081a4'},
//     {'name': 'Bhavani', 'id': '8da06400-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Binika', 'id': '0d047a20-f8cf-11ee-8458-0386ae2081a4'},
//     {'name': 'Boudhgarh', 'id': '719be800-f8c6-11ee-8458-0386ae2081a4'},
//     {'name': 'Champua', 'id': '1ebead20-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Chandbali', 'id': '6e9ca960-f8d4-11ee-8458-0386ae2081a4'},
//     {'name': 'Chennai', 'id': ''},
//     {'name': 'Chidambaram', 'id': '34e71c40-efe3-11ee-b37d-779a0c6cc934'},
//     {'name': 'Chinnamanur', 'id': 'ccee5af0-efeb-11ee-b37d-779a0c6cc934'},
//     {'name': 'Cochin', 'id': ''},
//     {'name': 'Coimbatore', 'id': '32f94690-bb4c-11ee-927b-a1d8bdd723a7'},
//     {'name': 'Colachal', 'id': '3fbed850-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Cuddalore', 'id': 'e3f3f8d0-3c19-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Cumbum', 'id': 'de04acc0-efed-11ee-b37d-779a0c6cc934'},
//     {'name': 'Daspalla', 'id': 'c142b9a0-f8c7-11ee-8458-0386ae2081a4'},
//     {'name': 'Devakottai', 'id': '07dda1a0-6109-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Dhamnagar', 'id': 'bc105940-f8d3-11ee-8458-0386ae2081a4'},
//     {'name': 'Dharapuram', 'id': '52294ea0-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Edappadi', 'id': '0070d2c0-efe4-11ee-b37d-779a0c6cc934'},
//     {'name': 'Erode', 'id': 'beb071c0-3b24-11ee-a86c-2fb52b9a505b'},
//     {'name': 'G.Udayagiri', 'id': '7d48d6d0-f8c7-11ee-8458-0386ae2081a4'},
//     {'name': 'Goa', 'id': ''},
//     {'name': 'Gobichettipalayam', 'id': '80bb26d0-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Gudalur', 'id': 'a7544920-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Gudiyatham', 'id': '6fafc4d0-64f5-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Hosur', 'id': 'f192d4d0-3b23-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Jajpur', 'id': '0441f9c0-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Jaleswar', 'id': '2c155fe0-f0b1-11ee-b37d-779a0c6cc934'},
//     {'name': 'Joda', 'id': '256f0480-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Jolarpet', 'id': 'bf001330-efe0-11ee-b37d-779a0c6cc934'},
//     {'name': 'Kadayanallur', 'id': 'bc29bc70-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Kalakad', 'id': '66989ee0-cfc1-11ee-8434-3d23496c8339'},
//     {'name': 'Kallakurichi', 'id': 'f4869330-efea-11ee-b37d-779a0c6cc934'},
//     {'name': 'Kangeyam', 'id': ''},
//     {'name': 'Kantabanji NAC', 'id': 'c56e4240-f8c4-11ee-8458-0386ae2081a4'},
//     {'name': 'Karamadai', 'id': '2232c320-9592-11ee-bbef-d12c2a11ac0f'},
//     {'name': 'Karanjia', 'id': '376763d0-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Karumathampatti', 'id': '2a5680a0-9592-11ee-bbef-d12c2a11ac0f'},
//     {'name': 'Karur', 'id': '4de22ea0-7492-11ee-bbef-d12c2a11ac0f'},
//     {'name': 'Keelakarai', 'id': '1e07d400-5fba-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Keonjhargarh', 'id': '2b758750-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Khandapada', 'id': '206e5280-f8c9-11ee-8458-0386ae2081a4'},
//     {'name': 'Khariar', 'id': '72505c30-f8cc-11ee-8458-0386ae2081a4'},
//     {'name': 'Khariar Road', 'id': '189c61b0-f8cd-11ee-8458-0386ae2081a4'},
//     {'name': 'Kolkata Port', 'id': ''},
//     {'name': 'Kollencode', 'id': '53c752f0-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Kottakuppam', 'id': '1d08e3a0-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Krishnagiri', 'id': '739c1e90-efe3-11ee-b37d-779a0c6cc934'},
//     {'name': 'Kulithalai', 'id': 'eae073e0-3b1e-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Madukkarai', 'id': '8973a820-3b1e-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Madurai', 'id': '665c4040-3b23-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Madurantakam', 'id': '9159fdc0-38c9-11ee-8781-831a4b0b9a73'},
//     {'name': 'Manamadurai', 'id': '163546f0-5fbe-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Melvisharam', 'id': '28c6b150-64f5-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Mettupalayam', 'id': '3b0b56a0-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Mettur', 'id': '921a0ee0-efe3-11ee-b37d-779a0c6cc934'},
//     {'name': 'Narasingapuram', 'id': ''},
//     {'name': 'Nawada', 'id': 'ea0df0a0-9045-11ef-ba20-335f834668b9'},
//     {'name': 'Nayagarh', 'id': 'f56e5e30-f8c9-11ee-8458-0386ae2081a4'},
//     {'name': 'Nellikuppam', 'id': 'e438f260-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Nelliyalam', 'id': 'bf9ae080-3b1e-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Nilgiri', 'id': 'c5817f60-f0b1-11ee-b37d-779a0c6cc934'},
//     {'name': 'Nuapada', 'id': 'c5e557f0-f8cd-11ee-8458-0386ae2081a4'},
//     {'name': 'Odagaon', 'id': '7b7dfa80-f8ca-11ee-8458-0386ae2081a4'},
//     {'name': 'Palladam', 'id': '6da52280-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Pallapatti', 'id': ''},
//     {'name': 'Panruti', 'id': '97264260-3c19-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Paramakudi', 'id': '01d177d0-5fbc-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Patnagarh', 'id': '5f7a9960-f8c5-11ee-8458-0386ae2081a4'},
//     {'name': 'Periyakulam', 'id': '29ca7070-efeb-11ee-b37d-779a0c6cc934'},
//     {'name': 'Pernambut', 'id': '1255bc40-6473-11ef-9046-39d36dd2ed2d'},
//     {'name': 'Phulbani', 'id': '352d5dd0-f8c7-11ee-8458-0386ae2081a4'},
//     {'name': 'Pollachi', 'id': '33e58120-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Ponneri', 'id': 'd62a2950-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Punjaipuliyampatti', 'id': ''},
//     {'name': 'RNC', 'id': 'e6ceecd0-06da-11eb-8e81-17b2b2035196'},
//     {'name': 'Raigangpur', 'id': '3d73b300-f0ba-11ee-b37d-779a0c6cc934'},
//     {'name': 'Ramanathapuram', 'id': '4b4554b0-be75-11ee-ada9-9b151162fde9'},
//     {'name': 'Ranchi', 'id': '5911dd50-4884-11ee-8e42-bd1ba4c1b5e8'},
//     {'name': 'Ranpur', 'id': 'cdb53b00-f8cb-11ee-8458-0386ae2081a4'},
//     {'name': 'Remuna', 'id': '537d1140-f0bb-11ee-b37d-779a0c6cc934'},
//     {'name': 'Salem', 'id': ''},
//     {'name': 'Sankarankovil', 'id': '993c9cf0-3b21-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Sathyamangalam', 'id': '88174e90-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Sengottai', 'id': 'aa98d180-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Sholinghur', 'id': '9e9c3500-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Sivagangai', 'id': '401dcd10-be75-11ee-ada9-9b151162fde9'},
//     {'name': 'Sivakasi', 'id': 'c6c5ccf0-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Sonepur', 'id': '56e9d320-f8ce-11ee-8458-0386ae2081a4'},
//     {'name': 'Soro', 'id': '59e40390-f0bb-11ee-b37d-779a0c6cc934'},
//     {'name': 'Tambaram', 'id': 'a05b4370-3c06-11ee-a86c-2fb52b9a505b'},
//     {'name': 'TamilNadu', 'id': ''},
//     {'name': 'Tanjore', 'id': ''},
//     {'name': 'Tarbha', 'id': '918e87e0-f8cf-11ee-8458-0386ae2081a4'},
//     {'name': 'Thiruchendur', 'id': '8e760f40-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Thirukovilur', 'id': 'ad66d400-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Thirumuruganpoondi', 'id': ''},
//     {'name': 'Thirutanni', 'id': '30ebfbf0-c9a6-11ee-8711-19f6da6eacaf'},
//     {'name': 'Thiruvannamalai', 'id': ''},
//     {'name': 'Thiruverkadu', 'id': 'cd307ce0-3c19-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Tirumangalam', 'id': '057606a0-efee-11ee-b37d-779a0c6cc934'},
//     {'name': 'Tirunelveli', 'id': ''},
//     {'name': 'Tirupathur', 'id': 'd02d8160-efe0-11ee-b37d-779a0c6cc934'},
//     {'name': 'Tiruppur', 'id': '4b8bd220-3b24-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Tiruvannamalai', 'id': '250eddd0-efe3-11ee-b37d-779a0c6cc934'},
//     {'name': 'Titilagarh', 'id': 'a5f55ab0-f8c5-11ee-8458-0386ae2081a4'},
//     {'name': 'Trichy', 'id': '2b4a3860-8ea0-11ee-bbef-d12c2a11ac0f'},
//     {'name': 'Tusura', 'id': '0431a700-f8c6-11ee-8458-0386ae2081a4'},
//     {'name': 'Udala', 'id': '5f7381a0-f0bb-11ee-b37d-779a0c6cc934'},
//     {'name': 'Udumalaipettai', 'id': ''},
//     {'name': 'Ulundurpettai', 'id': 'b9f1e340-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Vandavasi', 'id': 'c7a741b0-383a-11ee-8781-831a4b0b9a73'},
//     {'name': 'Vaniyambadi', 'id': '272e3460-edbf-11ee-b37d-779a0c6cc934'},
//     {'name': 'Vellakovil', 'id': '7516f520-cbfc-11ee-af7e-752511d00849'},
//     {'name': 'Vellore', 'id': 'ff41f290-b6b2-11ee-a8a0-335989a228dd'},
//     {'name': 'Viluppuram', 'id': ''},
//     {'name': 'Virudhachalam', 'id': 'b493fb30-3c19-11ee-a86c-2fb52b9a505b'},
//     {'name': 'Vyasnagar', 'id': '0c31aef0-f0ba-11ee-b37d-779a0c6cc934'},
//   ];

//   DocumentReference db =
//       FirebaseFirestore.instance.collection('utils').doc('region_list');

//   try {
//     await db.update({
//       "regions": FieldValue.arrayUnion(data),
//     });
//     log("done");
//     return true;
//   } catch (error) {
//     log("Failed: $error");
//     return null;
//   }
// }
