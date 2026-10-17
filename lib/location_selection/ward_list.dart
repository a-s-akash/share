import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/survey/survey_controller.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../home_page/map_controller.dart';
import '../home_page/session_context_sheet.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../ticket_notification/ticket_controller.dart';
import '../utils/session_context_controller.dart';

void showWardSelectDialog(ref, context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24.0))),
            insetPadding: const EdgeInsets.all(8.0),
            backgroundColor: Theme.of(context).canvasColor,
            content: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                width: MediaQuery.of(context).size.width * 0.70,
                child: const WardList()));
      });
}

class WardList extends ConsumerStatefulWidget {
  const WardList({Key? key}) : super(key: key);

  @override
  ConsumerState<WardList> createState() => _WardListState();
}

class _WardListState extends ConsumerState<WardList> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    List<Ward> wardList = ref.watch(locationController).wardList;
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedZoneId = ref.watch(deviceController).selectedZoneId;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedWard = ref.watch(deviceController).selectedWard;

    List<Ward> filteredList = wardList
        .where((ward) =>
            ward.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
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
                          selectedRoute: 'ward'),
                    ),
                  ),
                ],
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  maxLength: 20,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12.0),
                    counterText: '',
                    hintText: 'Search ward',
                    hintStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontSize: 15.0,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.19),
                  ),
                ),
              ),
              // List
              Expanded(
                child: wardList.isEmpty
                    ? const EmptyView()
                    : filteredList.isEmpty
                        ? const EmptyView()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return WardItem(ward: filteredList[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),
            child: SizedBox(
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(248, 64, 124, 161)
                      .withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () async {
                  EasyLoading.show(status: 'loading...', dismissOnTap: false);

                  // Utility.isConnected().then((value) async {
                  //   if (value) {
                  ref
                      .read(deviceController)
                      .updateSelectedLocation(ref, 'zone', '');
                  await ref.read(ticketController).updateSelectedAssetId(
                      selectedZoneId, 'zone', selectedZone);
                  await ref
                      .read(ticketController)
                      .isTicketsOfSpecificDeviceOrAsset(false);
                  await ref.read(mapController).updateFromWardList('zone');

                  await ref.read(loginController).paramsForTheWebViewWard(
                      ref,
                      selectedZoneId,
                      selectedZone,
                      '$selectedRegion > $selectedZone');
                  ref.read(bottomMenuStateProvider.state).state = 0;

                  EasyLoading.dismiss();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ),
                    );
                  }
                  //   } else {
                  //     EasyLoading.dismiss();

                  //     if (context.mounted) {
                  //       await snackBar(
                  //         context,
                  //         ErrorMessages.offlineErrorTitle,
                  //         ErrorMessages.offlineErrorMessage,
                  //       );
                  //     }
                  //   }
                  // });
                },
                child: const Text(
                  "Proceed to Home",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WardItem extends ConsumerWidget {
  final Ward ward;

  const WardItem({
    Key? key,
    required this.ward,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 3, right: 3, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.20),
          border: Border.all(color: Theme.of(context).unselectedWidgetColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(
                Icons.adjust_rounded,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
              child: Text(
                ward.name,
                style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        EasyLoading.show(status: 'loading...', dismissOnTap: false);

        // Utility.isConnected().then((value) async {
        //   if (value) {
        await ref
            .read(ticketController)
            .updateSelectedAssetId(ward.id, 'ward', ward.name);
        await ref.read(mapController).updateToWardList([ward.id]);

        await ref
            .read(ticketController)
            .isTicketsOfSpecificDeviceOrAsset(false);
        ref.read(surveyController).extractWardValue(ward.name);
        if (ref.watch(internetStatusProvider)) {
          ref.read(surveyController).getWardAssetsName(ward.id);
        }
        ref.read(surveyController).generatePolePrefixForSurvey(ref);
        ref.read(bottomMenuStateProvider.state).state = 0;

        EasyLoading.dismiss();

        if (context.mounted) {
          ref
              .read(deviceController)
              .updateWardId(context, ref, ward.name, ward.id, ward.desc);
        }
        ref.read(sessionContextController).loadCached().then((_) {
          showSessionContextSheet(context, ref, dismissible: false);
        });
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );

        // } else {
        //   EasyLoading.dismiss();

        //   if (context.mounted) {
        //     await snackBar(
        //       context,
        //       ErrorMessages.offlineErrorTitle,
        //       ErrorMessages.offlineErrorMessage,
        //     );
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
        Text(ErrorMessages.wardNotFoundError),
      ],
    );
  }
}

class Ward {
  String id;
  String name;
  String type;
  String desc;

  Ward({
    required this.id,
    required this.name,
    required this.type,
    required this.desc,
  });

  @override
  String toString() => name;
}
