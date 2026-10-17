import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/attendence_tracking.dart/user_tracking_controller.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import 'package:schnell_luminator/utils/session.dart';
import '../survey/background_connectivity_monitoring.dart';
import '../utils/asset_folder.dart';
import '../utils/dialog_box.dart';
import '../utils/utility.dart';
import 'device_controller.dart';

class DeviceSearch extends ConsumerStatefulWidget {
  const DeviceSearch({Key? key}) : super(key: key);

  @override
  ConsumerState<DeviceSearch> createState() => _DeviceSearchState();
}

class _DeviceSearchState extends ConsumerState<DeviceSearch> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider = ref.read(deviceController);
      if (provider.hasMoreDeviceSearch && !provider.isDeviceSearchLoadingMore) {
        provider.deviceListSearch(
            ref, context, searchController.text.replaceAll("#", ""),
            page: provider.deviceSearchPage + 1, requiredPagination: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List searchResult = ref.watch(deviceController).deviceSearchList;
    List filteredList = searchResult
        .where((item) =>
            item['type'] == "ilm" ||
            item['type'] == "gw" ||
            item['type'] == "ccms" ||
            item['type'] == "hub" ||
            item['type'] == "lamp" ||
            item['type'] == "pole" ||
            item['type'] == "nic" ||
            item['type'] == "semc" ||
            item['type'] == "smslc" ||
            item['type'] == 'ilm-4g')
        .toList();
    filteredList.sort((a, b) => a["name"].compareTo(b["name"]));
    log('response after filtering : $filteredList');
    bool isLoadMore = ref.watch(deviceController).isDeviceSearchLoadingMore;

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          ref.read(deviceController).emptyDeviceSearchList();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).cardColor,
              ),
              onPressed: () async {
                ref.read(deviceController).emptyDeviceSearchList();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(),
                  ),
                );
              },
            ),
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.19),
            elevation: 0.0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall!.color,
              fontSize: 18.0,
            ),
            title: Text(
              "SEARCH DEVICE/ASSET",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
          ),
          body: SafeArea(
            child: ConnectivityBanner(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: TextFormField(
                      maxLength: 20,
                      controller: searchController,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(5.0),
                        hintText: 'Search for ILM,CCMS,HUB,LAMP,GW,POLE',
                        counterStyle:
                            TextStyle(color: Theme.of(context).primaryColor),
                        hintStyle: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(
                                fontSize: 14.0,
                                color: Theme.of(context).primaryColor),
                        suffixIcon: Padding(
                            padding:
                                const EdgeInsets.only(left: 5.0, right: 10),
                            child: IconButton(
                                onPressed: () {
                                  Utility.isConnected().then((value) async {
                                    if (value) {
                                      bool isLocationTrackingRequi =
                                          await isLocationTrackingRequired();
                                      if (isLocationTrackingRequi) {
                                        //auto logout after 24 hrs
                                        bool didAutoLogout = await ref
                                            .read(userTrackingController)
                                            .autoLogout(context, ref);
                                        if (didAutoLogout) return;
                                      }
                                      final isLocationServiceOn = await Utility
                                          .ensureLocationServiceEnabled();
                                      if (!isLocationServiceOn) {
                                        return;
                                      } //check if location is on

                                      var en = searchController.text;

                                      if (en.length < 3) {
                                        if (context.mounted) {
                                          await snackBar(
                                              context,
                                              ErrorMessages
                                                  .searchCharLimitWarningTitle,
                                              ErrorMessages
                                                  .searchCharLimitWarningMessage);
                                        }
                                      } else {
                                        await ref
                                            .read(deviceController)
                                            .clickEventIsFor("allSearch");
                                        if (context.mounted) {
                                          await ref
                                              .read(deviceController)
                                              .deviceListSearch(ref, context,
                                                  en.replaceAll("#", ""),
                                                  page: 0,
                                                  requiredPagination: true);
                                        }
                                        // Removing clear to keep search text for pagination
                                        // searchController.text = '';
                                      }
                                    } else {
                                      if (context.mounted) {
                                        await snackBar(
                                            context,
                                            ErrorMessages.offlineErrorTitle,
                                            ErrorMessages.offlineErrorMessage);
                                      }
                                    }
                                  });
                                },
                                icon: Icon(Icons.search,
                                    size: 30,
                                    color: Theme.of(context).cardColor))),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.19),
                      ),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontSize: 16.0),
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Expanded(
                      child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredList.length + (isLoadMore ? 1 : 0),
                    itemBuilder: (ctx, index) {
                      if (index < filteredList.length) {
                        return _deviceListTile(
                            ctx,
                            ref,
                            filteredList[index]['name'],
                            filteredList[index]['type'],
                            "1");
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deviceListTile(context, WidgetRef ref, String searchResult,
      String type, clickEventIsFor) {
    File imageData = imageLocation[type]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () async {
          EasyLoading.dismiss();
          await ref.read(deviceController).showSelectedDevice(
              ref, context, searchResult, type, clickEventIsFor);
          ref.read(deviceController).emptyDeviceSearchList();
        },
        child: ListTile(
          title: Row(
            children: [
              Text(
                searchResult,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall!.color),
              ),
            ],
          ),
          subtitle: Text(
            type,
            style: TextStyle(color: Theme.of(context).cardColor),
          ),
          leading: Container(
            width: 50,
            margin: const EdgeInsets.all(5),
            child: Image.file(
              imageData,
            ),
          ),
        ),
      ),
    );
  }
}
