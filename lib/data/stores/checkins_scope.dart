import 'package:flutter/widgets.dart';

import 'checkins_store.dart';

class CheckinsScope extends InheritedNotifier<CheckinsStore> {
  const CheckinsScope({
    super.key,
    required CheckinsStore super.notifier,
    required super.child,
  });

  static CheckinsStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CheckinsScope>();
    assert(scope != null, 'CheckinsScope not found in widget tree');
    return scope!.notifier!;
  }
}
