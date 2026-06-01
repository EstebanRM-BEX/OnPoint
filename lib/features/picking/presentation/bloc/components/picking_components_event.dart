part of 'picking_components_bloc.dart';

@immutable
sealed class PickingComponentsEvent {}

// Carga componentes desde Odoo e inserta en SQLite
class FetchPickingComponentesEvent extends PickingComponentsEvent {
  final bool isLoadinDialog;
  FetchPickingComponentesEvent(this.isLoadinDialog);
}

// Carga componentes desde SQLite
class FetchPickingComponentesFromDBEvent extends PickingComponentsEvent {
  final bool isLoadinDialog;
  FetchPickingComponentesFromDBEvent(this.isLoadinDialog);
}

// Carga historial de componentes finalizados desde Odoo por fecha
class LoadHistoryPickComponentEvent extends PickingComponentsEvent {
  final bool isLoadinDialog;
  final String date;
  LoadHistoryPickComponentEvent(this.isLoadinDialog, this.date);
}
