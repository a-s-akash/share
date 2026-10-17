import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/location_selection/ward_list.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../home_page/dashboard.dart';
import '../home_page/map_controller.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../ticket_notification/ticket_controller.dart';

void showZoneSelectDialog(
  ref,
  context,
) {
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
                child: const ZoneList()));
      });
}

class ZoneList extends ConsumerStatefulWidget {
  const ZoneList({Key? key}) : super(key: key);

  @override
  ConsumerState<ZoneList> createState() => _ZoneListState();
}

class _ZoneListState extends ConsumerState<ZoneList> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    List<Zone> zoneList = ref.watch(locationController).zoneList;
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedRegionId = ref.watch(deviceController).selectedRegionId;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;

    List<Zone> filteredList = zoneList
        .where((zone) =>
            zone.name.toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    return WillPopScope(
      onWillPop: () async {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => const RegionList(),
        //   ),
        // );
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
                          selectedRoute: 'zone'),
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
                    hintText: 'Search zone',
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
                child: zoneList.isEmpty
                    ? const EmptyView()
                    : filteredList.isEmpty
                        ? const EmptyView()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return ZoneItem(zone: filteredList[index]);
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
              // width: 100,
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
                  ref
                      .read(deviceController)
                      .updateSelectedLocation(ref, 'region', '');
                  await ref.read(ticketController).updateSelectedAssetId(
                      selectedRegionId, 'region', selectedRegion);
                  await ref
                      .read(ticketController)
                      .isTicketsOfSpecificDeviceOrAsset(false);
                  await ref.read(mapController).updateFromWardList('region');
                  // if (ref.watch(internetStatusProvider)) {
                  //   if (context.mounted) {
                  //     ref.read(ticketController).getTicketsCountBasedOnStatus(
                  //         context, ref, 'Pending');
                  //   }
                  // }
                  await ref.read(loginController).paramsForTheWebViewWard(
                        ref,
                        selectedRegionId,
                        selectedRegion,
                        selectedRegion,
                      );
                  ref.read(bottomMenuStateProvider.state).state = 0;

                  EasyLoading.dismiss();
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  }
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

class ZoneItem extends ConsumerWidget {
  final Zone zone;

  const ZoneItem({
    Key? key,
    required this.zone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedRegionId = ref.watch(deviceController).selectedRegionId;
    return GestureDetector(
      child: Container(
        // padding: const EdgeInsets.all(8.0),
        // margin: const EdgeInsets.only(bottom: 8),
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
                zone.name,
                style: TextStyle(
                  // fontSize: 14,
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        // Utility.isConnected().then((value) async {
        //   if (value) {
        EasyLoading.show(status: 'loading...', dismissOnTap: false);

        await ref
            .read(ticketController)
            .updateSelectedAssetId(zone.id, 'zone', zone.name);
        await ref
            .read(deviceController)
            .updatedSelectedZone(zone.name, zone.id, zone.desc);
        await ref.read(mapController).updateToWardList(zone.wardList, 'zone');

        String userMail = ref.read(loginController).userMail;

        await ref.read(locationController).loadWardList(
            userMail, selectedCustomerId, selectedRegionId, zone.id);
        // if (context.mounted) {
        // await ref
        //     .read(locationController)
        //     .getWardDetails(context, ref, zone.id, zone.name)
        //     .then((value) async {
        EasyLoading.dismiss();
        ref.read(deviceController).updateSelectedLocation(ref, 'zone', '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WardList(),
          ),
        );
        // });
        // }
        //   } else {
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
        Text(ErrorMessages.zoneNotFoundError),
      ],
    );
  }
}

class Zone {
  String id;
  String name;
  String type;
  String desc;
  List wardList;

  Zone({
    required this.id,
    required this.name,
    required this.type,
    required this.desc,
    required this.wardList,
  });

  @override
  String toString() {
    return name;
  }
}
