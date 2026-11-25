import 'dart:math' as math;

import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/dates.dart';

class BarChart extends StatefulWidget {
  const BarChart({super.key, required this.values, required this.goal, required this.color, required this.unit});

  final List<(DateTime, int)> values;
  final int goal;
  final Color color;
  final String unit;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  static const _height = 200.0;
  int? _selected;

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    if (old.values.length != widget.values.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = NumberFormat.decimalPattern();
    final (date, value) = widget.values[_selected ?? widget.values.length - 1];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(mediumDate(date), style: theme.textTheme.labelLarge),
      Text('${number.format(value)} ${widget.unit}',
          style: theme.textTheme.headlineSmall?.copyWith(color: widget.color, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, box) => GestureDetector(
          onTapDown: (d) {
            final i = (d.localPosition.dx / box.maxWidth * widget.values.length).floor();
            setState(() => _selected = i.clamp(0, widget.values.length - 1));
          },
          child: Semantics(
            label: 'Bar chart, ${widget.values.length} days, goal ${widget.goal} ${widget.unit}',
            child: CustomPaint(
              size: Size(box.maxWidth, _height),
              painter: _BarPainter(
                values: widget.values,
                goal: widget.goal,
                selected: _selected ?? widget.values.length - 1,
                color: widget.color,
                lineColor: theme.colorScheme.outline,
                labelStyle: theme.textTheme.labelSmall!,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text('Dashed line: goal of ${number.format(widget.goal)} ${widget.unit}', style: theme.textTheme.bodySmall),
    ]);
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.goal,
    required this.selected,
    required this.color,
    required this.lineColor,
    required this.labelStyle,
  });

  final List<(DateTime, int)> values;
  final int goal;
  final int selected;
  final Color color;
  final Color lineColor;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const labelSpace = 20.0;
    final chartHeight = size.height - labelSpace;
    final top = values.fold(goal, (n, v) => math.max(n, v.$2)) * 1.05;
    final slot = size.width / values.length;
    final barWidth = math.min(slot * 0.6, 28.0);
    final paint = Paint();

    for (final (i, (date, value)) in values.indexed) {
      final x = slot * i + (slot - barWidth) / 2;
      final h = math.max(value / top * chartHeight, 2.0);
      paint.color = color.withValues(alpha: i == selected ? 1 : 0.45);
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, chartHeight - h, barWidth, h),
            topLeft: const Radius.circular(4), topRight: const Radius.circular(4)),
        paint,
      );
      if (values.length <= 7 || (values.length - 1 - i) % 7 == 0) {
        final label = values.length <= 7 ? DateFormat('E').format(date) : shortDate(date);
        final text = TextPainter(
            text: TextSpan(text: label, style: labelStyle), textDirection: TextDirection.ltr)
          ..layout();
        final left = (slot * (i + 0.5) - text.width / 2).clamp(0.0, size.width - text.width);
        text.paint(canvas, Offset(left, chartHeight + 4));
        text.dispose();
      }
    }

    final y = chartHeight - goal / top * chartHeight;
    paint
      ..color = lineColor
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values ||
      old.goal != goal ||
      old.selected != selected ||
      old.color != color ||
      old.lineColor != lineColor;
}
