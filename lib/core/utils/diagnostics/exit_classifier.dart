/// Clasificación de cierres para [ExitDiagnostics], sin dependencias de
/// Firebase ni de plataforma para poder probarla.
///
/// Crashlytics agrupa los no fatales por **stack**, no por mensaje: todo lo que
/// se reporta desde el mismo `recordError` cae en el mismo issue aunque el
/// texto cambie. Por eso cada grupo lleva su propia pila sintética
/// ([pilaDeGrupo]) y aparece como un issue separado
/// (`ExitDiagnostics.cierre_CRASH`, `ExitDiagnostics.cierre_LOW_MEMORY`…).
library;

/// Motivos de salida normales: no se reportan.
const motivosBenignos = {
  'EXIT_SELF',
  'USER_REQUESTED',
  'USER_STOPPED',
  'PACKAGE_UPDATED',
  'PACKAGE_STATE_CHANGE',
  'FREEZER',
};

/// Estado que se guarda antes de una salida intencional (`exit(0)`).
const estadoSalidaIntencional = 'exit';

/// Una salida del proceso según ApplicationExitInfo (Android 11+).
class SalidaAndroid {
  const SalidaAndroid({
    required this.reason,
    required this.description,
    required this.timestamp,
    this.importance,
    this.rss,
    this.pss,
  });

  factory SalidaAndroid.fromMap(Map<String, dynamic> map) => SalidaAndroid(
    reason: '${map['reason']}',
    description: '${map['description']}',
    timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    importance: (map['importance'] as num?)?.toInt(),
    rss: (map['rss'] as num?)?.toInt(),
    pss: (map['pss'] as num?)?.toInt(),
  );

  final String reason;
  final String description;
  final int timestamp;

  /// 100 = primer plano.
  final int? importance;
  final int? rss;
  final int? pss;

  /// Limpieza normal del sistema, no un cierre anómalo. `OTHER` + "empty
  /// for too long": Android liberó un proceso en caché que llevaba mucho
  /// tiempo en segundo plano.
  bool get esBenigna =>
      motivosBenignos.contains(reason) ||
      (reason == 'OTHER' && description.contains('empty for'));

  List<String> get informacion => [
    'reason: $reason',
    'description: $description',
    'importance: $importance (100 = primer plano)',
    'rss_kb: $rss',
    'pss_kb: $pss',
    'cuando: ${DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String()}',
  ];
}

/// Issue al que va un cierre: [grupo] define la pila (y con ella el issue) y
/// [titulo] el mensaje de la excepción.
class CierreClasificado {
  const CierreClasificado(this.grupo, this.titulo);

  final String grupo;
  final String titulo;

  @override
  bool operator ==(Object other) =>
      other is CierreClasificado &&
      other.grupo == grupo &&
      other.titulo == titulo;

  @override
  int get hashCode => Object.hash(grupo, titulo);

  @override
  String toString() => 'CierreClasificado($grupo, $titulo)';
}

/// La sesión terminó con la app a la vista: no pasó por segundo plano ni
/// salió a propósito.
bool terminoEnPrimerPlano(String? ultimoEstado) =>
    ultimoEstado == 'resumed' || ultimoEstado == 'inactive';

/// Margen para la salida que terminó la sesión anterior: el latido se
/// escribe antes de morir, pero los relojes de Dart y del sistema no marcan
/// exactamente el mismo instante.
const _toleranciaMs = 5000;

/// Salida que terminó la sesión anterior: la primera que Android registró
/// después del último latido. `null` si no hay ninguna (Android < 11, o el
/// equipo se apagó sin que el sistema llegara a registrar la salida).
SalidaAndroid? salidaDeSesionPrevia(
  List<SalidaAndroid> salidas,
  int? ultimoLatidoMs,
) {
  if (ultimoLatidoMs == null) return null;
  final candidatas =
      salidas
          .where((s) => s.timestamp >= ultimoLatidoMs - _toleranciaMs)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return candidatas.isEmpty ? null : candidatas.first;
}

/// Decide si la sesión anterior terminó de forma anómala con la app a la
/// vista y a qué issue va. `null` = no se reporta.
///
/// - Estado distinto de `resumed`/`inactive` (incluida la salida
///   intencional): la app pasó por segundo plano o salió a propósito.
/// - Con motivo de Android: un issue por motivo. Si el motivo es benigno
///   (p. ej. el MDM actualizó la app con la app abierta) no se reporta.
/// - Sin motivo en Android 11+: el sistema no registró la muerte del
///   proceso, así que se apagó el equipo (batería, reinicio, botón).
/// - Sin motivo en Android < 11: el sistema no informa motivos.
CierreClasificado? clasificarCierrePrevio({
  required String? ultimoEstado,
  required SalidaAndroid? salida,
  required bool soReportaSalidas,
}) {
  if (!terminoEnPrimerPlano(ultimoEstado)) return null;

  if (salida != null) {
    if (salida.esBenigna) return null;
    return CierreClasificado(
      'cierre_${salida.reason}',
      'Cierre en primer plano [${salida.reason}]: la sesión anterior '
          'terminó en "$ultimoEstado"',
    );
  }

  if (soReportaSalidas) {
    return const CierreClasificado(
      'cierre_equipo_apagado',
      'Equipo apagado con la app abierta (batería, reinicio o botón de '
          'encendido): Android no registró la salida del proceso',
    );
  }

  return CierreClasificado(
    'cierre_sin_motivo',
    'Cierre en primer plano sin motivo (Android < 11): la sesión anterior '
        'terminó en "$ultimoEstado"',
  );
}

/// Grupo para una salida de Android que no corresponde a la sesión previa
/// (p. ej. LOW_MEMORY con la app en segundo plano).
String grupoDeSalida(SalidaAndroid salida) => 'salida_${salida.reason}';

/// Pila sintética de un solo frame: Crashlytics agrupa por pila, así que cada
/// [grupo] queda como un issue propio con nombre legible.
StackTrace pilaDeGrupo(String grupo) => StackTrace.fromString(
  '#0      ExitDiagnostics.$grupo '
  '(package:wms_app/core/utils/diagnostics/exit_diagnostics.dart:1:1)\n',
);
