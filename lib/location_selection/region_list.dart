import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/location_selection/zone_list.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../login_page/login_controller.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../ticket_notification/ticket_controller.dart';
import '../utils/dialog_box.dart';
import 'location_controller.dart';

void showRegionDialog(
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
                child: const RegionList()));
      });
}

class RegionList extends ConsumerStatefulWidget {
  const RegionList({Key? key}) : super(key: key);

  @override
  ConsumerState<RegionList> createState() => _RegionListState();
}

class _RegionListState extends ConsumerState<RegionList> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    List<Region> regionList = ref.watch(locationController).regionList;
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;

    // filter regions based on search
    List<Region> filteredList = regionList
        .where((region) =>
            region.name.toLowerCase().contains(searchText.toLowerCase()))
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
                          selectedRoute: 'region'),
                    ),
                  ),
                ],
              ),
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
                    hintText: 'Search region',
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
                    fillColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.19),
                  ),
                ),
              ),
              Expanded(
                child: regionList.isEmpty
                    ? const EmptyView()
                    : filteredList.isEmpty
                        ? const EmptyView()
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return RegionItem(region: filteredList[index]);
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
                      .updateSelectedLocation(ref, 'customer', '');
                  await ref.read(ticketController).updateSelectedAssetId(
                      selectedCustomerId, 'customer', selectedCustomer);
                  await ref
                      .read(ticketController)
                      .isTicketsOfSpecificDeviceOrAsset(false);
                  // if (ref.watch(internetStatusProvider)) {
                  //   if (context.mounted) {
                  //     ref.read(ticketController).getTicketsCountBasedOnStatus(
                  //         context, ref, 'Pending');
                  //   }
                  // }
                  await ref.read(loginController).paramsForTheWebViewCustomer(
                      ref, selectedCustomerId, selectedCustomer);
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

class RegionItem extends ConsumerWidget {
  final Region region;
  const RegionItem({
    Key? key,
    required this.region,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String selectedCustomerId = ref.watch(deviceController).selectedCustomerId;
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
                region.name,
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
        // if (value) {
        EasyLoading.show(status: 'loading...', dismissOnTap: false);

        await ref
            .read(ticketController)
            .updateSelectedAssetId(region.id, 'region', region.name);
        await ref.read(mapController).updateRegionLevelAttributes(
            region.compatibleAssets,
            region.userProximityRadius,
            region.isLedTypeInstallAllowed,
            region.isSwitchPointRequiredForPanel);
        await ref.read(deviceController).updatedSelectedRegion(
            region.name, region.id, region.poleSchema, region.desc);

        String userMail = ref.read(loginController).userMail;
        // ref
        //     .read(mapController)
        //     .getGeofence(ref, context, userMail, 'region', region.id);
        await ref
            .read(mapController)
            .updateToWardList(region.wardList, 'region');

        await ref
            .read(locationController)
            .loadZoneList(userMail, selectedCustomerId, region.id);
        // if (context.mounted) {
        //   await ref
        //       .read(locationController)
        //       .getZoneDetails(
        //         context,
        //         ref,
        //         region.id,
        //         region.name,
        //         region.customerId,
        //         region.poleSchema,
        //       )
        //       .then((value) async {
        //     if (value == true) {
        EasyLoading.dismiss();
        ref.read(deviceController).updateSelectedLocation(ref, 'region', '');
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ZoneList(),
            ),
          );
          // showZoneSelectDialog(ref, context);
        }
        //   }
        // });
        // }
        // } else {
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
        Text(ErrorMessages.regionNotFoundError),
      ],
    );
  }
}

class Region {
  String id;
  String customerId;
  String name;
  String type;
  String poleSchema;
  int userProximityRadius;
  List compatibleAssets;
  String desc;
  List wardList;
  bool isLedTypeInstallAllowed;
  bool isSwitchPointRequiredForPanel;

  Region({
    required this.id,
    required this.customerId,
    required this.name,
    required this.type,
    required this.poleSchema,
    required this.compatibleAssets,
    required this.userProximityRadius,
    required this.desc,
    required this.wardList,
    required this.isLedTypeInstallAllowed,
    required this.isSwitchPointRequiredForPanel,
  });
}
