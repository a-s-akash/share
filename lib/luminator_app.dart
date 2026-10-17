import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:schnell_luminator/device_page/lamp/lamp_scan_page.dart';
import 'package:schnell_luminator/device_page/pole/pole_page.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/home_page/map_page.dart';
import 'package:schnell_luminator/location_selection/customer_list.dart';
import 'package:schnell_luminator/update/update_page.dart';
import 'device_page/device_search.dart';
import 'device_page/lamp/lamp_details_page.dart';
import 'env.dart';
import 'location_selection/region_list.dart';
import 'location_selection/ward_list.dart';
import 'location_selection/zone_list.dart';
import 'login_page/login_page.dart';
import 'offline_login/offline_login_page.dart';
import 'splash_screen/splash_page.dart';
import 'ticket_notification/ticket_list_page.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

class LuminatorApp extends StatelessWidget {
  const LuminatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: !baseURL.contains('schnelliot'),
      title: 'Luminator App',
      theme: lightTheme(context),
      initialRoute: splashRoute,
      builder: EasyLoading.init(),
      // builder: (context, child) {
      //   final wrappedChild = ConnectivityBanner(child: child!);
      //   return EasyLoading.init()(context, wrappedChild);
      // },
      routes: {
        loginRoute: (context) => LoginPage(),
        offlineLoginRoute: (context) => const OfflineLoginPage(),
        splashRoute: (context) => const SplashPage(),
        homeRoute: (context) => HomePage(),
        customerRoute: (context) => const CustomerList(),
        regionRoute: (context) => const RegionList(),
        zoneRoute: (context) => const ZoneList(),
        wardRoute: (context) => const WardList(),
        mapRoute: (context) => const MapPage(),
        updateRoute: (context) => UpdatePage(),
        lampDetailsRoute: (context) => const LampDetailsPage(),
        poleDetailsRoute: (context) => PoleDetails(),
        poleScanRoute: (context) => const PoleScanPage(),
        ticketListRoute: (context) => const TicketListPage(),
        searchRoute: (context) => const DeviceSearch(),
      },
    );
  }
}
