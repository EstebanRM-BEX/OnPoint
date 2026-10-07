part of 'packing_confirm_bloc.dart';

/// Validación que Odoo frenó por productos vencidos, esperando decisión.
class VencidosPendientes extends Equatable {
  final PedidoPack pedido;
  final bool crearBackorder;
  const VencidosPendientes(this.pedido, this.crearBackorder);

  @override
  List<Object?> get props => [pedido, crearBackorder];
}

class PackingConfirmState extends Equatable {
  final bool validado;
  final bool conBackorder;

  /// No null = la UI debe preguntar si acepta productos vencidos.
  final VencidosPendientes? vencidosPendientes;
  final PackingOperacion operacion;

  const PackingConfirmState({
    this.validado = false,
    this.conBackorder = false,
    this.vencidosPendientes,
    this.operacion = PackingOperacion.ninguna,
  });

  PackingConfirmState copyWith({
    bool? validado,
    bool? conBackorder,
    VencidosPendientes? vencidosPendientes,
    bool limpiarVencidos = false,
    PackingOperacion? operacion,
  }) {
    return PackingConfirmState(
      validado: validado ?? this.validado,
      conBackorder: conBackorder ?? this.conBackorder,
      vencidosPendientes: limpiarVencidos
          ? null
          : (vencidosPendientes ?? this.vencidosPendientes),
      operacion: operacion ?? this.operacion,
    );
  }

  @override
  List<Object?> get props => [
    validado,
    conBackorder,
    vencidosPendientes,
    operacion,
  ];
}
