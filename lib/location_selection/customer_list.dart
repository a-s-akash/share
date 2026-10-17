import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/location_selection/region_list.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../ticket_notification/ticket_controller.dart';
import '../utils/dialog_box.dart';
import 'location_controller.dart';

class CustomerList extends ConsumerStatefulWidget {
  const CustomerList({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends ConsumerState<CustomerList> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    List<Customer> customerList = ref.watch(locationController).customerList;
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;

    /// Filter customers
    List<Customer> filteredList = customerList
        .where((element) =>
            element.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
    return SafeArea(
      child: WillPopScope(
          onWillPop: () async {
            showExitPopup(context);
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              leading: selectedCustomer == ''
                  ? null
                  : IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      color: Theme.of(context).cardColor,
                    ),
              automaticallyImplyLeading: false,
              backgroundColor:
                  Theme.of(context).primaryColor.withValues(alpha: 0.19),
              elevation: 0.0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color,
                fontSize: 18.0,
              ),
              title: Text(
                "PROJECT CONTEXT",
                style: TextStyle(
                    color: Theme.of(context).cardColor,
                    fontWeight: FontWeight.w500),
              ),
              actions: [
                IconButton(
                  tooltip: 'logout',
                  onPressed: () {
                    logoutPop(context, ref);
                    // showVehicleDetailsDialog(context, ref);
                  },
                  icon: Icon(
                    Icons.logout_outlined,
                    size: 27,
                    color: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
            body: ConnectivityBanner(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 15.0),
                          child: SelectedLocationData(
                              selectedCustomer: selectedCustomer,
                              selectedRegion: selectedRegion,
                              selectedZone: selectedZone,
                              selectedWard: selectedWard,
                              selectedRoute: 'customer'),
                        ),
                      ),
                    ],
                  ),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                      maxLength: 20,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(16.0),
                        hintText: 'Search customer',
                        counterText: '',
                        hintStyle: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.19),
                      ),
                    ),
                  ),

                  // Customer List
                  Expanded(
                    child: customerList.isEmpty
                        ? const EmptyView()
                        : filteredList.isEmpty
                            ? const EmptyView()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  return CustomerItem(
                                    customer: filteredList[index],
                                    keyContext: context,
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}

Future<bool> showExitPopup(context) async {
  var bg = Theme.of(context).dialogTheme.backgroundColor;
  return await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: bg,
        content: Container(
          height: 100,
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Are you sure you want to exit?",
                  style: TextStyle(
                    color: Theme.of(context).secondaryHeaderColor,
                  )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (kDebugMode) {
                          log('yes selected');
                        }
                        exit(0);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).tabBarTheme.indicatorColor,
                      ),
                      child: Text(
                        "Yes",
                        style: TextStyle(
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (kDebugMode) {
                          log('no selected');
                        }
                        Navigator.of(context).pop(false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).textTheme.bodySmall!.color,
                      ),
                      child: Text(
                        "No",
                        style: TextStyle(
                          color: Theme.of(context).canvasColor,
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      );
    },
  );
}

class CustomerItem extends ConsumerWidget {
  final Customer customer;
  final BuildContext keyContext;

  const CustomerItem({
    Key? key,
    required this.customer,
    required this.keyContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 3, right: 3, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).unselectedWidgetColor),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, left: 40.0),
          child: Text(
            customer.name,
            style: TextStyle(
              color: Theme.of(context).cardColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      onTap: () async {
        // Utility.isConnected().then((value) async {
        // if (value) {
        EasyLoading.show(status: 'loading...', dismissOnTap: false);
        await ref
            .read(ticketController)
            .updateSelectedAssetId(customer.id, 'customer', customer.name);
        ref
            .read(deviceController)
            .updatedSelectedCustomer(customer.name, customer.id);
        ref.read(deviceController).updateSelectedLocation(ref, 'customer', '');
        String userMail = ref.read(loginController).userMail;
        await ref
            .read(locationController)
            .loadRegionList(userMail, customer.id);
        // if (context.mounted) {
        //   ref
        //       .read(locationController)
        //       .getRegionDetails(context, ref, customer.id, customer.name)
        //       .then((val) async {
        try {
          // if (val == 1) {
          await EasyLoading.dismiss();
          if (keyContext.mounted) {
            Navigator.push(
              keyContext,
              MaterialPageRoute(
                builder: (context) => const RegionList(),
              ),
            );
          }
          // }
        } catch (e) {
          await EasyLoading.dismiss();
          log('Navigation error: $e');
        }
        // });
        // }
        // } else {
        //   if (context.mounted) {
        //     await snackBar(context, ErrorMessages.offlineErrorTitle,
        //         ErrorMessages.offlineErrorMessage);
        //   }
        // }
        // });
      },
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, color: Theme.of(context).tabBarTheme.indicatorColor),
        Text(ErrorMessages.customerNotFoundError),
      ],
    );
  }
}

class Customer {
  String id;
  String name;

  Customer({required this.id, required this.name});
}
