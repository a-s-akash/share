import 'dart:developer';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:schnell_luminator/home_page/dashboard.dart';
import 'package:schnell_luminator/ticket_notification/ticket_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../device_page/device_controller.dart';
import '../login_page/login_controller.dart';
import '../survey/survey_controller.dart';
import '../utils/app_theme.dart';
import '../utils/asset_folder.dart';
import '../utils/constants.dart';
import '../utils/dialog_box.dart';
import '../utils/dropdown_options.dart';
import '../utils/utility.dart';
import '../survey/background_connectivity_monitoring.dart';
import 'offline/ticket_export.dart';
import 'offline/ticket_queue_item.dart';
import 'offline/ticket_update_queue_item.dart';
import 'ticket_creation_page.dart';
import 'ticket_details_page.dart';
import 'ticket_model.dart';

/// Which ticket view is showing — true = My Tickets, false = All Tickets.
/// A plain local toggle (not TabController-driven) so switching is an
/// instant state flip with no page-transition animation to wait on.
final ticketListMyTicketsSelectedProvider = StateProvider<bool>((ref) => true);

const ticketStatusItems = [
  'Ticket Status (ALL)',
  'Open',
  'Assigned',
  'Closed',
  'Visited-Closed',
  'Visited-Not Closed',
  'Verified-Opened',
  'Pending'
];
// bool doesDeviceTypeExist(deviceType) {
//   for (var key in componenetsChanged.keys) {
//     if (componenetsChanged[key]!
//         .contains(deviceType.toString().toUpperCase())) {
//       return true;
//     }
//   }
//   return false;
// }

bool doesDeviceTypeExist(String deviceType) {
  return componenetsChanged.containsKey(deviceType.toUpperCase());
}

/// Shared by MyTicketsView (the actual list) and _MyTicketsCount (its
/// header count), so the two can never disagree on what "context-specific"
/// means. Empty selectedContextName means no ward/zone/region/customer is
/// selected, so everything matches — same convention getDefaultTicketServiceFB
/// uses server-side for the All Tickets query.
bool ticketMatchesSelectedContext(
    Ticket ticket, String contextType, String contextName) {
  if (contextName.isEmpty) return true;
  switch (contextType) {
    case 'ward':
      return ticket.ward == contextName;
    case 'zone':
      return ticket.zone == contextName;
    case 'region':
      return ticket.region == contextName;
    case 'customer':
      return ticket.customer == contextName;
    default:
      return true;
  }
}

