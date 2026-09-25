import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] (e.g. a bloc's state stream) to the [Listenable] that
/// `GoRouter.refreshListenable` expects, so redirects re-run on each event.
class StreamListenable extends ChangeNotifier {
  StreamListenable(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
