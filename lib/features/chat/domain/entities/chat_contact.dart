/// Representa un usuario/contacto con el que se puede chatear.
///
/// Entidad inmutable y sin dependencias de frameworks (Clean Architecture).
class ChatContact {
  final String id;
  final String name;

  /// URL o ruta del avatar. `null` => se pinta un avatar con iniciales.
  final String? avatarUrl;

  /// Cargo/rol dentro del almacén (p.ej. "Picking", "Supervisor").
  final String role;

  /// Presencia en línea (mock por ahora).
  final bool isOnline;

  const ChatContact({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role = '',
    this.isOnline = false,
  });

  /// Iniciales para el avatar por defecto (máx. 2 letras).
  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ChatContact && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
