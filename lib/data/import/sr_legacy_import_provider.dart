import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sr_legacy_importer.dart';

final srLegacyDatasetInfoProvider = FutureProvider<SrLegacyDatasetInfo>((ref) {
  return loadSrLegacyDatasetInfo();
});
