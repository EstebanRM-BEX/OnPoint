import 'package:equatable/equatable.dart';
import '../../domain/entities/enterprise_info.dart';
import '../../domain/entities/recent_url.dart';

enum EnterpriseStatus {
  initial,

  /// Buscando las bases de datos de una URL
  searching,

  /// Búsqueda exitosa: [EnterpriseState.enterpriseInfo] tiene las bases
  success,

  /// Error de búsqueda o de historial: ver [EnterpriseState.errorMessage]
  failure,

  /// El usuario eligió base de datos: ver [EnterpriseState.selectedDatabase]
  databaseSelected,
}

/// Estado único del módulo enterprise.
///
/// Un solo objeto con `copyWith` evita que eventos concurrentes se pisen
/// entre sí (p. ej. cargar el historial ya no borra el resultado de una
/// búsqueda en curso, como pasaba con las subclases separadas).
class EnterpriseState extends Equatable {
  final EnterpriseStatus status;
  final List<RecentUrl> recentUrls;
  final EnterpriseInfo? enterpriseInfo;
  final String url;
  final String? errorMessage;
  final String? selectedDatabase;

  const EnterpriseState({
    this.status = EnterpriseStatus.initial,
    this.recentUrls = const [],
    this.enterpriseInfo,
    this.url = '',
    this.errorMessage,
    this.selectedDatabase,
  });

  EnterpriseState copyWith({
    EnterpriseStatus? status,
    List<RecentUrl>? recentUrls,
    EnterpriseInfo? enterpriseInfo,
    String? url,
    String? errorMessage,
    String? selectedDatabase,
  }) {
    return EnterpriseState(
      status: status ?? this.status,
      recentUrls: recentUrls ?? this.recentUrls,
      enterpriseInfo: enterpriseInfo ?? this.enterpriseInfo,
      url: url ?? this.url,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDatabase: selectedDatabase ?? this.selectedDatabase,
    );
  }

  @override
  List<Object?> get props =>
      [status, recentUrls, enterpriseInfo, url, errorMessage, selectedDatabase];
}
