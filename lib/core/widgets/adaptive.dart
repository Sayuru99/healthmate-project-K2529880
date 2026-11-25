import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../app_exception.dart';

bool _isApple(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

Future<DateTime?> pickDate(BuildContext context, {required DateTime initial, required DateTime last}) {
  final first = DateTime(2000);
  if (!_isApple(context)) {
    return showDatePicker(context: context, initialDate: initial, firstDate: first, lastDate: last);
  }
  var picked = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) => Container(
      height: 300,
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.pop(context, picked)),
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initial,
              minimumDate: first,
              maximumDate: last,
              onDateTimeChanged: (d) => picked = d,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final apple = _isApple(context);
  Widget button(BuildContext context, String text, bool value) => apple
      ? CupertinoDialogAction(
          isDestructiveAction: value, onPressed: () => Navigator.pop(context, value), child: Text(text))
      : TextButton(
          style: value ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error) : null,
          onPressed: () => Navigator.pop(context, value),
          child: Text(text),
        );
  final answer = await showAdaptiveDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [button(context, 'Cancel', false), button(context, action, true)],
    ),
  );
  return answer ?? false;
}

void showMessage(BuildContext context, String text, {SnackBarAction? action}) =>
    showMessageOn(ScaffoldMessenger.of(context), text, action: action);

void showMessageOn(ScaffoldMessengerState messenger, String text, {SnackBarAction? action}) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text), action: action, persist: false));

Future<bool> tryAction(ScaffoldMessengerState messenger, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on AppException catch (e) {
    showMessageOn(messenger, e.message);
    return false;
  }
}
