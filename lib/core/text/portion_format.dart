import 'decimal_format.dart';

/// Ej.: "1 porción", "0,5 porciones", "4 porciones".
String formatPortions(num portions) =>
    '${formatDecimalEs(portions.toDouble())} '
    '${portions == 1 ? 'porción' : 'porciones'}';
