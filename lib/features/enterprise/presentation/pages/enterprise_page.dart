import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import '../../../../src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import '../../../../features/user/presentation/bloc/user_bloc.dart';
import '../../../../src/presentation/widgets/dialog_error_widget.dart';
import '../bloc/enterprise_bloc.dart';
import '../bloc/enterprise_event.dart';
import '../bloc/enterprise_state.dart';
import '../widgets/database_selection_bottom_sheet.dart';

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
  late final KeyboardWatchdog _kbWatchdog =
      KeyboardWatchdog(state: this, focusNode: _urlFocusNode);

  @override
  void initState() {
    super.initState();
    context.read<EnterpriseBloc>().add(const GetRecentUrlsEvent());
    context.read<UserBloc>().add(LoadInfoDeviceEventUser());
    WidgetsBinding.instance.addObserver(this);

    // Se pide el foco después del primer frame (en vez de `autofocus: true`)
    // para que no compita con la carga de GetRecentUrlsEvent: si esa carga
    // resuelve justo cuando el teclado está animando su apertura, el salto de
    // layout de la lista de "recientes" (ver _buildRecentUrlsList) podía
    // hacer que el teclado apareciera y se escondiera un par de veces antes
    // de estabilizarse.
    Future.microtask(() {
      if (mounted) _urlFocusNode.requestFocus();
    });
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
                state.errorMessage ?? 'Error al procesar la solicitud');
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
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [primaryColorApp, secondary, primaryColorApp],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const WarningWidgetCubit(),
              const SizedBox(height: 10),
              _buildHeader(context),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: _buildForm(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Bienvenido a OnPoint",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          Center(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                String version = '';
                if (state is DeviceInfoLoaded) {
                  version = state.deviceInfo.appVersion;
                }
                return Text(
                  "Version: $version",
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: primaryColorApp.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextFormField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              autocorrect: false,
              style: const TextStyle(fontSize: 12),
              onTap: () {
                // Cubre el caso donde el campo ya tenía foco pero el IME del
                // PDA cerró el teclado (Chainway/Android 13 y similares).
                SystemChannels.textInput.invokeMethod('TextInput.show');
              },
              decoration: InputDecoration(
                hintText: "Ingrese la url",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                suffixIcon: IconButton(
                  onPressed: () => _urlController.clear(),
                  icon: Icon(Icons.clear, color: primaryColorApp, size: 20),
                ),
              ),
              validator: (value) => Validator.isEmpty(value, context),
            ),
          ),
          _buildRecentUrlsList(),
          const SizedBox(height: 20),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildRecentUrlsList() {
    return BlocBuilder<EnterpriseBloc, EnterpriseState>(
      buildWhen: (previous, current) =>
          previous.recentUrls != current.recentUrls,
      builder: (context, state) {
        final recentUrls = state.recentUrls;

        return Container(
          margin: const EdgeInsets.only(top: 10),
          // Altura fija (antes 100/200 según si había datos): ese salto de
          // layout, si coincidía con la animación de apertura del teclado
          // (autofocus + esta carga resolviendo casi al mismo tiempo), podía
          // hacer que el teclado se mostrara y ocultara varias veces.
          height: 200,
          child: recentUrls.isEmpty
              ? Center(
                  child: Text(
                    'Sin URLs recientes',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                )
              : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: recentUrls.length,
            itemBuilder: (context, index) {
              final item = recentUrls[index];
              return Card(
                color: Colors.white,
                elevation: 2,
                child: ListTile(
                  leading:
                      Icon(Icons.history, color: primaryColorApp, size: 20),
                  title: Text(item.url, style: const TextStyle(fontSize: 12)),
                  subtitle: Text(item.fecha.toString().split(' ')[0],
                      style: const TextStyle(fontSize: 10)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.grey[400]),
                    onPressed: () {
                      context
                          .read<EnterpriseBloc>()
                          .add(DeleteRecentUrlEvent(item.url));
                    },
                  ),
                  onTap: () => _urlController.text = item.url,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return MaterialButton(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      minWidth: double.infinity,
      color: primaryColorApp,
      onPressed: () {
        FocusScope.of(context).unfocus();
        if (!_formKey.currentState!.validate()) return;

        final url = _urlController.text.trimRight();
        if (url.endsWith('/')) {
          _urlController.text = url.substring(0, url.length - 1);
        }

        // La conectividad la valida el repositorio (NetworkInfo);
        // si no hay red llega un status failure al listener.
        context
            .read<EnterpriseBloc>()
            .add(SearchEnterpriseEvent(_urlController.text));
      },
      child: BlocBuilder<EnterpriseBloc, EnterpriseState>(
        buildWhen: (previous, current) => previous.status != current.status,
        builder: (context, state) {
          if (state.status == EnterpriseStatus.searching) {
            return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            );
          }
          return const Text("Consultar", style: TextStyle(color: Colors.white));
        },
      ),
    );
  }
}
