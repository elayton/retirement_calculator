import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Width of the value box, shared by the editable and fixed fields so the
/// numbers line up down the section.
const _valueBoxWidth = 100.0;

/// Height of the value box, likewise shared.
const _valueBoxHeight = 36.0;

/// Gap between a label and its value box.
const _labelGap = 8.0;

/// Width of the stepper column beside the value box. A field with no steppers
/// reserves the same width of blank, so every box in a section lines up.
const _stepperWidth = 24.0;

/// Height of a single stepper arrow; two of them stack into the column.
const _stepperHeight = 16.0;

/// Gap between the value box and the stepper column.
const _stepperGap = 4.0;

/// The row shared by every field below: a label that soaks up the slack, the
/// value box, then the stepper column or an equally wide blank.
Widget _fieldRow(String label, Widget box, {Widget? stepper, String? help}) {
  final row = Row(
    // A value box draws its text a little above the middle, so the label is
    // aligned to its baseline rather than centred against it.
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: _labelGap),
      // The stepper holds no text and so reports no baseline, which leaves this
      // row reporting the box's while the stepper is centred against it.
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          box,
          const SizedBox(width: _stepperGap),
          SizedBox(width: _stepperWidth, child: stepper),
        ],
      ),
    ],
  );

  return help == null ? row : Tooltip(message: help, child: row);
}

/// A labeled box that edits one integer plan parameter.
class IntegerField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final double step;
  final double minValue;
  final double maxValue;
  final String? help;

  const IntegerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.minValue = 0,
    this.maxValue = double.infinity,
    this.help,
  });

  @override
  Widget build(BuildContext context) {
    return NumberField(
      label: label,
      value: value.toDouble(),
      decimalPlaces: 0,
      step: step,
      minValue: minValue,
      maxValue: maxValue,
      help: help,
      onChanged: (value) => onChanged(value.round()),
    );
  }
}

/// A labeled box that edits one numeric plan parameter.
///
/// [decimalPlaces] fixes the precision, zero for whole numbers such as ages and
/// more for money and rates. [prefix] and [suffix] name the unit inside the
/// box, and [help] spells out the parameter on hover. A negative [minValue]
/// lets the box accept a minus sign.
class NumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final int decimalPlaces;
  final double step;
  final double minValue;
  final double maxValue;
  final String? prefix;
  final String? suffix;
  final String? help;

  const NumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.decimalPlaces = 0,
    this.step = 1,
    this.minValue = 0,
    this.maxValue = double.infinity,
    this.prefix,
    this.suffix,
    this.help,
  });

  @override
  State<NumberField> createState() => NumberFieldState();
}

class NumberFieldState extends State<NumberField> {
  /// An emptied box falls back to zero, whatever the field's floor is.
  static const emptyValue = 0.0;

  late final TextEditingController _controller = TextEditingController(text: _format(widget.value, widget.decimalPlaces));

  /// The value the arrows step from, which can differ from the box text while
  /// the box is empty or mid-edit.
  late double _value = widget.value;

