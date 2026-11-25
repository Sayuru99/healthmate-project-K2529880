import 'package:material_ui/material_ui.dart';

class WideSegments<T> extends StatelessWidget {
  const WideSegments({super.key, required this.segments, required this.selected, required this.onChanged});

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: box.maxWidth),
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: segments,
              selected: {selected},
              onSelectionChanged: (s) => onChanged(s.single),
            ),
          ),
        ),
      );
}
