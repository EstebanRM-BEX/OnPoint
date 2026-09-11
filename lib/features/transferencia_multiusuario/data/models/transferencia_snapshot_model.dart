import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_claim_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_multiusuario_json_utils.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_pool_item_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/data/models/transferencia_session_model.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_snapshot.dart';

class TransferenciaSnapshotModel extends TransferenciaSnapshot {
  TransferenciaSnapshotModel({
    required super.session,
    required super.pool,
    required super.myClaims,
  });

  /// [json] es el `data` de la respuesta de
  /// /api/transfer/session/{id}/snapshot: los mismos campos de cabecera que
  /// un elemento de /transfer/sessions (se reusa [TransferenciaSessionModel],
  /// que solo lee las claves que le interesan) más `pool` y `my_claims`.
  ///
  /// NOTA importante: `pool` acá viene SIN el filtro de "libres" — el
  /// ejemplo real trae una tarea con `asignaciones_activas: 1` (ya
  /// reclamada por alguien), algo que /transfer/session/{id}/pool con
  /// verification: false ("Por hacer", solo lo libre) no debería incluir
  /// según su propia documentación. Por eso [TransferenciaSnapshot.pool]
  /// se usa únicamente para sembrar "Terminados" (verification: true,
  /// que sí incluye tareas agotadas/reclamadas) — "Por hacer" sigue
  /// pidiéndose con su propio fetch en vivo.
  factory TransferenciaSnapshotModel.fromJson(Map<String, dynamic> json) {
    final sessionId = dynamicToInt(json['id']) ?? 0;

    final poolJson = json['pool'] as List? ?? [];
    final myClaimsJson = json['my_claims'] as List? ?? [];

    return TransferenciaSnapshotModel(
      session: TransferenciaSessionModel.fromJson(json),
      pool: poolJson
          .map(
            (item) => TransferenciaPoolItemModel.fromJson(
              item as Map<String, dynamic>,
              sessionId: sessionId,
            ),
          )
          .toList(),
      myClaims: myClaimsJson
          .map(
            (item) =>
                TransferenciaClaimModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
