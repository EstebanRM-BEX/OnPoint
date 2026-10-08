/// Reglas de negocio puras para la gestión de propietarios en Información Rápida.
///
/// Aplica para la selección masiva de productos y transferencias donde no está
/// permitido mezclar productos sin propietario con productos de un propietario
/// específico, ni productos de diferentes propietarios entre sí.
class PropietarioRules {
  const PropietarioRules._();

  /// Normaliza el propietario a una clave canónica.
  ///
  /// Retorna `null` si el producto no tiene manejo de propietario o su nombre
  /// está vacío (representa el grupo "sin propietario").
  static String? normalizeKey({
    required bool? tieneManejoPropietario,
    required String? propietario,
  }) {
    if (tieneManejoPropietario != true) return null;
    final prop = propietario?.trim();
    if (prop == null || prop.isEmpty || prop.toLowerCase() == 'false') {
      return null;
    }
    return prop;
  }

  /// Verifica si dos claves de propietario son compatibles para operar juntos.
  static bool sonCompatibles(String? keyA, String? keyB) {
    return keyA == keyB;
  }

  /// Valida la compatibilidad de un nuevo producto con los ya seleccionados.
  ///
  /// Retorna `null` si son compatibles, o el mensaje de error explicativo si no lo son.
  static String? validarCompatibilidad({
    required String? keyExistente,
    required String? keyNuevo,
  }) {
    if (sonCompatibles(keyExistente, keyNuevo)) return null;

    if (keyExistente == null) {
      return 'No puedes mezclar productos sin propietario con productos de "$keyNuevo"';
    } else if (keyNuevo == null) {
      return 'No puedes mezclar productos de "$keyExistente" con productos sin propietario';
    } else {
      return 'No puedes mezclar productos de "$keyExistente" con productos de "$keyNuevo"';
    }
  }
}
