import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../device_page/device_controller.dart';
import '../survey/survey_controller.dart';

class UsableWidgets {
  static Widget projContextContainerInMaintenace(
      BuildContext context, WidgetRef ref, region, zone, ward, onTapCall) {
    String selectedWardDesc = ref.watch(deviceController).selectedWardDesc;

    return GestureDetector(
      onTap: onTapCall,
      child: Container(
        margin: const EdgeInsets.only(left: 22, right: 22, top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined,
                color: Theme.of(context).cardColor),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        region,
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_outlined,
                          color: Theme.of(context).cardColor, size: 18),
                      Text(
                        zone,
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.chevron_right_outlined,
                          color: Theme.of(context).cardColor, size: 18),
                      Expanded(
                        child: Text(
                          ward,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (selectedWardDesc.isNotEmpty)
                    Text(
                      selectedWardDesc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Theme.of(context).cardColor.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget selectedContextContainer(
      BuildContext context, WidgetRef ref, locationContext) {
    return Container(
      margin: const EdgeInsets.only(
        left: 2,
        right: 22,
      ),
      height: 30,
      // width:
      //     MediaQuery.of(context).size.width / 2.4,
      decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ),
          borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                locationContext,
                style: TextStyle(
                    color: Theme.of(context).secondaryHeaderColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
        ]),
      ),
    );
  }

  static Widget projContextContainerInHistory(
    BuildContext context,
    String selectedRegion,
    String selectedZone,
    String selectedWard,
    String selectedWardDesc,
  ) {
    return Container(
      // width: 260,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: Theme.of(context).cardColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    selectedRegion,
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right_outlined,
                      color: Theme.of(context).cardColor, size: 18),
                  Text(
                    selectedZone,
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.chevron_right_outlined,
                      color: Theme.of(context).cardColor, size: 18),
                  Text(
                    selectedWard,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).cardColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (selectedWardDesc.isNotEmpty)
                Text(
                  selectedWardDesc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  // static Widget projContextContainerInMaintenace(
  //     BuildContext context, WidgetRef ref, region, zone, ward, onTapCall) {
  //   return GestureDetector(
  //     onTap: () {
  //       onTapCall;
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.only(left: 22, right: 22, top: 10),
  //       height: 50,
  //       decoration: BoxDecoration(
  //           color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
  //           borderRadius: BorderRadius.circular(18)),
  //       child: Center(
  //         child: Padding(
  //           padding: const EdgeInsets.all(6.0),
  //           child: Align(
  //             alignment: Alignment.centerLeft,
  //             child: FittedBox(
  //               fit: BoxFit.contain,
  //               child:
  //                   Row(mainAxisAlignment: MainAxisAlignment.start, children: [
  //                 Icon(Icons.location_on_outlined,
  //                     color: Theme.of(context).cardColor),
  //                 const SizedBox(
  //                   width: 5,
  //                 ),
  //                 Text(
  //                   region,
  //                   style: TextStyle(
  //                       color: Theme.of(context).cardColor,
  //                       fontWeight: FontWeight.bold),
  //                 ),
  //                 Icon(Icons.chevron_right_outlined,
  //                     color: Theme.of(context).cardColor),
  //                 Text(
  //                   zone,
  //                   style: TextStyle(
  //                       color: Theme.of(context).cardColor,
  //                       fontWeight: FontWeight.bold),
  //                 ),
  //                 Icon(Icons.chevron_right_outlined,
  //                     color: Theme.of(context).cardColor),
  //                 Text(
  //                   ward,
  //                   style: TextStyle(
  //                       color: Theme.of(context).cardColor,
  //                       fontWeight: FontWeight.bold),
  //                 )
  //               ]),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  static Widget buildDropdown(
    BuildContext context, {
    String? value,
    required String? label,
    required List<dynamic> items,
    required void Function(String?) onChanged,
    bool isEditable = true,
  }) {
    // Ensure value is valid or set to null if not found
    if (!isEditable) {
      items = [value];
    }
    final validValue = (value != null && items.contains(value)) ? value : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard before showing dropdown
          FocusScope.of(context).unfocus();
        },
        child: DropdownButtonFormField2<String>(
          hint: Text('Select',
              style: TextStyle(
                  color: Theme.of(context).secondaryHeaderColor, fontSize: 13)),
          isExpanded: true,
          value: validValue,
          decoration: InputDecoration(
            // hintStyle: TextStyle(color: Theme.of(context).secondaryHeaderColor),
            labelText: label,
            labelStyle: TextStyle(
                fontSize: 17,
                color: const Color(0xF8407CA1).withValues(alpha: 0.8),
                fontWeight: FontWeight.bold),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.toSet().map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 12, color: Colors.black),
              ),
            );
          }).toList(),
          buttonStyleData: const ButtonStyleData(height: 41),
          onChanged: isEditable ? onChanged : null,
          dropdownStyleData: DropdownStyleData(
            elevation: 2,
            offset: const Offset(0, 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          menuItemStyleData: MenuItemStyleData(
            height: 48,
            overlayColor: WidgetStatePropertyAll(Colors.grey.shade100),
          ),
        ),
      ),
    );
  }

  static Widget yesNoToggle(WidgetRef ref, BuildContext context, String label,
      selectedValue, canToggle) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            ToggleSwitch(
              changeOnTap: canToggle,
              minWidth: 80,
              cornerRadius: 12,
              activeBgColors: [
                [
                  const Color.fromARGB(248, 64, 124, 161).withValues(alpha: 0.8)
                ],
                [const Color.fromARGB(248, 64, 124, 161).withValues(alpha: 0.8)]
              ],
              activeFgColor: Colors.white,
              inactiveBgColor: Colors.grey[300],
              inactiveFgColor: Colors.black,
              totalSwitches: 2,
              labels: const ['Yes', 'No'],
              initialLabelIndex: selectedValue ? 0 : 1,
              onToggle: (index) {
                if (!canToggle) return;

                final isYes = index == 0;
                ref
                    .read(surveyController)
                    .updateSurveyFieldValues(context, ref, isYes, label);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget assetCountContainer(context, value, IconData icon) {
    return FittedBox(
      child: Container(
        height: 50,
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
