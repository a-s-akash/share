import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../login_page/login_controller.dart';
import '../utils/app_theme.dart';
import '../utils/dialog_box.dart';
import '../utils/dropdown_options.dart';
import '../utils/utility.dart';

const priority = [
  'Priority',
  'Critical',
  'Major',
  'Minor',
  'Warning',
  'Indeterminate'
];

Future<void> showMaintenanceTicketCreationDialog(
  context,
  WidgetRef ref,
) async {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0))),
            insetPadding: const EdgeInsets.all(8.0),
            backgroundColor: Theme.of(context).canvasColor,
            content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.80,
                width: MediaQuery.of(context).size.width * 0.80,
                child: const MaintenanceTicketCreation()));
      });
}

class MaintenanceTicketCreation extends ConsumerWidget {
  const MaintenanceTicketCreation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextEditingController locationTextController =
        ref.watch(ticketController).locController;
    TextEditingController autoCompletecontroller =
        ref.watch(ticketController).autoCompletecontroller;
    TextEditingController creationCommentsController =
        ref.watch(ticketController).creationCommentsController;
    String assetType = ref.watch(deviceController).assetType;

    String smslcward = ref.watch(deviceController).smslcward;
    String smslczone = ref.watch(deviceController).smslczone;
    String smslcregion = ref.watch(deviceController).smslcregion;

    String ccmszone = ref.watch(deviceController).ccmszone;
    String ccmsregion = ref.watch(deviceController).ccmsregion;
    String ccmsward = ref.watch(deviceController).ccmsward;

    String usermail = ref.watch(loginController).userMail;
    String username = usermail.split("@").first.toUpperCase();
    String selectedProblemType =
        ref.watch(ticketController).selectedProblemType;
    String enteredTicketCreationComments =
        ref.watch(ticketController).enteredTicketCreationComments;
    String deviceOrAssetType = ref.read(ticketController).deviceOrAssetType;
    List<String> availableEntityTypes =
        ref.watch(ticketController).availableEntityTypes;