  /// The value as box text: whole numbers print plainly, and a fraction keeps
  /// its meaningful digits but drops the trailing zeros.
  static String _format(double value, int decimalPlaces) {
    final text = value.toStringAsFixed(decimalPlaces);
    if (decimalPlaces == 0) return text;

    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String get _text => _format(_value, widget.decimalPlaces);

  /// True for a field whose floor is below zero, such as a market drop.
  bool get _isSigned => widget.minValue < 0;

  /// Accepts digits, an optional leading minus sign, and one decimal point
  /// carrying at most [decimalPlaces] digits; drops the rest.
  TextInputFormatter get _formatter {
    final sign = _isSigned ? '-?' : '';
    final pattern = RegExp('^$sign\\d{0,9}(\\.\\d{0,${widget.decimalPlaces}})?\$');

    return TextInputFormatter.withFunction((oldValue, newValue) => pattern.hasMatch(newValue.text) ? newValue : oldValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Only well-formed numbers at or above [minValue] are accepted. An emptied box
  // zeroes the parameter; a half-typed one keeps the last value until it parses.
  void _onChanged(String text) {
    final value = text.isEmpty ? emptyValue : double.tryParse(text);
    if (value != null && value >= widget.minValue && value <= widget.maxValue) {
      setState(() => _value = value);
      widget.onChanged(value);
    }
  }

  void _step(double delta) {
    final value = _value + delta;
    if (value < widget.minValue || value > widget.maxValue) return;

    // Round-trip through the box text so stepping a fractional value by a
    // tenth does not accumulate floating point noise.
    final rounded = double.tryParse(_format(value, widget.decimalPlaces));
    if (rounded == null || rounded < widget.minValue || rounded > widget.maxValue) return;

    setState(() => _value = rounded);
    // Written directly so typing and stepping share one value, caret kept at
    // the end of the new text.
    _controller.value = TextEditingValue(
      text: _text,
      selection: TextSelection.collapsed(offset: _text.length),
    );
    widget.onChanged(rounded);
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      // Under Material 3 an IconButton keeps the 40x40 default minimum and ignores
      // the `constraints` constructor argument, so the size has to come from
      // the style.
      style: IconButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        minimumSize: const Size(_stepperWidth, _stepperHeight),
        maximumSize: const Size(_stepperWidth, _stepperHeight),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The unit sits outside the number, so it does not move with the digits.
    final unitStyle = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12);

    return _fieldRow(
      widget.label,
      SizedBox(
        width: _valueBoxWidth,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.decimalPlaces > 0, signed: _isSigned),
          inputFormatters: [_formatter],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints.tightFor(height: _valueBoxHeight),
            prefixText: widget.prefix,
            prefixStyle: unitStyle,
            suffixText: widget.suffix,
            suffixStyle: unitStyle,
          ),
          onChanged: _onChanged,
        ),
      ),
      // Arrows step the value without touching the keyboard.
      stepper: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(Icons.keyboard_arrow_up, 'Increase', _value < widget.maxValue ? () => _step(widget.step) : null),
          _arrow(Icons.keyboard_arrow_down, 'Decrease', _value > widget.minValue ? () => _step(-widget.step) : null),
        ],
      ),
      help: widget.help,
    );
  }
}

/// A labeled box that edits a list of ages typed as a comma-delimited string,
/// such as "65, 70, 73".
class AgeListField extends StatefulWidget {
  final String label;
  final List<int> value;
  final ValueChanged<List<int>> onChanged;
  final String? help;

  const AgeListField({super.key, required this.label, required this.value, required this.onChanged, this.help});

  @override
  State<AgeListField> createState() => AgeListFieldState();
}

class AgeListFieldState extends State<AgeListField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value.join(', '));

  /// Digits and separators only.
  static final _formatter = FilteringTextInputFormatter.allow(RegExp(r'[\d,\s]'));

  /// The ages typed into [text], with blank and half-typed entries dropped.
  static List<int> _parse(String text) {
    return text
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .whereType<int>()
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _fieldRow(
      widget.label,
      SizedBox(
        width: _valueBoxWidth,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.right,
          keyboardType: TextInputType.number,
          inputFormatters: [_formatter],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints.tightFor(height: _valueBoxHeight),
          ),
          onChanged: (text) => widget.onChanged(_parse(text)),
        ),
      ),
      help: widget.help,
    );
  }
}

/// A labeled age that cannot be edited.
class ConstantField extends StatelessWidget {
  final String label;
  final int value;
  final String? help;

  const ConstantField({super.key, required this.label, required this.value, this.help});

  @override
  Widget build(BuildContext context) {
    return _fieldRow(
      label,
      // Right-aligned into the same column as the editable boxes, so the ages still
      // line up without a box of their own.
      SizedBox(
        width: _valueBoxWidth,
        height: _valueBoxHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text('$value', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
      help: help,
    );
  }
}
