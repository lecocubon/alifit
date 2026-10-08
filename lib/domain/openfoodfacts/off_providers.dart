import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/openfoodfacts/http_off_client.dart';
import 'off_client.dart';

final offClientProvider = Provider<OffClient>((ref) => HttpOffClient());
