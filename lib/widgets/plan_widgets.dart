import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/plan_constants.dart';
import '../models/plan_parameters.dart';

/// Width of the value box, shared by the editable and fixed fields so the
/// numbers line up down the section. Wide enough for a value and its unit,
/// such as "$7,500/mo".
const _valueBoxWidth = 100.0;

/// Height of the value box, likewise shared.
const _valueBoxHeight = 36.0;

/// The space taken by the gap and the stepper arrows of an editable field,
/// reserved by a fixed field so both align.
const _trailingWidth = 28.0;

/// The floor for every rate field. A rate may be negative, down to a total
/// wipeout, but never below that.
const _minRate = -100.0;

/// Below this page width the sidebar sits above the table instead of beside it.
const planSidebarBreakpoint = 1000.0;

/// The fixed width of the sidebar when it sits beside the table.
const planSidebarWidth = 300.0;

/// Sidebar section titles, in display order. Each one stands in for a group of
/// plan parameters; sections without controls yet render a placeholder body.
const planSidebarSections = <String>['Timeline', 'Expenses', 'Salary', 'Growth', 'Market Downturns', 'Roth Conversion'];

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
          // One accordion per section, stacked vertically; the ones without
          // controls yet collapse to a placeholder body.
          for (final (i, title) in planSidebarSections.indexed) ...[
            if (i > 0) const SizedBox(height: 4),
            _SidebarSection(title: title, children: _sectionFields(title, context)),
          ],
        ],
      ),
    );
  }

  /// The controls belonging to [title], or null for a section whose parameters
  /// have no fields yet.
  List<Widget>? _sectionFields(String title, BuildContext context) {
    return switch (title) {
      'Timeline' => [_timelineFields(context)],
      'Expenses' => [_expenseFields(context)],
      'Salary' => [_salaryFields(context)],
      'Growth' => [_growthFields(context)],
      'Market Downturns' => [_downturnFields(context)],
      _ => null,
    };
  }

  /// The controls for the ages that drive the projection.
  Widget _timelineFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntegerField(
          label: 'Retirement Age',
          value: parameters.retirementAge,
          help: 'Age at which salary income stops and retirement spending begins.',
          onChanged: (value) {
            parameters.retirementAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _IntegerField(
          label: 'Social Security Age',
          value: parameters.socialSecurityAge,
          help: 'Age at which Social Security income begins.',
          onChanged: (value) {
            parameters.socialSecurityAge = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _IntegerField(
          label: 'Spouse Social Security Age',
          value: parameters.spouseSocialSecurityAge,
          help: 'Age at which the spouse Social Security income begins.',
          onChanged: (value) {
            parameters.spouseSocialSecurityAge = value;
            onChanged();
          },
        ),
        Divider(height: 20, color: Theme.of(context).colorScheme.outlineVariant),
        _ConstantField(
          label: '401(k) Withdrawal Age',
          value: PlanConstants.fourOhOneKWthdrawalAge,
          help: 'Rule of 55 allows penalty-free 401(k) withdrawals.',
        ),
        const SizedBox(height: 8),
        _ConstantField(
          label: 'IRA Withdrawal Age',
          value: PlanConstants.iraWithdrawalAge,
          help: 'Earliest penalty-free IRA withdrawals.',
        ),
        const SizedBox(height: 8),
        _ConstantField(
          label: 'Medicare Start Age',
          value: PlanConstants.medicareStartAge,
          help: 'Medicare premiums replace medical insurance from this age.',
        ),
        const SizedBox(height: 8),
        _ConstantField(
          label: 'RMD Start Age',
          value: PlanConstants.rmdStartAge,
          help: 'Required minimum distributions from retirement accounts begin at this age.',
        ),
      ],
    );
  }

  /// The controls for monthly expenses.
  Widget _expenseFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumberField(
          label: 'Budget',
          value: parameters.budget,
          step: 100,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly spending in retirement, excluding health insurance.',
          onChanged: (value) {
            parameters.budget = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Medical Insurance',
          value: parameters.medicalInsurance,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Private health insurance monthly premium before Medicare starts at ${PlanConstants.medicareStartAge}.',
          onChanged: (value) {
            parameters.medicalInsurance = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Medicare',
          value: parameters.medicare,
          step: 50,
          prefix: r'$',
          suffix: '/mo',
          help: 'Monthly premium once Medicare starts at ${PlanConstants.medicareStartAge}.',
          onChanged: (value) {
            parameters.medicare = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Inflation Rate',
          value: parameters.inflationRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Expected annual rate by which spending and premiums increase.',
          onChanged: (value) {
            parameters.inflationRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for earned income while working.
  Widget _salaryFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumberField(
          label: 'Base Salary',
          value: parameters.baseSalary,
          step: 5000,
          prefix: r'$',
          help: 'Annual salary before bonus, taxes, and retirement contributions.',
          onChanged: (value) {
            parameters.baseSalary = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Bonus Rate',
          value: parameters.bonusRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual bonus, as a percentage of the base salary.',
          onChanged: (value) {
            parameters.bonusRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the annual return assumed on each account.
  Widget _growthFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumberField(
          label: 'Brokerage Growth Rate',
          value: parameters.brokerageGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the taxable brokerage balance.',
          onChanged: (value) {
            parameters.brokerageGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: '401(k) Growth Rate',
          value: parameters.fourOhOneKGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the 401(k) balance.',
          onChanged: (value) {
            parameters.fourOhOneKGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Traditional IRA Growth Rate',
          value: parameters.traditionalIraGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the pre-tax traditional IRA balance.',
          onChanged: (value) {
            parameters.traditionalIraGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Roth IRA Growth Rate',
          value: parameters.rothIraGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the after-tax Roth IRA balance.',
          onChanged: (value) {
            parameters.rothIraGrowthRate = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'HSA Growth Rate',
          value: parameters.hsaGrowthRate,
          decimalPlaces: 2,
          step: 0.5,
          minValue: _minRate,
          suffix: '%',
          help: 'Annual return on the HSA balance above the cash threshold.',
          onChanged: (value) {
            parameters.hsaGrowthRate = value;
            onChanged();
          },
        ),
      ],
    );
  }

  /// The controls for the ages a market drop is applied at, and how deep it is.
  Widget _downturnFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgeListField(
          label: 'Downturn Ages',
          value: parameters.downMarketAges,
          help: 'Ages at which a downturn strikes, separated by commas.',
          onChanged: (value) {
            parameters.downMarketAges = value;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _NumberField(
          label: 'Downturn Rate',
          value: parameters.downMarketRate,
          decimalPlaces: 2,
          step: 5,
          // A downturn is a loss, so the field has to reach below zero.
          minValue: _minRate,
          suffix: '%',
          help: 'Change applied to the portfolio in a downturn year.',
          onChanged: (value) {
            parameters.downMarketRate = value;
            onChanged();
          },
        ),
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
class _IntegerField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? help;

  const _IntegerField({required this.label, required this.value, required this.onChanged, this.help});

  @override
  Widget build(BuildContext context) {
    return _NumberField(
      label: label,
      value: value.toDouble(),
      help: help,
      onChanged: (value) => onChanged(value.round()),
    );
  }
}

/// A labeled box that edits one numeric plan parameter.
///
/// [decimalPlaces] fixes the precision, zero for whole numbers such as ages and
/// more for money and rates. [prefix] and [suffix] name the unit inside the
/// box, and [help] spells out the parameter out on hover. [minValue] floors the
/// value and the arrows; a negative floor also lets the box accept a minus sign.
class _NumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final int decimalPlaces;
  final double step;
  final double minValue;
  final String? prefix;
  final String? suffix;
  final String? help;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.decimalPlaces = 0,
    this.step = 1,
    this.minValue = 0,
    this.prefix,
    this.suffix,
    this.help,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
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

  /// Accepts digits, a leading minus sign when [minValue] allows one, plus one
  /// decimal point carrying at most [decimalPlaces] digits, and drops the
  /// keystroke that would break that.
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

  // Only well-formed numbers at or above [minValue] are accepted. An emptied
  // box falls back to zero so clearing a field zeroes the parameter, while a
  // half-typed one keeps the last value until it parses.
  void _onChanged(String text) {
    final value = text.isEmpty ? emptyValue : double.tryParse(text);
    if (value != null && value >= widget.minValue) {
      setState(() => _value = value);
      widget.onChanged(value);
    }
  }

  void _step(double delta) {
    final value = _value + delta;
    if (value < widget.minValue) return;

    // Round-trip through the box text so stepping a fractional value by a
    // tenth does not accumulate floating point noise.
    final rounded = double.tryParse(_format(value, widget.decimalPlaces));
    if (rounded == null || rounded < widget.minValue) return;

    setState(() => _value = rounded);
    // Write the box text directly so typing and stepping share one value, and
    // keep the caret at the end of the new text.
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
      constraints: const BoxConstraints.tightFor(width: 24, height: 16),
      style: IconButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The unit sits outside the number, so it does not move with the digits.
    final unitStyle = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12);

    final field = Row(
      children: [
        Expanded(child: Text(widget.label)),
        const SizedBox(width: 8),
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
        const SizedBox(width: 4),
        // Arrows step the value without touching the keyboard.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _arrow(Icons.keyboard_arrow_up, 'Increase', () => _step(widget.step)),
            _arrow(Icons.keyboard_arrow_down, 'Decrease', _value > widget.minValue ? () => _step(-widget.step) : null),
          ],
        ),
      ],
    );

    return widget.help == null ? field : Tooltip(message: widget.help!, child: field);
  }
}

/// A labeled box that edits a list of ages typed as a comma-delimited string,
/// such as "65, 70, 73".
class _AgeListField extends StatefulWidget {
  final String label;
  final List<int> value;
  final ValueChanged<List<int>> onChanged;
  final String? help;

  const _AgeListField({required this.label, required this.value, required this.onChanged, this.help});

  @override
  State<_AgeListField> createState() => _AgeListFieldState();
}

class _AgeListFieldState extends State<_AgeListField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value.join(', '));

  /// Digits and separators only, so the box can never hold a stray letter.
  static final _formatter = FilteringTextInputFormatter.allow(RegExp(r'[\d,\s]'));

  /// The ages typed into [text]. Blank and half-typed entries are dropped, so a
  /// trailing comma or a lone digit still parses into the ages before it.
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
    final field = Row(
      children: [
        Expanded(child: Text(widget.label)),
        const SizedBox(width: 8),
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
        const SizedBox(width: 4),
        // Aligns with the stepper arrows on the editable fields above.
        const SizedBox(width: _trailingWidth),
      ],
    );

    return widget.help == null ? field : Tooltip(message: widget.help!, child: field);
  }
}

/// A labeled age that comes from [PlanConstants] and cannot be edited.
class _ConstantField extends StatelessWidget {
  final String label;
  final int value;
  final String? help;

  const _ConstantField({required this.label, required this.value, this.help});

  @override
  Widget build(BuildContext context) {
    final field = Row(
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
    );

    return help == null ? field : Tooltip(message: help!, child: field);
  }
}