/// Shows a live count of tickets and ticket updates still queued locally
/// (not yet uploaded) next to the ticket list actions, so field users can
/// see queued work without opening the export sheet.
class OfflineTicketsIndicator extends StatelessWidget {
  const OfflineTicketsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Box>>(
      future: Future.wait([
        Hive.isBoxOpen(ticketQueueBox)
            ? Future.value(Hive.box<TicketQueueItem>(ticketQueueBox))
            : Hive.openBox<TicketQueueItem>(ticketQueueBox),
        Hive.isBoxOpen(ticketUpdateQueueBox)
            ? Future.value(
                Hive.box<TicketUpdateQueueItem>(ticketUpdateQueueBox))
            : Hive.openBox<TicketUpdateQueueItem>(ticketUpdateQueueBox),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final ticketBox = snapshot.data![0] as Box<TicketQueueItem>;
        final updateBox = snapshot.data![1] as Box<TicketUpdateQueueItem>;
        return ListenableBuilder(
          listenable: Listenable.merge(
              [ticketBox.listenable(), updateBox.listenable()]),
          builder: (context, _) {
            final outstanding =
                ticketBox.values.where((t) => !t.uploaded).length +
                    updateBox.values.where((u) => !u.uploaded).length;
            if (outstanding == 0) return const SizedBox.shrink();

            const color = Colors.orangeAccent;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload_outlined,
                        size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '$outstanding offline',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TicketListPage extends ConsumerWidget {
  const TicketListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String usermail = ref.watch(loginController).userMail;
    String username = usermail.split("@").first.toUpperCase();

    bool isMyTicketsSelected = ref.watch(ticketListMyTicketsSelectedProvider);

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
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
            leading: Builder(builder: (BuildContext context) {
              return IconButton(
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
              "TICKETS",
              style: TextStyle(
                  color: Theme.of(context).cardColor,
                  fontWeight: FontWeight.w500),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.file_download,
                  color: Colors.green,
                ),
                tooltip: 'Export Offline Tickets',
                onPressed: () async {
                  await Utility.refreshTicketQueueBox();
                  showTicketExportDialog(context);
                },
              ),
              IconButton(
                onPressed: () async {
                  await ref.read(surveyController).performManualSync();
                },
                icon: const Icon(
                  Icons.sync,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Theme.of(context).cardColor),
                onPressed: () {
                  ref.read(ticketController).fetchLocationForTicket();
                  ref
                      .read(ticketController)
                      .updateSelectedFields(context, ref, '', 'reset', false);
                  showTicketCreationDialog(context, ref);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: customHomeDrawer(
            username,
            usermail,
            context,
            ref,
          ),
          body: ConnectivityBanner(
            child: Column(
              children: [
                const TicketFiltersHeader(),
                const TicketViewToggle(),
                const TicketCountRow(),
                Expanded(
                  child: isMyTicketsSelected
                      ? const MyTicketsView()
                      : const BrowseTicketsByWardView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Project context (customer/region/zone/ward), status dropdown, device type
/// and search — shown once above the tabs instead of once per tab, so both
/// MY TICKETS and ALL TICKETS share the same controls instead of each having
/// their own copy. Kept deliberately compact (tight paddings) so the actual
/// ticket list below gets as much vertical space as possible.
class TicketFiltersHeader extends ConsumerWidget {
  const TicketFiltersHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String selectedCustomer = ref.watch(deviceController).selectedCustomer;
    String selectedRegion = ref.watch(deviceController).selectedRegion;
    String selectedZone = ref.watch(deviceController).selectedZone;
    String selectedWard = ref.watch(deviceController).selectedWard;
    String ticketStatus = ref.watch(ticketController).ticketStatusValue;

    double deviceWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        const SizedBox(
          height: 5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SelectedLocationData(
              selectedCustomer: selectedCustomer,
              selectedRegion: selectedRegion,
              selectedZone: selectedZone,
              selectedWard: selectedWard),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 18.0,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 45.0,
                ),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton2(
                        isDense: true,
                        isExpanded: false,
                        value: ticketStatus,
                        items: ticketStatusItems.map((String items) {
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
                          Utility.isConnected().then((value) async {
                            if (value) {
                              EasyLoading.show(
                                  status: 'loading...', dismissOnTap: false);
                              ref.read(ticketController).setScrollCount(0);
                              log('Selected status filter = $newValue');
                              if (context.mounted) {
                                ref
                                    .read(ticketController)
                                    .getTicketsBasedOnStatusFB(
                                        context, ref, newValue!);
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
                        dropdownStyleData: DropdownStyleData(
                            padding: const EdgeInsets.only(left: 1),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Theme.of(context).canvasColor,
                            )),
                        buttonStyleData: ButtonStyleData(
                          height: 35,
                          width: deviceWidth * 0.42,
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Theme.of(context).canvasColor,
                          ),
                          elevation: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 35,
                      width: deviceWidth * 0.34,
                      padding: const EdgeInsets.only(left: 14, right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Theme.of(context).canvasColor,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .hoverColor
                                .withValues(alpha: 0.3),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset:
                                const Offset(0, 1), // Adjust the shadow offset
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Device Type (ALL)',
                          style: TextStyle(
                              color: Theme.of(context).hoverColor,
                              fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              SearchField(ref: ref),
            ],
          ),
        ),
      ],
    );
  }
}

/// Switches between MY TICKETS and ALL TICKETS. Deliberately a plain
/// two-cell toggle (a Row of GestureDetectors flipping a StateProvider<bool>)
/// instead of a Material TabBar/TabBarView — TabBarView's page-transition
/// (and the fact it keeps rebuilding whichever tab becomes visible) is what
/// made the previous version feel laggy; this just swaps the underline color
/// and the content widget instantly, no animation to wait on.
class TicketViewToggle extends ConsumerWidget {
  const TicketViewToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isMyTickets = ref.watch(ticketListMyTicketsSelectedProvider);

    Widget buildCell({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      final color = selected
          ? Theme.of(context).primaryColor
          : Theme.of(context).unselectedWidgetColor;
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? color : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).primaryColor),
        ),
      ),
      child: Row(
        children: [
          buildCell(
            selected: isMyTickets,
            icon: Icons.person_outline,
            label: 'My Tickets',
            onTap: () => ref
                .read(ticketListMyTicketsSelectedProvider.notifier)
                .state = true,
          ),
          buildCell(
            selected: !isMyTickets,
            icon: Icons.groups_outlined,
            label: 'All Tickets',
            onTap: () {
              ref.read(ticketListMyTicketsSelectedProvider.notifier).state =
                  false;
              // All Tickets is a live, online-only view — nothing refetches
              // it on its own (no connectivity listener, no per-tab
              // lifecycle hook), so without this, switching to it after
              // being offline at the one-time pre-navigation fetch (or
              // after connectivity later returns) would just keep showing
              // whatever was last fetched, empty or stale.
              Utility.isConnected().then((online) {
                if (!online) return;
                EasyLoading.show(status: 'loading...', dismissOnTap: false);
                ref.read(ticketController).setScrollCount(0);
                final status = ref.read(ticketController).ticketStatusValue;
                if (context.mounted) {
                  ref
                      .read(ticketController)
                      .getTicketsBasedOnStatusFB(context, ref, status);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}

/// Sits below the toggle and shows a count relevant to whichever view is
/// currently selected — My Tickets' own (reactive, box-driven) count while
/// that one is active, and the existing fetched/total count for All Tickets
/// while that one is active.
class TicketCountRow extends ConsumerWidget {
  const TicketCountRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isMyTicketsSelected = ref.watch(ticketListMyTicketsSelectedProvider);
    double deviceWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(top: 10, left: 20, right: deviceWidth * 0.07),
      child: isMyTicketsSelected
          ? const _MyTicketsCount()
          : const _AllTicketsCount(),
    );
  }
}

class _MyTicketsCount extends ConsumerWidget {
  const _MyTicketsCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedContextType = ref.watch(ticketController).selectedContextType;
    final selectedContextName = ref.watch(ticketController).selectedContextName;

    // ticketListBox is opened once at app startup (main.dart) and never
    // closed during the session, so it's safe to read synchronously here —
    // no FutureBuilder needed, which was re-resolving (and briefly blanking)
    // on every rebuild since Hive.box()/Future.value() return a new Future
    // identity each call even though the box itself was already open.
    if (!Hive.isBoxOpen(ticketListBox)) return const SizedBox.shrink();
    final box = Hive.box(ticketListBox);
    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final total = box.length;
        final displayed = selectedContextName.isEmpty
            ? total
            : box.values.where((raw) {
                final ticket = Ticket.fromJson(Map<String, dynamic>.from(raw));
                return ticketMatchesSelectedContext(
                    ticket, selectedContextType, selectedContextName);
              }).length;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              selectedContextName.isEmpty
                  ? '$total My Ticket${total == 1 ? '' : 's'}'
                  : '$displayed/$total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        );
      },
    );
  }
}

class _AllTicketsCount extends ConsumerWidget {
  const _AllTicketsCount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isOnline = ref.watch(internetStatusProvider);
    if (!isOnline) return const SizedBox.shrink();

    List<Ticket> tickets = ref.watch(ticketController).filteredTickets;
    String searchText = ref.watch(ticketController).searchText;
    int fetchedTicketCount = ref.watch(ticketController).fetchedTicketCount;
    int totalTicketsCountBasedOnStatus =
        ref.watch(ticketController).totalTicketsCountBasedOnStatus;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (searchText != '') Text("${tickets.length} Results found"),
        const Spacer(),
        Text(
          "$fetchedTicketCount / $totalTicketsCountBasedOnStatus",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Reactive "my tickets" view — reads straight off ticketListBox via
/// box.listenable(), so it works offline (cached at login/on refresh) and
/// updates itself automatically whenever the box changes: no setState(),
/// no manual reload call after a write. Deliberately has no status tabs,
/// search, or pagination — it's always just "my current assigned tickets".
class MyTicketsView extends ConsumerWidget {
  const MyTicketsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The background sync isolate reopens ticketListBox on the main isolate
    // via HiveSyncManager (see main.dart) after syncing a queued ticket, and
    // bumps hiveSyncProvider to signal it — watch it so this rebuilds and
    // picks up the freshly reopened box instance instead of the stale one.
    ref.watch(hiveSyncProvider);

    // Same ward/zone/region/customer selection BrowseTicketsByWardView
    // queries Firestore with (getTicketsBasedOnStatusFB ->
    // getDefaultTicketServiceFB), applied here as a plain local-field
    // match against ticketListBox instead of a network query.
    final selectedContextType = ref.watch(ticketController).selectedContextType;
    final selectedContextName = ref.watch(ticketController).selectedContextName;

    // Same reasoning as _MyTicketsCount — the box is already open by the
    // time any UI builds, so read it directly instead of routing through a
    // FutureBuilder that resets (and flashes a spinner) on every rebuild.
    if (!Hive.isBoxOpen(ticketListBox)) {
      return const Center(child: CircularProgressIndicator());
    }
    final box = Hive.box(ticketListBox);
    return ValueListenableBuilder<Box>(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final myTickets = box.values
            .map((raw) => Ticket.fromJson(Map<String, dynamic>.from(raw)))
            .where((t) => ticketMatchesSelectedContext(
                t, selectedContextType, selectedContextName))
            .toList()
          ..sort(
              (a, b) => (b.createdTime ?? '').compareTo(a.createdTime ?? ''));

        if (myTickets.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 44,
                      color:
                          Theme.of(context).hoverColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'No tickets assigned to you yet',
                    style: TextStyle(
                        fontSize: 14, color: Theme.of(context).hoverColor),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 50, top: 8),
          itemCount: myTickets.length,
          itemBuilder: (context, index) {
            final ticket = myTickets[index];
            return GestureDetector(
              onTap: () {
                if (ticket.ticketStatus != 'Visited-Closed' &&
                    ticket.ticketStatus != 'Closed' &&
                    ticket.ticketStatus != 'Verified-Closed' &&
                    doesDeviceTypeExist(ticket.deviceType ?? '')) {
                  ref.read(ticketController).resetFieldValues(ticket);
                  ref.read(ticketController).updateSelectedTicket(ticket);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TicketDetailsPage()),
                  );
                }
              },
              child: ListTile(
                title: TicketDetailsCard(ticket, isFromTicketsList: true),
              ),
            );
          },
        );
      },
    );
  }
}

/// The original ward/zone/region + status-tab ticket browser, unchanged —
/// still a live, online-fetched, paginated view (getTicketsBasedOnStatusFB),
/// kept as its own tab rather than folded into the reactive My Tickets view.
class BrowseTicketsByWardView extends ConsumerWidget {
  const BrowseTicketsByWardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Ticket> tickets = ref.watch(ticketController).filteredTickets;
    String ticketStatus = ref.watch(ticketController).ticketStatusValue;
    bool isOnline = ref.watch(internetStatusProvider);

    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (ref.read(ticketController).ticketHasNext) {
          ref.read(ticketController).getTicketsBasedOnStatusFB(
              context, ref, ticketStatus,
              isScroll: true);
        }
      }
    });

    return isOnline
        ? ListView.builder(
            padding: const EdgeInsets.only(bottom: 50),
            itemCount: tickets.length,
            controller: scrollController,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  if (tickets[index].ticketStatus != 'Visited-Closed' &&
                      tickets[index].ticketStatus != 'Closed' &&
                      tickets[index].ticketStatus != 'Verified-Closed') {
                    log('${tickets[index].ticketStatus}');
                    if (doesDeviceTypeExist(tickets[index].deviceType ?? '')) {
                      ref
                          .read(ticketController)
                          .resetFieldValues(tickets[index]);
                      ref
                          .read(ticketController)
                          .updateSelectedTicket(tickets[index]);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TicketDetailsPage()),
                        );
                      }
                    }
                  } else {
                    null;
                  }
                },
                child: ListTile(
                  title: TicketDetailsCard(tickets[index],
                      isFromTicketsList: true),
                ),
              );
            },
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off,
                      size: 44,
                      color:
                          Theme.of(context).hoverColor.withValues(alpha: 0.6)),
                  const SizedBox(height: 12),
                  Text(
                    "You're offline",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).secondaryHeaderColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Connect to the network to reload the latest tickets.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hoverColor),
                  ),
                ],
              ),
            ),
          );
  }
}

