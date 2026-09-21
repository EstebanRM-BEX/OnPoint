import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import '../../../../src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import '../../../../features/user/presentation/bloc/user_bloc.dart';
import '../../../../src/presentation/widgets/dialog_error_widget.dart';
import '../bloc/enterprise_bloc.dart';
import '../bloc/enterprise_event.dart';
import '../bloc/enterprise_state.dart';
import 'package:wms_app/shared/widgets/auth/auth_brand_gradient.dart';
import 'package:wms_app/shared/widgets/auth/auth_buttons.dart';
import 'package:wms_app/shared/widgets/auth/onpoint_brand_header.dart';
import 'package:wms_app/shared/widgets/confirm_delete_dialog.dart';
import '../widgets/database_selection_bottom_sheet.dart';
import '../widgets/recent_url_tile.dart';
import '../widgets/server_url_field.dart';

class EnterprisePage extends StatefulWidget {
  const EnterprisePage({super.key});

  @override
  State<EnterprisePage> createState() => _EnterprisePageState();
}

class _EnterprisePageState extends State<EnterprisePage>
    with WidgetsBindingObserver {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Watchdog de teclado: en PDAs con escáner activo (Zebra/Urovo/Chainway)
  // el IME del sistema puede ocultar el teclado suave por sí solo mientras
  // el campo conserva el foco. Ver lib/shared/utils/keyboard_watchdog.dart.
  late final KeyboardWatchdog _kbWatchdog = KeyboardWatchdog(
    state: this,
    focusNode: _urlFocusNode,
  );

  @override
  void initState() {
    super.initState();
    context.read<EnterpriseBloc>().add(const GetRecentUrlsEvent());
    context.read<UserBloc>().add(LoadInfoDeviceEventUser());
    WidgetsBinding.instance.addObserver(this);

    _focusAfterRecentsLoaded();
  }

  /// Pide el foco (y con él el teclado) solo cuando la lista de recientes ya
  /// cargó. La lista crece según cuántas URLs haya; si esa carga resolvía
  /// mientras el teclado animaba su apertura, el salto de layout podía hacer
  /// que el teclado apareciera y se escondiera un par de veces. El timeout
  /// cubre el historial vacío (el estado no cambia → el stream no emite).
  Future<void> _focusAfterRecentsLoaded() async {
    final bloc = context.read<EnterpriseBloc>();
    try {
      await bloc.stream
          .firstWhere(
            (s) =>
                s.recentUrls.isNotEmpty || s.status == EnterpriseStatus.failure,
          )
          .timeout(const Duration(milliseconds: 600));
    } catch (_) {}
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _urlFocusNode.requestFocus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdog.dispose();
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _kbWatchdog.onMetricsChanged();

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnterpriseBloc, EnterpriseState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case EnterpriseStatus.failure:
            showScrollableErrorDialog(
              state.errorMessage ?? 'Error al procesar la solicitud',
            );
            break;
          case EnterpriseStatus.success:
            showModalBottomSheet(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<EnterpriseBloc>(),
                child: DatabaseSelectionBottomSheet(
                  databases: state.enterpriseInfo?.databases ?? const [],
                  url: state.url,
                ),
              ),
            );
            break;
          case EnterpriseStatus.databaseSelected:
            getIt<IStorageService>().nameDatabase = state.selectedDatabase!;
            Navigator.pushReplacementNamed(context, 'auth');
            break;
          case EnterpriseStatus.initial:
          case EnterpriseStatus.searching:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Cabecera y hoja van dentro del mismo scroll: con el teclado
            // abierto (PDAs de pantalla corta) todo se desplaza y el campo
            // queda visible, sin tener que encoger/ocultar la cabecera
            // (ese cambio de layout durante la animación del teclado es lo
            // que lo hacía parpadear).
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: authBrandGradient),
                child: SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: WarningWidgetCubit()),
                      const SliverToBoxAdapter(child: OnPointBrandHeader()),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildSheet(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Botón fijo fuera del scroll: sube pegado al teclado.
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: _buildSubmitButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ServerUrlField(
              controller: _urlController,
              focusNode: _urlFocusNode,
            ),
            const SizedBox(height: 24),
            _buildRecentUrlsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUrlsList() {
    return BlocBuilder<EnterpriseBloc, EnterpriseState>(
      buildWhen: (previous, current) =>
          previous.recentUrls != current.recentUrls,
      builder: (context, state) {
        final recentUrls = state.recentUrls;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text(
                    'CONEXIONES RECIENTES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${recentUrls.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (recentUrls.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirmClearAll(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Limpiar todo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Se muestran todas: la lista va dentro del scroll de la página
            // (ver _focusAfterRecentsLoaded para el tema del teclado).
            if (recentUrls.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Sin conexiones recientes',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
              )
            else
              for (final item in recentUrls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RecentUrlTile(
                    item: item,
                    onTap: () => _selectRecent(item.url),
                    onDelete: () => _confirmDelete(context, item.url),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, String url) async {
    final bloc = context.read<EnterpriseBloc>();
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Eliminar conexión',
      message: '¿Eliminar $url de las conexiones recientes?',
    );
    if (confirmed) bloc.add(DeleteRecentUrlEvent(url));
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final bloc = context.read<EnterpriseBloc>();
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Limpiar conexiones',
      message:
          'Se eliminarán todas las conexiones recientes. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Limpiar todo',
    );
    if (confirmed) bloc.add(const ClearRecentUrlsEvent());
  }

  /// Carga una URL reciente en el campo con el cursor al final, sin tocar el
  /// foco (así el teclado no se abre/cierra al tocar una tarjeta).
  void _selectRecent(String url) {
    _urlController.value = TextEditingValue(
      text: url,
      selection: TextSelection.collapsed(offset: url.length),
    );
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final url = _urlController.text.trimRight();
    if (url.endsWith('/')) {
      _urlController.text = url.substring(0, url.length - 1);
    }

    // La conectividad la valida el repositorio (NetworkInfo);
    // si no hay red llega un status failure al listener.
    context.read<EnterpriseBloc>().add(
      SearchEnterpriseEvent(_urlController.text),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<EnterpriseBloc, EnterpriseState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => AuthPrimaryButton(
        label: 'Consultar',
        loading: state.status == EnterpriseStatus.searching,
        onPressed: () => _submit(context),
      ),
    );
  }
}
