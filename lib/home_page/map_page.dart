import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:schnell_luminator/device_page/device_controller.dart';
import 'package:schnell_luminator/home_page/map_controller.dart';
import 'package:schnell_luminator/location_selection/location_controller.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/utils/dialog_box.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mapController).loadCounts(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<DeviceMarkerData>> markersData =
        ref.watch(mapController).markersData;
    final LatLng? userLocation = ref.watch(locationController).userLocation;
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedWard = ref.watch(deviceController).selectedWard;
    List<String> availableAssets = ref.watch(mapController).availableAssets;

    List<List<LatLng>> geoFence = ref.watch(mapController).geoFence;
    List<String> choosenAssets = ref.watch(mapController).choosenAssets;
    String usermail = ref.watch(loginController).userMail;
    String usernmae = usermail.split("@").first.toUpperCase();

    final bool showName = ref.watch(mapController).showName;

    final lowerChosen = choosenAssets.map((e) => e.toLowerCase()).toList();

    final combinedMarkerData = markersData.entries
        .where((entry) => lowerChosen.contains(entry.key.toLowerCase()))
        .expand((entry) => entry.value)
        .toList();
    log('Map Screen combinedMarkerData: ${combinedMarkerData.length}');

    final markers = combinedMarkerData.map((m) {
      return Marker(
        point: m.point,
        width: 40,
        height: showName ? 60 : 40,
        child: GestureDetector(
          onTap: m.onTap,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            direction: Axis.vertical,
            children: [
              SvgPicture.asset(
                m.icon,
                width: 25,
                height: 25,
              ),
              if (showName)
                MarkerLabel(
                  label: m.label,
                  bgColor: Theme.of(context).canvasColor,
                ),
            ],
          ),
        ),
      );
    }).toList();

    return Scaffold(
      drawer: customHomeDrawer(
        usernmae,
        usermail,
        context,
        ref,
      ),
      body: Column(
        children: [
          SelectedLocationData(
              selectedCustomer: selectedCustomer,
              selectedRegion: selectedRegion,
              selectedZone: selectedZone,
              selectedWard: selectedWard,
              isMapPage: true),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userLocation!,
                    initialZoom: 18.0,
                    maxZoom: 30,
                    backgroundColor: Theme.of(context).canvasColor,
                    interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.drag),
                  ),
                  children: <Widget>[
                    TileLayer(
                      maxZoom: 25,
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName:
                          'com.schnell.schnell_luminator.schnell_luminator',
                    ),
                    if (geoFence.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          ...geoFence.asMap().entries.map((entry) {
                            final index = entry.key;
                            final points = entry.value;

                            final color = generateColor(index);

                            return Polygon(
                              points: points,
                              color: color..withValues(alpha: 0.3),
                              borderStrokeWidth: 2.0,
                              borderColor: color,
                            );
                          }).toList(),
                        ],
                      ),
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        zoomToBoundsOnClick: false,
                        markers: markers,
                        maxClusterRadius: 300,
                        spiderfyCircleRadius: 50,
                        disableClusteringAtZoom: 35,
                        size: const Size(50, 50),
                        polygonOptions: PolygonOptions(
                          borderColor: Theme.of(context).focusColor,
                          color: Theme.of(context).secondaryHeaderColor,
                          borderStrokeWidth: 3,
                        ),
                        builder: (context, markers) {
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text('${markers.length}'),
                          );
                        },
                      ),
                    ),
                    CurrentLocationLayer(
                      alignPositionOnUpdate: AlignOnUpdate.never,
                      alignDirectionOnUpdate: AlignOnUpdate.never,
                      style: LocationMarkerStyle(
                          marker: DefaultLocationMarker(
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).canvasColor,
                              size: 14,
                            ),
                          ),
                          markerSize: const Size.square(22),
                          showAccuracyCircle: false,
                          markerDirection: MarkerDirection.heading),
                    ),
                  ],
                ),
                Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: availableAssets.map((item) {
                        final String name = item;
                        final String image =
                            ref.watch(mapController).assetsIcons[name];
                        final bool isSelected = choosenAssets.contains(name);

                        return GestureDetector(
                          onTap: () {
                            ref.read(mapController).updateChoosenAsset(name);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            width: MediaQuery.of(context).size.width / 4.3,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Theme.of(context).unselectedWidgetColor,
                                  spreadRadius: 0,
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.white,
                              border: isSelected
                                  ? Border.all(
                                      width: 1,
                                      color: const Color.fromARGB(
                                          255, 180, 180, 180),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            image,
                                            width: 15,
                                            height: 15,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            ref
                                                .watch(mapController)
                                                .labelName[name],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color.fromARGB(
                                                  255, 51, 51, 51),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Padding(
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 2),
                                        child: Icon(
                                          Icons.check,
                                          size: 15,
                                          color:
                                              Color.fromARGB(255, 51, 51, 51),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  (ref.watch(mapController).assetCounts[name] ??
                                          0)
                                      .toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 51, 51, 51),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'map_showname_fab',
              extendedPadding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              backgroundColor: Theme.of(context).cardColor,
              icon: Icon(
                showName ? Icons.cancel : Icons.check,
                size: 18,
              ),
              label: Text(
                showName ? "Hide Name" : "Show Name",
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () {
                ref.read(mapController).toggleShowName();
              },
            ),
            const Spacer(),
            FloatingActionButton(
              heroTag: 'map_recenter_fab',
              backgroundColor: Theme.of(context).cardColor,
              child: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(userLocation, 18);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MarkerLabel extends StatelessWidget {
  final String label;
  final Color bgColor;

  const MarkerLabel({super.key, required this.label, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: Theme.of(context).secondaryHeaderColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

Color generateColor(int index) {
  final hue = (index * 137.508) % 360;
  return HSLColor.fromAHSL(0.5, hue, 0.5, 0.30).toColor();
}
