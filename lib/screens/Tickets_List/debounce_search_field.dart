import 'dart:async';
import 'package:flutter/material.dart';

class DebounceSearchField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  final bool autofocus;

  const DebounceSearchField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.onClear,
    this.autofocus = true,
  });

  @override
  State<DebounceSearchField> createState() => _DebounceSearchFieldState();
}

class _DebounceSearchFieldState extends State<DebounceSearchField> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      decoration: InputDecoration(
        hintText: "Search...",
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
          ),
        ),
        contentPadding: const EdgeInsets.all(10),
        suffixIcon: IconButton(
          icon: Icon(Icons.close,
              size: 20, color: Theme.of(context).secondaryHeaderColor),
          onPressed: () {
            widget.onClear();
            _controller.clear();
          },
        ),
      ),
      onChanged: _onSearchChanged,
    );
  }
}
