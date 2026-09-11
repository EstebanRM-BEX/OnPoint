import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/transferencia_multiusuario/domain/entities/transferencia_session.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/bloc/list/transferencia_multiusuario_list_bloc.dart';
import 'package:wms_app/features/transferencia_multiusuario/presentation/widgets/transferencia_session_card_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Listado de sesiones de transferencia multiusuario (fase 1: solo lectura).
/// Espejo de ListRecepcionMultiusuarioScreen: una sesión puede ser trabajada
/// por 1 o más usuarios a la vez.
class ListTransferenciaMultiusuarioScreen extends StatefulWidget {
  const ListTransferenciaMultiusuarioScreen({super.key});

  @override
  State<ListTransferenciaMultiusuarioScreen> createState() =>
      _ListTransferenciaMultiusuarioScreenState();
}

class _ListTransferenciaMultiusuarioScreenState
    extends State<ListTransferenciaMultiusuarioScreen>
    with LoadingDialogMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Offline-first: primero lo que ya hay en SQLite, el refresh manual trae
    // lo nuevo del backend.
    context.read<TransferenciaMultiusuarioListBloc>().add(
      const FetchTransferenciaSessionsFromDbEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSessionTap(TransferenciaSession session) {
    Navigator.pushNamed(
      context,
      AppRoutes.transferenciaMultiusuarioDetail,
      arguments: [session],
    );
  }

  void _refresh() {
    _searchController.clear();
    context.read<TransferenciaMultiusuarioListBloc>().add(
      const SearchTransferenciaSessionEvent(''),
    );
    context.read<TransferenciaMultiusuarioListBloc>().add(
      const FetchTransferenciaSessionsEvent(isLoadinDialog: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: primaryColorApp,
        body: SafeArea(
          child: Container(
            color: Colors.white,
            width: size.width,
            height: size.height,
            child: Column(
              children: [
                _Header(size: size, onRefresh: _refresh),
                DynamicSearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Buscar transferencia',
                  // watchdog: reabre el teclado si el IME del PDA
                  // (Zebra/Urovo/Chainway) lo cierra solo.
                  persistentKeyboard: true,
                  onSearchChanged: (value) => context
                      .read<TransferenciaMultiusuarioListBloc>()
                      .add(SearchTransferenciaSessionEvent(value)),
                  onSearchCleared: () => context
                      .read<TransferenciaMultiusuarioListBloc>()
                      .add(const SearchTransferenciaSessionEvent('')),
                  onTap: () {},
                ),
                Expanded(
                  child:
                      BlocConsumer<
                        TransferenciaMultiusuarioListBloc,
                        TransferenciaMultiusuarioListState
                      >(
                        listener: (context, state) {
                          if (state is TransferenciaMultiusuarioListLoading) {
                            showLoadingDialog('Cargando transferencias...');
                          } else {
                            hideLoadingDialog();
                          }
                          if (state is TransferenciaMultiusuarioListError) {
                            showScrollableErrorDialog(state.message);
                          }
                        },
                        builder: (context, state) {
                          if (state is TransferenciaMultiusuarioListDbLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final sessions = state is TransferenciaSessionsLoaded
                              ? state.sessions
                              : const [];

                          if (sessions.isEmpty) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: const [
                                Text(
                                  'No hay transferencias',
                                  style: TextStyle(fontSize: 14, color: grey),
                                ),
                                Text(
                                  'Intente buscar otra transferencia',
                                  style: TextStyle(fontSize: 12, color: grey),
                                ),
                              ],
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 2),
                            itemCount: sessions.length,
                            itemBuilder: (context, index) {
                              final session = sessions[index];
                              return InkWell(
                                onTap: () => _handleSessionTap(session),
                                child: TransferenciaSessionCardWidget(
                                  session: session,
                                ),
                              );
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.size, required this.onRefresh});

  final Size size;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: primaryColorApp,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      width: double.infinity,
      child: Column(
        children: [
          const WarningWidgetCubit(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: white),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
              GestureDetector(
                onTap: onRefresh,
                child: const Row(
                  children: [
                    Text(
                      'TRASLADO MULTIUSUARIO',
                      style: TextStyle(color: white, fontSize: 16),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.refresh, color: white, size: 20),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }
}
