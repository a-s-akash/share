import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/session_context_controller.dart';

/// Shows the combined Operation Mode + Vehicle selection bottom sheet.
///
/// [dismissible] controls whether the user can swipe/tap-away/back out
/// without completing the selections — `false` the first time it's shown
/// on the Home Screen, `true` when reopened from the status chip to
/// review/update.
Future<void> showSessionContextSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool dismissible,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _SessionContextSheet(dismissible: dismissible),
  );
}

class _SessionContextSheet extends ConsumerStatefulWidget {
  const _SessionContextSheet({required this.dismissible});

  final bool dismissible;

  @override
  ConsumerState<_SessionContextSheet> createState() =>
      _SessionContextSheetState();
}

class _SessionContextSheetState extends ConsumerState<_SessionContextSheet> {
  final _formKey = GlobalKey<FormState>();
  late AppMode? _selectedMode;
  late String? _selectedVehicleType;
  late TextEditingController _vehicleNumberController;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(sessionContextController);
    _selectedMode = controller.mode;
    _selectedVehicleType = controller.vehicleType;
    _vehicleNumberController =
        TextEditingController(text: controller.vehicleNumber ?? '');
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedMode == null) return;
    if (!_formKey.currentState!.validate()) return;

    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    await ref.read(sessionContextController).confirmSelections(
          mode: _selectedMode!,
          vehicleType: _selectedVehicleType!,
          vehicleNumber: vehicleNumber,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selectedMode != null;

    return PopScope(
      canPop: widget.dismissible,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .unselectedWidgetColor
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Text(
                      'Session Setup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your operation mode and vehicle for this session',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'OPERATION MODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Theme.of(context)
                            .secondaryHeaderColor
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeCard(
                            icon: Icons.build_circle_outlined,
                            label: AppMode.installation.label,
                            selected: _selectedMode == AppMode.installation,
                            onTap: () => setState(
                                () => _selectedMode = AppMode.installation),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModeCard(
                            icon: Icons.handyman_outlined,
                            label: AppMode.maintenance.label,
                            selected: _selectedMode == AppMode.maintenance,
                            onTap: () => setState(
                                () => _selectedMode = AppMode.maintenance),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'VEHICLE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Theme.of(context)
                            .secondaryHeaderColor
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField2<String>(
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      value: _selectedVehicleType,
                      items: const [
                        DropdownMenuItem(
                            value: '2 Wheeler', child: Text('2 Wheeler')),
                        DropdownMenuItem(
                            value: '4 Wheeler', child: Text('4 Wheeler')),
                      ],
                      dropdownStyleData: DropdownStyleData(
                        elevation: 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _selectedVehicleType = value),
                      validator: (value) =>
                          value == null ? 'Select vehicle type' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _vehicleNumberController,
                      maxLength: 10,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9 ]')),
                      ],
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Vehicle Number',
                        labelStyle: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter vehicle number'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canContinue
                              ? Theme.of(context).primaryColor
                              : Theme.of(context)
                                  .unselectedWidgetColor
                                  .withValues(alpha: 0.4),
                          foregroundColor: Theme.of(context).canvasColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        onPressed: canContinue ? _confirm : null,
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Material(
        color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? primary
                    : Theme.of(context)
                        .unselectedWidgetColor
                        .withValues(alpha: 0.4),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon,
                    size: 30,
                    color: selected
                        ? primary
                        : Theme.of(context).unselectedWidgetColor),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected
                        ? primary
                        : Theme.of(context).secondaryHeaderColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
