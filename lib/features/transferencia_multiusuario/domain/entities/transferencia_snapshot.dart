import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_claim.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_pool_item.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';

/// Resultado de POST /api/transfer/session/{id}/snapshot: cabecera de la
/// sesión + pool + mis asignados en una sola llamada. Se usa solo para la
/// carga inicial de TransferenciaMultiusuarioDetailScreen — los refrescos
/// puntuales (tras reclamar/liberar, o el propio tab "Detalle") siguen
/// usando los endpoints individuales, ver nota en
/// TransferenciaSnapshotModel.fromJson sobre por qué [pool] no se usa para
/// sembrar "Por hacer".
class TransferenciaSnapshot {
  final TransferenciaSession session;
  final List<TransferenciaPoolItem> pool;
  final List<TransferenciaClaim> myClaims;

  const TransferenciaSnapshot({
    required this.session,
    required this.pool,
    required this.myClaims,
  });
}
