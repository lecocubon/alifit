import 'off_product.dart';

/// El código de barras no existe en la base de Open Food Facts.
class OffNotFoundException implements Exception {
  const OffNotFoundException(this.barcode);

  final String barcode;
}

/// No se pudo contactar el servicio (sin conexión, timeout, error del
/// servidor, respuesta inválida, etc.). No implica que el producto no
/// exista.
class OffNetworkException implements Exception {
  const OffNetworkException(this.message);

  final String message;
}

abstract class OffClient {
  /// Consulta de solo lectura a Open Food Facts, sin credenciales.
  Future<OffProduct> fetchProduct(String barcode);
}
