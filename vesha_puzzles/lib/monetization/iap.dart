/// In-app purchase abstraction. The only product planned is a one-time
/// "Support the artists" purchase that removes ads; no puzzle or story is
/// ever locked behind payment. Default implementation: not available.
library;

import 'package:flutter/foundation.dart';

import 'flags.dart';

class IapProduct {
  const IapProduct(this.id, this.price);
  final String id;
  final String price;
}

abstract class IapService {
  bool get available;
  ValueListenable<bool> get supporter;
  Future<List<IapProduct>> products();
  Future<bool> buySupporter();
  Future<void> restore();
}

class NoIapService implements IapService {
  NoIapService();
  final ValueNotifier<bool> _supporter = ValueNotifier(false);
  @override
  bool get available => false;
  @override
  ValueListenable<bool> get supporter => _supporter;
  @override
  Future<List<IapProduct>> products() async => const [];
  @override
  Future<bool> buySupporter() async => false;
  @override
  Future<void> restore() async {}
}

const String kSupporterProductId = 'support_the_artists';

IapService createIapService() {
  if (kEnableIap) {
    // A real store implementation (package:in_app_purchase) goes here.
    // See docs/MONETIZATION.md.
  }
  return NoIapService();
}