    bool validateMandatoryFields() {
      final bool isDeviceTypeValid = deviceOrAssetType != 'Device/Asset Type*';
      final bool isProblemTypeValid = selectedProblemType != 'Problem Type*';
      final bool isAutoCompleteValid = deviceOrAssetType != 'others'
          ? autoCompletecontroller.text.isNotEmpty
          : true;
      final bool isCommentValid =
          selectedProblemType != 'Others' && deviceOrAssetType != 'others'
              ? true
              : enteredTicketCreationComments.isNotEmpty;

      return isDeviceTypeValid &&
          isProblemTypeValid &&
          isAutoCompleteValid &&
          isCommentValid;
    }

    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Text(
              "Ticket Creation",
              style: TextStyle(color: Theme.of(context).cardColor),
            ),
          ),
          Divider(
              color: Theme.of(context).dialogTheme.backgroundColor,
              thickness: 0.5),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  height: 35,
                  width: deviceWidth * 0.25,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      border: Border.all(
                          width: 2,
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8))),
                  child: Center(
                    child: AutoSizeText(
                      assetType == 'ccms' ? ccmsregion : smslcregion,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  height: 35,
                  width: deviceWidth * 0.25,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      border: Border.all(
                          width: 2,
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8))),
                  child: Center(
                    child: AutoSizeText(
                      assetType == 'ccms' ? ccmszone : smslczone,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  height: 35,
                  width: deviceWidth * 0.25,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      border: Border.all(
                          width: 2,
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.8))),
                  child: Center(
                    child: AutoSizeText(
                      assetType == 'ccms' ? ccmsward : smslcward,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5.0),
            child: Divider(
                color: Theme.of(context).dialogTheme.backgroundColor,
                thickness: 0.5),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // selectedDeviceType != 'others' &&
              //         selectedDeviceType != 'Device/Asset Type*'
              Container(
                width: deviceWidth * 0.35,
                height: deviceHeight * 0.087,
                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: DropdownButtonFormField2<String>(
                  value: deviceOrAssetType,
                  items: availableEntityTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(context).secondaryHeaderColor),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(ticketController).updateSelectedFields(
                          context, ref, value, "deviceType", false,
                          isMaintenanceTicket: true);
                    }
                  },
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hoverColor,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelText: 'Device/Asset Type',
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  isExpanded: true,
                ),
              ),
              Container(
                width: deviceWidth * 0.35,
                height: deviceHeight * 0.087,
                padding: const EdgeInsets.only(top: 7, bottom: 7),
                child: TextField(
                  readOnly: true,
                  controller: autoCompletecontroller,
                  obscureText: false,
                  style: TextStyle(
                    fontSize: 13,
                    overflow: TextOverflow.ellipsis,
                    color: Theme.of(context).secondaryHeaderColor,
                  ),
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelStyle: TextStyle(
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                      labelText: 'Device/Asset Id',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                      hintText: autoCompletecontroller.text,
                      floatingLabelBehavior: FloatingLabelBehavior.always),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 7.0),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Container(
                color: Theme.of(context).dialogTheme.backgroundColor,
                margin: const EdgeInsets.all(6.0),
                child: SizedBox(
                  width: deviceWidth * 0.66,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      style: TextStyle(
                          color: Theme.of(context).secondaryHeaderColor),
                      maxLength: 250,
                      readOnly: (deviceOrAssetType == 'others') ? false : true,
                      controller: locationTextController,
                      decoration: InputDecoration(
                          counterText: "",
                          hintText: locationTextController.text,
                          hintStyle: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor,
                            fontSize: 12,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Icon(Icons.warning_amber,
                      size: 30, color: Theme.of(context).dividerColor),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isDense: true,
                    isExpanded: false,
                    value: selectedProblemType,
                    // items: problemTypes[
                    //         deviceOrAssetType.toString().toUpperCase()]!
                    items: fetchProblemTypes(
                            deviceOrAssetType.toString().toUpperCase())
                        .map((String items) {
                      return DropdownMenuItem(
                        alignment: AlignmentDirectional.centerStart,
                        value: items,
                        child: Text(
                          items,
                          style: TextStyle(
                              color: Theme.of(context).secondaryHeaderColor,
                              fontSize: 10),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != "Problem Type*") {
                        ref.read(ticketController).updateSelectedFields(
                            context, ref, newValue, "problemType", false);
                      }
                    },
                    dropdownStyleData: DropdownStyleData(
                        padding: const EdgeInsets.only(left: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Theme.of(context).canvasColor,
                        )),
                    buttonStyleData: ButtonStyleData(
                      height: 45,
                      width: deviceWidth * 0.67,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Theme.of(context).canvasColor,
                      ),
                      elevation: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.12,
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(left: 3, right: 3),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).hoverColor),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: creationCommentsController.text.isEmpty
                        ? RichText(
                            text: TextSpan(
                              text: 'Comments ',
                              style: TextStyle(
                                color: Theme.of(context).hoverColor,
                                fontSize: 14,
                              ),
                              children: deviceOrAssetType == 'others' ||
                                      selectedProblemType == 'Others'
                                  ? [
                                      TextSpan(
                                        text: '*',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .tabBarTheme
                                                .indicatorColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ]
                                  : [],
                            ),
                          )
                        : Container(),
                  ),
                ),
                TextField(
                  controller: creationCommentsController,
                  style:
                      TextStyle(color: Theme.of(context).secondaryHeaderColor),
                  onChanged: (value) {
                    ref.read(ticketController).updateSelectedFields(
                        context, ref, value, "comments", false);
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: deviceWidth * 0.78,
            decoration: BoxDecoration(
              color: Theme.of(context).hoverColor.withValues(alpha: 0.05),
              border:
                  Border.all(color: Theme.of(context).hoverColor, width: 0.6),
            ),
            margin: const EdgeInsets.only(top: 15),
            padding: const EdgeInsets.only(
              top: 14,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  width: deviceWidth * 0.83,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              Text(
                                'Open',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 3.0, bottom: 3.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.circle,
                                    size: 12,
                                    color: Theme.of(context).dividerColor),
                              ),
                              Text(
                                'Major',
                                style: TextStyle(
                                    color: Theme.of(context).dividerColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: deviceWidth * 0.83,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .hintColor
                                .withValues(alpha: 0.1),
                            border: Border.all(
                                color: Theme.of(context)
                                    .hintColor
                                    .withValues(alpha: 0.2),
                                width: 1)),
                        padding: const EdgeInsets.only(
                            top: 1.0, bottom: 1.0, left: 10),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.person_2_outlined,
                                    size: 15,
                                    color: Theme.of(context).hintColor),
                              ),
                              Expanded(
                                child: Text(
                                  username,
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        height: 40,
                        width: deviceWidth * 0.34,
                        padding: const EdgeInsets.only(
                            top: 1.0, bottom: 1.0, left: 10),
                        decoration: BoxDecoration(
                            color: warningColor.withValues(alpha: 0.1),
                            border: Border.all(
                                color: warningColor.withValues(alpha: 0.2),
                                width: 1)),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.person_2_outlined,
                                    size: 15, color: warningColor),
                              ),
                              Expanded(
                                child: Text(
                                  username,
                                  style: const TextStyle(
                                      color: warningColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 3,
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            height: 60,
            width: deviceWidth,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 40,
                    width: deviceWidth * 0.38,
                    decoration: BoxDecoration(
                        border: Border.all(
                            width: 0.9, color: Theme.of(context).hoverColor),
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                            color: Theme.of(context).secondaryHeaderColor),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Utility.isConnected().then(
                      (value) async {
                        if (value) {
                          if (validateMandatoryFields()) {
                            if (context.mounted) {
                              ref.read(ticketController).createTicketDetailsFB(
                                  context, ref, usermail, username);
                            }
                          }
                        } else {
                          if (context.mounted) {
                            await snackBar(
                                context,
                                ErrorMessages.offlineErrorTitle,
                                ErrorMessages.offlineErrorMessage);
                          }
                        }
                      },
                    );
                  },
                  child: Container(
                    height: 40,
                    width: deviceWidth * 0.38,
                    decoration: BoxDecoration(
                        color: validateMandatoryFields()
                            ? Theme.of(context).hintColor
                            : Theme.of(context).hoverColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        'CREATE',
                        style: TextStyle(
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
