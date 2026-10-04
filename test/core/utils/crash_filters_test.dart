import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/utils/diagnostics/crash_filters.dart';

void main() {
  FlutterErrorDetails details(Object error, String stack) =>
      FlutterErrorDetails(exception: error, stack: StackTrace.fromString(stack));

  const pickerStack = '''
#0      List.single (dart:core-patch/array.dart:123)
#1      ScrollController.position (package:flutter/src/widgets/scroll_controller.dart:173:12)
#2      FixedExtentScrollController.selectedItem (package:flutter/src/widgets/list_wheel_scroll_view.dart:268:12)
#3      _CupertinoPickerState._handleChildTap (package:flutter/src/cupertino/picker.dart:321:51)
''';

  test('toque en la rueda de fecha sin posición → benigno (no fatal)', () {
    expect(
      isBenignDatePickerTapError(details(StateError('No element'), pickerStack)),
      isTrue,
    );
  });

  test('el mismo "No element" en otra parte → sigue siendo fatal', () {
    expect(
      isBenignDatePickerTapError(
        details(StateError('No element'), '#0 List.first (dart:core)\n'
            '#1 _InfoRapidaScreenState._buildContent (info_rapida/index.dart:218)'),
      ),
      isFalse,
    );
  });

  test('otro error en el picker → sigue siendo fatal', () {
    expect(
      isBenignDatePickerTapError(
        details(ArgumentError('x'), pickerStack),
      ),
      isFalse,
    );
  });
}
