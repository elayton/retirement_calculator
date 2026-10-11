import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';

/// Width of the value box, shared by the editable and fixed fields so the
/// numbers line up down the section.
const _valueBoxWidth = 80.0;

/// Height of the value box, likewise shared.
const _valueBoxHeight = 36.0;

/// The space taken by the gap and the stepper arrows of an editable field,
/// reserved by a fixed field so both align.
const _trailingWidth = 28.0;

/// Below this page width the sidebar sits above the table instead of beside it.
const planSidebarBreakpoint = 1000.0;

/// The fixed width of the sidebar when it sits beside the table.
const planSidebarWidth = 300.0;

/// Sidebar section titles, in display order. Each one stands in for a group of
/// plan parameters; sections without controls yet render a placeholder body.
const planSidebarSections = <String>['Timeline', 'Budget & Insurance', 'Contributions', 'Investment Growth', 'Market Downturns', 'Roth Conversion'];

/// The left sidebar of the plan page: a vertical stack of accordions, one per
/// group of plan parameters.
///
/// Parameters are edited in place on [parameters]; [onChanged] is called after
/// each edit so the page can rebuild the projection table from the new values.
class PlanSidebar extends StatelessWidget {
  const PlanSidebar({super.key, required this.parameters, required this.onChanged, this.width = planSidebarWidth});

  final PlanParameters parameters;
  final VoidCallback onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarSection(title: 'Timeline', children: [_timelineFields(context)]),
          // One collapsed accordion per remaining section, stacked vertically.
          for (final title in planSidebarSections.skip(1)) ...[const SizedBox(height: 4), _SidebarSection(title: title)],
        ],
      ),
    );
  }

  /// The controls for the ages that drive the projection.
  Widget _timelineFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntegerField(
          label: 'Retirement Age',
          value: parameters.retirementAge,
          onChanged: (value) {
            parameters.retirementAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _IntegerField(
          label: 'Social Security Age',
          value: parameters.socialSecurityAge,
          onChanged: (value) {
            parameters.socialSecurityAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _IntegerField(
          label: 'Spouse Social Security Age',
          value: parameters.spouseSocialSecurityAge,
          onChanged: (value) {
            parameters.spouseSocialSecurityAge = value;
            onChanged();
          },
        ),
        Divider(height: 20, color: Theme.of(context).colorScheme.outlineVariant),
        _ConstantField(label: '401(k) Withdrawal Age', value: PlanConstants.fourOhOneKWthdrawalAge),
        const SizedBox(height: 8),
        _ConstantField(label: 'IRA Withdrawal Age', value: PlanConstants.iraWithdrawalAge),
        const SizedBox(height: 8),
        _ConstantField(label: 'Medicare Start Age', value: PlanConstants.medicareStartAge),
        const SizedBox(height: 8),
        _ConstantField(label: 'RMD Start Age', value: PlanConstants.rmdStartAge),
      ],
    );
  }
}

/// A single expandable section; sections without controls show a placeholder.
class _SidebarSection extends StatelessWidget {
  final String title;
  final List<Widget>? children;

  const _SidebarSection({required this.title, this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ExpansionTile(
          // Collapsed by default; the trailing arrow opens and closes the section.
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          children:
              children ??
              [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Coming soon.',
                    style: TextStyle(fontStyle: FontStyle.italic, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}

/// A labeled box that edits one integer plan parameter.
class _IntegerField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _IntegerField({required this.label, required this.value, required this.onChanged});

  @override
  State<_IntegerField> createState() => _IntegerFieldState();
}

class _IntegerFieldState extends State<_IntegerField> {
  /// Ages are never negative, so decrementing stops here.
  static const minValue = 0;

  late final TextEditingController _controller = TextEditingController(text: '${widget.value}');

  /// The value the arrows step from, which can differ from the box text while
  /// the box is empty or mid-edit.
  late int _value = widget.value;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Only whole numbers are accepted, and an empty box keeps the last value.
  void _onChanged(String text) {
    final value = int.tryParse(text);
    if (value != null) {
      setState(() => _value = value);
      widget.onChanged(value);
    }
  }

  void _step(int delta) {
    final value = _value + delta;
    if (value < minValue) return;

    final text = '$value';
    setState(() => _value = value);
    // Write the box text directly so typing and stepping share one value, and
    // keep the caret at the end of the new text.
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged(value);
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 16),
      style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label)),
        const SizedBox(width: 8),
        SizedBox(
          width: _valueBoxWidth,
          child: TextField(
            controller: _controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints.tightFor(height: _valueBoxHeight),
            ),
            onChanged: _onChanged,
          ),
        ),
        const SizedBox(width: 4),
        // Arrows step the value by one without touching the keyboard.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrow(Icons.keyboard_arrow_up, 'Increase', () => _step(1)),
            _arrow(Icons.keyboard_arrow_down, 'Decrease', _value > minValue ? () => _step(-1) : null),
          ],
        ),
      ],
    );
  }
}

/// A labeled age that comes from [PlanConstants] and cannot be edited.
class _ConstantField extends StatelessWidget {
  final String label;
  final int value;

  const _ConstantField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Fixed by plan constants.',
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          // Right-aligned into the same column as the editable boxes above, so
          // the ages still line up without needing a box of their own.
          SizedBox(
            width: _valueBoxWidth,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          // Aligns with the stepper arrows on the editable fields above.
          const SizedBox(width: _trailingWidth),
        ],
      ),
    );
  }
}
