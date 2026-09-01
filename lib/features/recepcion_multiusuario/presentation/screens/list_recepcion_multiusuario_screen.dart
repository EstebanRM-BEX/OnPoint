import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/routes/app_router.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/list/recepcion_multiusuario_list_bloc.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/widgets/recepcion_session_card_widget.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';

/// Listado de sesiones de recepción multiusuario (fase 1: solo lectura).
/// A diferencia de recepción individual, no maneja asignación de responsable
/// ni tiempos de inicio — una sesión puede ser trabajada por 1 o más usuarios
/// a la vez.
class ListRecepcionMultiusuarioScreen extends StatefulWidget {
  const ListRecepcionMultiusuarioScreen({super.key});

  @override
  State<ListRecepcionMultiusuarioScreen> createState() =>
      _ListRecepcionMultiusuarioScreenState();
}

class _ListRecepcionMultiusuarioScreenState
    extends State<ListRecepcionMultiusuarioScreen>
    with LoadingDialogMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Offline-first: primero lo que ya hay en SQLite, el refresh manual trae
    // lo nuevo del backend.
    context.read<RecepcionMultiusuarioListBloc>().add(
      const FetchRecepcionSessionsFromDbEvent(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSessionTap(RecepcionSession session) {
    Navigator.pushNamed(
      context,
      AppRoutes.recepcionMultiusuarioDetail,
      arguments: [session],
    );
  }

  void _refresh() {
    _searchController.clear();
    context.read<RecepcionMultiusuarioListBloc>().add(
      const SearchRecepcionSessionEvent(''),
    );
    context.read<RecepcionMultiusuarioListBloc>().add(
      const FetchRecepcionSessionsEvent(isLoadinDialog: false),
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
                  hintText: 'Buscar recepción',
                  // watchdog: reabre el teclado si el IME del PDA
                  // (Zebra/Urovo/Chainway) lo cierra solo.
                  persistentKeyboard: true,
                  onSearchChanged: (value) => context
                      .read<RecepcionMultiusuarioListBloc>()
                      .add(SearchRecepcionSessionEvent(value)),
                  onSearchCleared: () => context
                      .read<RecepcionMultiusuarioListBloc>()
                      .add(const SearchRecepcionSessionEvent('')),
                  onTap: () {},
                ),
                Expanded(
                  child:
                      BlocConsumer<
                        RecepcionMultiusuarioListBloc,
                        RecepcionMultiusuarioListState
                      >(
                        listener: (context, state) {
                          if (state is RecepcionMultiusuarioListLoading) {
                            showLoadingDialog('Cargando recepciones...');
                          } else {
                            hideLoadingDialog();
                          }
                          if (state is RecepcionMultiusuarioListError) {
                            showScrollableErrorDialog(state.message);
                          }
                        },
                        builder: (context, state) {
                          if (state is RecepcionMultiusuarioListDbLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final sessions = state is RecepcionSessionsLoaded
                              ? state.sessions
                              : const [];

                          if (sessions.isEmpty) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: const [
                                Text(
                                  'No hay recepciones',
                                  style: TextStyle(fontSize: 14, color: grey),
                                ),
                                Text(
                                  'Intente buscar otra recepción',
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
                                child: RecepcionSessionCardWidget(
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
                      'RECEPCIÓN MULTIUSUARIO',
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