class SearchField extends StatefulWidget {
  final WidgetRef ref;

  const SearchField({Key? key, required this.ref}) : super(key: key);

  @override
  State<SearchField> createState() => _SearchFieldState();
}

int toggle = 0;

class _SearchFieldState extends State<SearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _con;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _con = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 375),
    );
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _con.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void resetText() {
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 375),
      height: 37.0,
      width: (toggle == 0 ? 37.0 : deviceWidth * 0.91),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).hoverColor),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).secondaryHeaderColor,
              spreadRadius: -10.0,
              blurRadius: 10.0,
              offset: const Offset(0.0, 10.0))
        ],
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 375),
            left: (toggle == 0) ? 20.0 : 40.0,
            top: 5.0,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: (toggle == 0) ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                height: 23.0,
                width: deviceWidth * 0.7,
                child: TextFormField(
                  controller: _textEditingController,
                  maxLength: 20,
                  cursorRadius: const Radius.circular(10.0),
                  cursorWidth: 2.0,
                  cursorColor: Theme.of(context).secondaryHeaderColor,
                  decoration: InputDecoration(
                      counterText: '',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      labelText: 'Search...',
                      labelStyle: TextStyle(
                          color: Theme.of(context).hoverColor,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide.none)),
                  onChanged: (value) =>
                      widget.ref.read(ticketController).updateSearchText(value),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 375),
            right: (toggle == 0) ? 20.0 : 0,
            top: 2.0,
            curve: Curves.easeOut,
            child: AnimatedOpacity(
                opacity: (toggle == 0) ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: 23.0,
                  width: deviceWidth * 0.1,
                  child: IconButton(
                    icon: Icon(Icons.close,
                        size: 16, color: Theme.of(context).hoverColor),
                    onPressed: () {
                      resetText();
                      widget.ref.read(ticketController).updateSearchText('');
                      FocusScope.of(context).unfocus();
                      setState(
                        () {
                          if (toggle == 0) {
                            toggle = 1;
                            _con.forward();
                          } else {
                            toggle = 0;
                            _con.reverse();
                          }
                        },
                      );
                    },
                  ),
                )),
          ),
          Material(
            color: Theme.of(context).canvasColor,
            borderRadius: BorderRadius.circular(30.0),
            child: IconButton(
              icon: Icon(Icons.search,
                  size: 18, color: Theme.of(context).cardColor),
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(
                  () {
                    if (toggle == 0) {
                      toggle = 1;
                      _con.forward();
                    } else {
                      toggle = 0;
                      _con.reverse();
                    }
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class TicketDetailsCard extends ConsumerWidget {
  const TicketDetailsCard(this.ticket,
      {Key? key, this.isFromTicketsList = false})
      : super(key: key);
  final Ticket ticket;
  final bool isFromTicketsList;

  Color getTicketSeverityColor(BuildContext context, String value) {
    String severity = value;
    Color severityColor = Theme.of(context).canvasColor;
    if (severity == 'Critical') {
      severityColor = Theme.of(context).tabBarTheme.indicatorColor!;
    } else if (severity == 'Indeterminate') {
      severityColor = Theme.of(context).hintColor;
    } else if (severity == 'Warning') {
      severityColor = warningColor;
    } else if (severity == 'Major') {
      severityColor = Theme.of(context).dividerColor;
    } else if (severity == 'Minor') {
      severityColor = Theme.of(context).disabledColor;
    }
    return severityColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;
    bool isTicketsOfSpecificDevice =
        ref.watch(ticketController).isTicketsOfSpecificDevice;
    log('$isTicketsOfSpecificDevice');
    Color severityColor = getTicketSeverityColor(context, ticket.priority!);
    File imageData =
        imageLocation[ticket.deviceType.toString().toLowerCase()] ??
            Assets.warning;
    bool isOnline = ref.watch(internetStatusProvider);

    return Card(
      color: doesDeviceTypeExist(ticket.deviceType ?? '')
          ? Theme.of(context).canvasColor
          : const Color.fromARGB(255, 201, 199, 199),
      elevation: 2,
      shadowColor: severityColor,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border(
                right: BorderSide(color: severityColor, width: 0.3),
                top: BorderSide(color: severityColor, width: 0.3),
                bottom: BorderSide(color: severityColor, width: 0.3),
                left: BorderSide(color: severityColor, width: 5))),
        child: Padding(
          padding: const EdgeInsets.only(left: 5.0, top: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: SizedBox(
                        width: deviceWidth / 2.50,
                        height: deviceHeight / 35,
                        child: AutoSizeText(
                          '#${ticket.ticketId ?? ''}',
                          style: TextStyle(
                              color: Theme.of(context).cardColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w200),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                  if (!ticket.synced || ticket.hasPendingUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_upload_outlined,
                              size: 12, color: Colors.orangeAccent),
                          const SizedBox(width: 3),
                          Text(
                            // The ticket itself hasn't reached the server
                            // yet takes priority over a merely-pending edit
                            // to it, since that edit can't sync until the
                            // create does (see submitUpdate's isCreatePending).
                            !ticket.synced ? 'Not Synced' : 'Update Pending',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ticket.createdTime != null && ticket.createdTime != ''
                          ? ref
                              .read(ticketController)
                              .getDurationFB(ticket.createdTime ?? '')
                          : '',
                      style: TextStyle(
                          color: Theme.of(context).hoverColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (ticket.deviceId != '' ||
                  ticket.deviceId.toString().toUpperCase() == 'DELETED')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Divider(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.35),
                    thickness: 0.05,
                    height: 6,
                  ),
                ),
              if (ticket.deviceId != '' ||
                  ticket.deviceId.toString().toUpperCase() == 'DELETED')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (!isTicketsOfSpecificDevice && isOnline) {
                          // if (selectedWard != '') {
                          EasyLoading.show(
                            dismissOnTap: false,
                          );
                          ref.read(deviceController).scanDevice(
                              ref, context, 1, "1",
                              isTicket: true,
                              isFromTicketsList: isFromTicketsList,
                              deviceId: ticket.deviceId ?? '');
                          // } else {
                          //   wardRequiredAlert(context, ref,
                          //       'Please select a ward to proceed further..');
                          // }
                        } else {
                          null;
                        }
                      },
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: Image.file(height: 16, width: 16, imageData),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                              width: deviceWidth / 2.2,
                              child: AutoSizeText(
                                ticket.deviceId.toString().toUpperCase() ==
                                        'DELETED'
                                    ? ''
                                    : ticket.deviceId ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).cardColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: warningColor.withValues(alpha: 0.1),
                          shape: BoxShape.rectangle,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(3))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Center(
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 5.0),
                                child: Icon(Icons.circle,
                                    size: 10, color: warningColor),
                              ),
                              AutoSizeText(
                                ["Auto", "Public"]
                                        .contains(ticket.complaineeType)
                                    ? ticket.complaineeType!
                                    : 'Manual',
                                minFontSize: 4,
                                maxFontSize: 24,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: warningColor),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (ticket.problemType != '' && ticket.problemType != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Divider(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.35),
                    thickness: 0.05,
                    height: 6,
                  ),
                ),
              Row(
                children: [
                  if (ticket.problemType != '' && ticket.problemType != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 5.0, top: 2, bottom: 2),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    size: 14,
                                    color: Theme.of(context).disabledColor),
                                const SizedBox(
                                  width: 9,
                                ),
                                SizedBox(
                                    // color: Colors.yellow,
                                    width: deviceWidth / 2.35,
                                    child: AutoSizeText(
                                      ticket.problemType ?? '',
                                      style: TextStyle(
                                          color: Theme.of(context).cardColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  if (ticket.complaineeType != '' &&
                      ticket.complaineeType != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .hintColor
                              .withValues(alpha: 0.5),
                          shape: BoxShape.rectangle,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(3))),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: Center(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_2_outlined,
                                size: 14,
                              ),
                              AutoSizeText(
                                ticket.complainee!,
                                minFontSize: 1,
                                maxFontSize: 24,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).cardColor),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (((ticket.latitude != '' && ticket.longitude != '') &&
                      (ticket.latitude != null && ticket.longitude != null)) ||
                  ticket.location != '')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Divider(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.35),
                    thickness: 0.05,
                    height: 6,
                  ),
                ),
              if (((ticket.latitude != '' && ticket.longitude != '') &&
                      (ticket.latitude != null && ticket.longitude != null)) ||
                  ticket.location != '')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: GestureDetector(
                    onTap: () {
                      if ((ticket.latitude != '' && ticket.longitude != '') &&
                          (ticket.latitude != null &&
                              ticket.longitude != null)) {
                        launchMap(context, ticket);
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: ((ticket.latitude != '' &&
                                      ticket.longitude != '') &&
                                  (ticket.latitude != null &&
                                      ticket.longitude != null))
                              ? Image.file(
                                  Assets.gMapPointer,
                                  height: 20,
                                  width: 20,
                                )
                              : Image.file(
                                  Assets.gMapPointer,
                                  height: 14,
                                  width: 14,
                                  color: Theme.of(context).hoverColor,
                                ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        SizedBox(
                          width: deviceWidth * 0.75,
                          child: AutoSizeText(
                            ticket.location ?? '',
                            minFontSize: 8,
                            maxFontSize: 12,
                            maxLines: 2,
                            style: TextStyle(
                                color: Theme.of(context).cardColor,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // if (ticket.ticketDetails?['t_created_by'] != '' &&
              //     ticket.ticketDetails?['t_created_by'] != null)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 2),
              //     child: Row(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Padding(
              //           padding:
              //               const EdgeInsets.only(left: 5.0, top: 2, bottom: 2),
              //           child: Row(
              //             children: [
              //               const Icon(
              //                 Icons.person,
              //                 size: 14,
              //               ),
              //               const SizedBox(
              //                 width: 5,
              //               ),
              //               SizedBox(
              //                 width: deviceWidth * 0.75,
              //                 child: Text(
              //                   maxLines: 3,
              //                   overflow: TextOverflow.ellipsis,
              //                   ticket.ticketDetails?['t_created_by'] ?? '',
              //                   style: TextStyle(
              //                       color: Theme.of(context).cardColor,
              //                       fontSize: 11),
              //                 ),
              //               )
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              if (ticket.comment != '' && ticket.comment != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Divider(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.35),
                    thickness: 0.05,
                    height: 6,
                  ),
                ),
              if (ticket.comment != '' && ticket.comment != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 5.0, top: 2, bottom: 2),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.speaker_notes_outlined,
                              size: 14,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            SizedBox(
                              width: deviceWidth * 0.75,
                              child: Text(
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                ticket.comment ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).cardColor,
                                    fontSize: 11),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Divider(
                  color: Theme.of(context)
                      .unselectedWidgetColor
                      .withValues(alpha: 0.35),
                  thickness: 0.05,
                  height: 6,
                ),
              ),
              Container(
                // color: Colors.red,
                margin: const EdgeInsets.only(bottom: 5),
                width: deviceWidth * 0.83,
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: deviceWidth / 2.5,
                      color: getTicketSeverityColor(context, ticket.priority!)
                          .withValues(alpha: 0.1),
                      padding: const EdgeInsets.all(3.0),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                  top: 4, bottom: 4, left: 25),
                              decoration: BoxDecoration(
                                color: getTicketSeverityColor(
                                    context, ticket.priority!),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(
                              width: deviceWidth * 0.3,
                              child: AutoSizeText(
                                ticket.priority ?? '',
                                style: TextStyle(
                                    color: getTicketSeverityColor(
                                        context, ticket.priority!),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: deviceWidth * 0.02,
                    ),
                    Container(
                      width: deviceWidth / 2.7,
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      padding: const EdgeInsets.only(
                          top: 3.0, bottom: 3.0, left: 10),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5.0),
                              child: Icon(Icons.circle,
                                  size: 10, color: Theme.of(context).cardColor),
                            ),
                            SizedBox(
                              width: deviceWidth * 0.3,
                              child: AutoSizeText(
                                ticket.ticketStatus?.toUpperCase() ?? '',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                minFontSize: 7,
                                maxFontSize: 10,
                                maxLines: 1,
                              ),
                            ),
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
      ),
    );
  }
}
