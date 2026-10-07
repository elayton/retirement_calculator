import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/portfolio.dart';
import '../models/portfolio_type.dart';
import '../parsers/fidelity_full_view_parser.dart';

class LoadPage extends StatefulWidget {
  const LoadPage({
    super.key,
    this.onLoaded,
  });

  final ValueChanged<Portfolio>? onLoaded;

  @override
  State<LoadPage> createState() => _LoadPageState();
}

class _LoadPageState extends State<LoadPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // The current selection and load result are tracked below.
  PortfolioType _portfolioType = PortfolioType.fidelityFullView;
  Portfolio? _portfolio;
  String? _error;

  // Pick a file, parse it, and update the loaded state.
  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['csv']);
    final path = file?.path;
    if (file == null || path == null) return;

    try {
      final contents = await File(path).readAsString();
      final portfolio = switch (_portfolioType) {
        PortfolioType.fidelityFullView => parseFidelityFullView(contents, type: _portfolioType.label, fileName: file.name),
      };
      setState(() {
        _portfolio = portfolio;
        _error = null;
      });
      widget.onLoaded?.call(portfolio);
    } catch (e) {
      setState(() {
        _portfolio = null;
        _error = 'Failed to load "${file.name}": $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // What is currently loaded.
          if (_portfolio != null) ...[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Current Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Type: ${_portfolio!.type}'),
                  Text('File: ${_portfolio!.fileName}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          // The portfolio type selector and file picker.
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Load Portfolio:'),
                const SizedBox(width: 12),
                _PortfolioTypeDropdown(initialSelection: _portfolioType, onSelected: (value) => setState(() => _portfolioType = value)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(child: _BrowseButton(onPressed: _pickFile)),
          // The error from the most recent load attempt, if any.
          if (_error != null) ...[const SizedBox(height: 16), Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
        ],
      ),
    );
  }
}

class _PortfolioTypeDropdown extends StatelessWidget {
  const _PortfolioTypeDropdown({required this.initialSelection, required this.onSelected});

  final PortfolioType initialSelection;
  final ValueChanged<PortfolioType> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<PortfolioType>(
      width: 220,
      initialSelection: initialSelection,
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
      trailingIcon: Transform.translate(
        offset: const Offset(0, -4),
        child: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
      ),
      selectedTrailingIcon: Transform.translate(
        offset: const Offset(0, -4),
        child: Icon(Icons.arrow_drop_up, color: Theme.of(context).colorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints.tightFor(height: 40),
      ),
      dropdownMenuEntries: PortfolioType.values.map((type) => DropdownMenuEntry(value: type, label: type.label)).toList(),
      onSelected: (value) {
        if (value != null) onSelected(value);
      },
    );
  }
}

class _BrowseButton extends StatelessWidget {
  const _BrowseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
          fixedSize: const Size(220, 40),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
        onPressed: onPressed,
        icon: const Icon(Icons.folder_open),
        label: const Text('Browse for Portfolio File'),
      ),
    );
  }
}
