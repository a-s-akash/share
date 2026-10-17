import 'dart:developer';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../device_page/device_controller.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../utils/dialog_box.dart';
import '../utils/dropdown_options.dart';
import 'ticket_controller.dart';
import 'ticket_list_page.dart';
import 'ticket_model.dart';
import '../survey/screens/survey_take_photo.dart';

class TicketDetailsPage extends ConsumerWidget {
  const TicketDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;

    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String usermail = ref.watch(loginController).userMail;
    String eneteredComment = ref.watch(ticketController).eneteredComment;
    bool isTicketsOfSpecificDevice =
        ref.watch(ticketController).isTicketsOfSpecificDevice;
    String usernmae = usermail.split("@").first.toUpperCase();
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    String newTicketStatus = ref.watch(ticketController).newTicketStatus;
    bool isComponentChangeEnabled =
        ref.watch(ticketController).isComponentChangeEnabled;
    String newComponentsChangedValue =
        ref.watch(ticketController).newComponentsChangedValue;
    String newIssuesIdentifiedValue =
        ref.watch(ticketController).newIssuesIdentifiedValue;
    bool isComponentChangeFieldEnabled =
        ref.watch(ticketController).isComponentChangeFieldEnabled;
    Ticket ticket = ref.watch(ticketController).selectedTicekt;
    // List<String> componentsFieldList =
    //     componenetsChanged[ticket.deviceType.toString().toUpperCase()]!;
    // List<String> issuesFieldList =
    //     issuesIdentified[ticket.deviceType.toString().toUpperCase()]!;
    List<String> issuesFieldList =
        fetchIssuesIdentified(ticket.deviceType.toString().toUpperCase());

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          // Offline, a refetch would only return Firestore's cached copy and
          // wipe out locally-applied queued updates — keep the current list.
          if (!isTicketsOfSpecificDevice && ref.read(internetStatusProvider)) {
            EasyLoading.show(status: 'loading...', dismissOnTap: false);
            await ref
                .read(ticketController)
                .getTicketsBasedOnStatusFB(context, ref, 'Pending')
                .then((value) {
              EasyLoading.dismiss();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TicketListPage()),
                );
              }
            });
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(builder: (BuildContext context) {
              return isTicketsOfSpecificDevice
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.menu,
                        color: Theme.of(context).cardColor,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    );
            }),
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.19),
            elevation: 0.0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 18.0,
            ),
            title: Text(
              ticket.ticketId ?? 'Ticket Details',
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          drawer: customHomeDrawer(
            usernmae,
            usermail,
            context,
            ref,
          ),
          body: ConnectivityBanner(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      if (!isTicketsOfSpecificDevice)
                        const SizedBox(
                          height: 5,
                        ),
                      if (!isTicketsOfSpecificDevice)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: SelectedLocationData(
                              selectedCustomer: selectedCustomer,
                              selectedRegion: selectedRegion,
                              selectedZone: selectedZone,
                              selectedWard: selectedWard),
                        ),
                      Container(
                        color: Theme.of(context).dialogTheme.backgroundColor,
                        height: isTicketsOfSpecificDevice
                            ? deviceHeight * 0.89
                            : deviceHeight * 0.83,
                        width: deviceWidth,
                        child: Column(
                          children: [
                            if (isTicketsOfSpecificDevice)
                              const SizedBox(
                                height: 15,
                              ),
                            if (!isTicketsOfSpecificDevice)
                              Container(
                                  margin: const EdgeInsets.only(
                                      top: 4, left: 8, right: 8, bottom: 4),
                                  child: TicketDetailsCard(ticket)),
                            Container(
                              margin: const EdgeInsets.only(
                                  left: 12, right: 12, bottom: 5),
                              width: deviceWidth,
                              // height: deviceHeight * 0.12,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).canvasColor,
                                  border: Border.all(
                                    width: 0.4,
                                    color: Theme.of(context).hoverColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton2(
                                            isDense: true,
                                            isExpanded: false,
                                            value:
                                                newIssuesIdentifiedValue == ''
                                                    ? issuesFieldList[0]
                                                    : newIssuesIdentifiedValue,
                                            items: issuesFieldList
                                                .map((String items) {
                                              return DropdownMenuItem(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                value: items,
                                                child: Text(
                                                  items,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .secondaryHeaderColor,
                                                      fontSize: 10),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              ref
                                                  .read(ticketController)
                                                  .updateTicketStatus(
                                                      'issues',
                                                      newValue !=
                                                              "Issues Identified"
                                                          ? newValue!
                                                          : "");

                                              log('Selected Issue identified = $newValue');
                                            },
                                            dropdownStyleData:
                                                DropdownStyleData(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 1),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              3),
                                                      color: Theme.of(context)
                                                          .canvasColor,
                                                    )),
                                            buttonStyleData: ButtonStyleData(
                                              height: deviceHeight * 0.044,
                                              width: deviceWidth * 0.50,
                                              padding: const EdgeInsets.only(
                                                  left: 10, right: 10),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: Theme.of(context)
                                                    .canvasColor,
                                                border: Border.all(
                                                    color: Theme.of(context)
                                                        .cardColor,
                                                    width: 0.5),
                                              ),
                                              // elevation: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // const SizedBox(width: 8),
                                      const Spacer(),
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Checkbox(
                                            value:
                                                isComponentChangeFieldEnabled,
                                            visualDensity:
                                                VisualDensity.compact,
                                            onChanged: (value) {
                                              isComponentChangeEnabled
                                                  ? ref
                                                      .read(ticketController)
                                                      .changeComponenetChangedFieldValue()
                                                  : null;
                                            }),
                                      ),
                                      Text(
                                        "Components\nChanged",
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: isComponentChangeEnabled
                                              ? Theme.of(context)
                                                  .secondaryHeaderColor
                                              : Theme.of(context)
                                                  .unselectedWidgetColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                  // if (isComponentChangeFieldEnabled &&
                                  //     ["ILM", "Lamp", "Gateway", "Meter"]
                                  //         .contains(newIssuesIdentifiedValue))
                                  //   Padding(
                                  //     padding: const EdgeInsets.fromLTRB(12, 5, 12, 10),
                                  //     child: TextField(
                                  //       controller: ref
                                  //           .read(ticketController)
                                  //           .replacedEntityNameController,
                                  //       onChanged: (value) => ref
                                  //           .read(ticketController)
                                  //           .componentIdUpdate(value),
                                  //       decoration: InputDecoration(
                                  //         isDense: true,
                                  //         hintText:
                                  //             'Enter $newIssuesIdentifiedValue ID',
                                  //         hintStyle: const TextStyle(fontSize: 12),
                                  //         border: OutlineInputBorder(
                                  //           borderRadius: BorderRadius.circular(5),
                                  //         ),
                                  //         contentPadding: const EdgeInsets.symmetric(
                                  //             horizontal: 10, vertical: 10),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // Padding(
                                  //   padding: const EdgeInsets.only(left: 6.0),
                                  //   child: Row(
                                  //     children: [
                                  //       DropdownButtonHideUnderline(
                                  //         child: DropdownButton2(
                                  //           isDense: true,
                                  //           isExpanded: false,
                                  //           value: newComponentsChangedValue == ''
                                  //               ? componentsFieldList[0]
                                  //               : newComponentsChangedValue,
                                  //           items:
                                  //               componentsFieldList.map((String items) {
                                  //             return DropdownMenuItem(
                                  //               alignment:
                                  //                   AlignmentDirectional.centerStart,
                                  //               value: items,
                                  //               child: Text(
                                  //                 items,
                                  //                 style: TextStyle(
                                  //                     color:
                                  //                         isComponentChangeFieldEnabled
                                  //                             ? Theme.of(context)
                                  //                                 .secondaryHeaderColor
                                  //                             : Theme.of(context)
                                  //                                 .unselectedWidgetColor,
                                  //                     fontSize: 10),
                                  //               ),
                                  //             );
                                  //           }).toList(),
                                  //           onChanged: isComponentChangeFieldEnabled
                                  //               ? (newValue) {
                                  //                   Utility.isConnected()
                                  //                       .then((value) async {
                                  //                     if (value) {
                                  //                       ref
                                  //                           .read(ticketController)
                                  //                           .updateTicketStatus(
                                  //                               'components',
                                  //                               newValue !=
                                  //                                       "Components Changed"
                                  //                                   ? newValue!
                                  //                                   : "");

                                  //                       log('Selected componenet = $newValue');
                                  //                     } else {
                                  //                       if (context.mounted) {
                                  //                         await snackBar(
                                  //                             context,
                                  //                             ErrorMessages
                                  //                                 .offlineErrorTitle,
                                  //                             ErrorMessages
                                  //                                 .offlineErrorMessage);
                                  //                       }
                                  //                     }
                                  //                   });
                                  //                 }
                                  //               : null,
                                  //           dropdownStyleData: DropdownStyleData(
                                  //               padding: const EdgeInsets.only(left: 1),
                                  //               decoration: BoxDecoration(
                                  //                 borderRadius:
                                  //                     BorderRadius.circular(3),
                                  //                 color: Theme.of(context).canvasColor,
                                  //               )),
                                  //           buttonStyleData: ButtonStyleData(
                                  //             height: deviceHeight * 0.044,
                                  //             width: deviceWidth * 0.44,
                                  //             padding: const EdgeInsets.only(
                                  //                 left: 10, right: 10),
                                  //             decoration: BoxDecoration(
                                  //               borderRadius: BorderRadius.circular(3),
                                  //               color: Theme.of(context).canvasColor,
                                  //             ),
                                  //             elevation: 1,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //       const SizedBox(width: 5),
                                  //       DropdownButtonHideUnderline(
                                  //         child: DropdownButton2(
                                  //           isDense: true,
                                  //           isExpanded: false,
                                  //           value: newIssuesIdentifiedValue == ''
                                  //               ? issuesFieldList[0]
                                  //               : newIssuesIdentifiedValue,
                                  //           items: issuesFieldList.map((String items) {
                                  //             return DropdownMenuItem(
                                  //               alignment:
                                  //                   AlignmentDirectional.centerStart,
                                  //               value: items,
                                  //               child: Text(
                                  //                 items,
                                  //                 style: TextStyle(
                                  //                     color:
                                  //                         isComponentChangeFieldEnabled
                                  //                             ? Theme.of(context)
                                  //                                 .secondaryHeaderColor
                                  //                             : Theme.of(context)
                                  //                                 .unselectedWidgetColor,
                                  //                     fontSize: 10),
                                  //               ),
                                  //             );
                                  //           }).toList(),
                                  //           onChanged: isComponentChangeFieldEnabled
                                  //               ? (newValue) {
                                  //                   Utility.isConnected()
                                  //                       .then((value) async {
                                  //                     if (value) {
                                  //                       ref
                                  //                           .read(ticketController)
                                  //                           .updateTicketStatus(
                                  //                               'issues',
                                  //                               newValue !=
                                  //                                       "Issues Identified"
                                  //                                   ? newValue!
                                  //                                   : "");

                                  //                       log('Selected Issue identified = $newValue');
                                  //                     } else {
                                  //                       if (context.mounted) {
                                  //                         await snackBar(
                                  //                             context,
                                  //                             ErrorMessages
                                  //                                 .offlineErrorTitle,
                                  //                             ErrorMessages
                                  //                                 .offlineErrorMessage);
                                  //                       }
                                  //                     }
                                  //                   });
                                  //                 }
                                  //               : null,
                                  //           dropdownStyleData: DropdownStyleData(
                                  //               padding: const EdgeInsets.only(left: 1),
                                  //               decoration: BoxDecoration(
                                  //                 borderRadius:
                                  //                     BorderRadius.circular(3),
                                  //                 color: Theme.of(context).canvasColor,
                                  //               )),
                                  //           buttonStyleData: ButtonStyleData(
                                  //             height: deviceHeight * 0.044,
                                  //             width: deviceWidth * 0.44,
                                  //             padding: const EdgeInsets.only(
                                  //                 left: 10, right: 10),
                                  //             decoration: BoxDecoration(
                                  //               borderRadius: BorderRadius.circular(3),
                                  //               color: Theme.of(context).canvasColor,
                                  //             ),
                                  //             elevation: 1,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //       const SizedBox(width: 10),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            CommentSection(
                                deviceWidth: deviceWidth,
                                deviceHeight: deviceHeight),
                            Container(
                              padding: const EdgeInsets.only(left: 15),
                              width: deviceWidth,
                              height: 50,
                              decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .dialogTheme
                                      .backgroundColor,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton2(
                                      isDense: true,
                                      isExpanded: false,
                                      value: newTicketStatus == ''
                                          ? statusTransitionMap[ticket
                                              .ticketStatus
                                              .toString()]![0]
                                          : newTicketStatus,
                                      items: statusTransitionMap[
                                              ticket.ticketStatus.toString()]!
                                          .map((String items) {
                                        return DropdownMenuItem(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          value: items,
                                          child: Text(
                                            items,
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .secondaryHeaderColor,
                                                fontSize: 10),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        if (statusTransitionMap[ticket
                                                .ticketStatus
                                                .toString()]![0] !=
                                            newValue) {
                                          ref
                                              .read(ticketController)
                                              .updateTicketStatus(
                                                  'status',
                                                  newValue !=
                                                          "Ticket Status (ALL)"
                                                      ? newValue!
                                                      : "");
                                          log('Selected ticket status = $newValue');
                                        }
                                      },
                                      dropdownStyleData: DropdownStyleData(
                                          padding:
                                              const EdgeInsets.only(left: 1),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            color:
                                                Theme.of(context).canvasColor,
                                          )),
                                      buttonStyleData: ButtonStyleData(
                                        height: 35,
                                        width: deviceWidth * 0.45,
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          color: Theme.of(context).canvasColor,
                                        ),
                                        elevation: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    height: 35,
                                    width: deviceWidth * 0.45,
                                    padding: const EdgeInsets.only(
                                        left: 14, right: 14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: Theme.of(context).canvasColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .unselectedWidgetColor
                                              .withValues(alpha: 0.3),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: const Offset(
                                              0, 1), // Adjust the shadow offset
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person_2_outlined,
                                            color: Theme.of(context)
                                                .unselectedWidgetColor,
                                            size: 16,
                                          ),
                                          Text(
                                            ticket.assignee ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .hoverColor,
                                                fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            ),
                            // const Spacer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 10),
                    height: 50,
                    width: deviceWidth,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 40,
                            width: deviceWidth * 0.3,
                            decoration: BoxDecoration(
                                color: Theme.of(context).secondaryHeaderColor,
                                border: Border.all(
                                    width: 0.9,
                                    color:
                                        Theme.of(context).secondaryHeaderColor),
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            // Goes live when online, otherwise queued offline
                            // (see TicketRepository.submitUpdate).
                            if (ref.read(ticketController).canUpdate) {
                              final ticketUpdated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CaptureThreeImagesScreen(
                                    capturedImages: ref
                                        .watch(ticketController)
                                        .fetchedCapturedImages,
                                    isForTicket: true,
                                    isForTicketUpdate: true,
                                    ticketToUpdate: ticket,
                                    comment: eneteredComment,
                                    usermail: usermail,
                                    username: usernmae,
                                  ),
                                ),
                              );

                              if (ticketUpdated == true && context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: Container(
                            height: 40,
                            width: deviceWidth * 0.6,
                            decoration: BoxDecoration(
                                color: ref.watch(ticketController).canUpdate
                                    ? Theme.of(context).hintColor
                                    : Theme.of(context).unselectedWidgetColor,
                                borderRadius: BorderRadius.circular(8)),
                            child: Center(
                              child: Text(
                                'Proceed with Photo',
                                style: TextStyle(
                                    color: Theme.of(context).canvasColor),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommentSection extends ConsumerWidget {
  const CommentSection({
    super.key,
    required this.deviceWidth,
    required this.deviceHeight,
  });

  final double deviceWidth;
  final double deviceHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Ticket ticket = ref.watch(ticketController).selectedTicekt;
    // List<Comments> comments = ref.watch(ticketController).comments;
    // Updates that went through the offline queue reach the server (and the
    // pending-update overlay) with an empty `comment` and each comment as a
    // "Commented: ..." action instead — surface those as comments too.
    List<dynamic> comments = [];
    for (final entry in ticket.auditTrail ?? []) {
      if (entry is! Map) continue;
      if ((entry['comment']?.toString() ?? '').isNotEmpty) {
        comments.add(entry);
        continue;
      }
      for (final action in List.from(entry['actions'] ?? [])) {
        final text = action.toString();
        if (text.startsWith('Commented: ')) {
          comments.add({
            ...entry,
            'comment': text.substring('Commented: '.length),
          });
        }
      }
    }
    comments = comments.reversed.toList();
    String eneteredComment = ref.watch(ticketController).eneteredComment;
    TextEditingController commentController =
        ref.watch(ticketController).commentController;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: deviceWidth,
      height: comments.isNotEmpty ? deviceHeight * 0.297 : deviceHeight * 0.086,
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          border: Border.all(width: 0.4, color: Theme.of(context).hoverColor),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          SizedBox(
            height: deviceHeight * 0.084,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).cardColor,
                    child: const Icon(
                      Icons.person_2_outlined,
                      size: 14,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        maxLength: 250,
                        controller: commentController,
                        onChanged: (value) =>
                            ref.read(ticketController).textFieldUpdate(value),
                        decoration: InputDecoration(
                            counterText: "",
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(
                                fontSize: 14,
                                color:
                                    Theme.of(context).unselectedWidgetColor)),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Goes live when online, otherwise queued offline
                      // (see TicketRepository.submitUpdate).
                      if (eneteredComment != '') {
                        ref.read(ticketController).updateTicketCommentFB(
                            context, ref, ticket, eneteredComment);
                        //  ref.read(ticketController).updateTicketComment(
                        // context, ref, ticket, eneteredComment);
                      }
                    },
                    icon: Icon(
                      Icons.send,
                      color: eneteredComment == ''
                          ? Theme.of(context).unselectedWidgetColor
                          : Theme.of(context).cardColor,
                    ),
                  )
                ],
              ),
            ),
          ),
          if (comments.isNotEmpty)
            Divider(
                color: Theme.of(context).hoverColor,
                thickness: 0.5,
                height: 0.2),
          if (comments.isNotEmpty)
            SizedBox(
              height: deviceHeight * 0.21,
              width: deviceWidth,
              child: ListView.builder(
                itemCount: comments.length,
                itemBuilder: (BuildContext context, int index) {
                  if (comments[index]['comment'] == null ||
                      comments[index]['comment'] == '') {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                    width: deviceWidth,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              margin: const EdgeInsets.only(top: 5, right: 8),
                              height: deviceHeight * 0.035,
                              width: 25,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  comments[index]['by'][0] ?? '',
                                  style: TextStyle(
                                      color: Theme.of(context).canvasColor,
                                      fontSize: 10),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: deviceWidth * 0.55,
                                      height: deviceHeight * 0.02,
                                      child: Text(
                                        comments[index]['by'] ?? '',
                                        maxLines: 2,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: deviceWidth * 0.24,
                                      child: Text(
                                        textAlign: TextAlign.end,
                                        comments[index]['on'] != null &&
                                                comments[index]['on']
                                                        .toString() !=
                                                    ''
                                            ? ref
                                                .read(ticketController)
                                                .getDurationFB(
                                                    comments[index]['on'])
                                            : '',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    )
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.only(top: 5),
                                  width: deviceWidth * 0.79,
                                  child: Text(
                                    textAlign: TextAlign.start,
                                    comments[index]['comment'] ?? '',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).hoverColor),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Divider(
                              color: Theme.of(context).hoverColor,
                              thickness: 0.2,
                              height: 0.2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
        ],
      ),
    );
  }
}
