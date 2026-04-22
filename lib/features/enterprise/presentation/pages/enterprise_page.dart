import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/core/utils/validator_utils.dart';
import 'package:wms_app/injection_container.dart';
import '../../../../src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import '../../../../features/user/presentation/bloc/user_bloc.dart';
import '../../../../src/presentation/widgets/dialog_error_widget.dart';
import '../../domain/entities/recent_url.dart';
import '../bloc/enterprise_bloc.dart';
import '../bloc/enterprise_event.dart';
import '../bloc/enterprise_state.dart';
import '../widgets/database_selection_bottom_sheet.dart';

class EnterprisePage extends StatefulWidget {
  const EnterprisePage({super.key});

  @override
  State<EnterprisePage> createState() => _EnterprisePageState();
}

class _EnterprisePageState extends State<EnterprisePage> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<EnterpriseBloc>().add(const GetRecentUrlsEvent());
    context.read<UserBloc>().add(LoadInfoDeviceEventUser());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EnterpriseBloc, EnterpriseState>(
      listener: (context, state) {
        if (state is EnterpriseFailure) {
          showScrollableErrorDialog(state.message);
        }

        if (state is EnterpriseSuccess) {
          showModalBottomSheet(
            context: context,
            builder: (_) => BlocProvider.value(
              value: context.read<EnterpriseBloc>(),
              child: DatabaseSelectionBottomSheet(
                databases: state.enterpriseInfo.databases,
                url: state.url,
              ),
            ),
          );
        }

        if (state is DatabaseSelectedState) {
          getIt<IStorageService>().nameDatabase = state.database;
          // Navigation logic after selection
          Navigator.pushReplacementNamed(context, 'auth');
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
              autocorrect: false,
              autofocus: true,
              style: const TextStyle(fontSize: 12),
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
      buildWhen: (previous, current) => current is RecentUrlsLoaded,
      builder: (context, state) {
        List<RecentUrl> recentUrls = [];
        if (state is RecentUrlsLoaded) {
          recentUrls = state.recentUrls;
        }

        return Container(
          margin: const EdgeInsets.only(top: 10),
          height: recentUrls.isEmpty ? 100 : 200,
          child: ListView.builder(
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
      onPressed: () async {
        FocusScope.of(context).unfocus();
        if (!_formKey.currentState!.validate()) return;

        final url = _urlController.text.trimRight();
        if (url.endsWith('/')) {
          _urlController.text = url.substring(0, url.length - 1);
        }

        try {
          final result = await InternetAddress.lookup('example.com');
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            context
                .read<EnterpriseBloc>()
                .add(SearchEnterpriseEvent(_urlController.text));
          }
        } catch (e) {
          Get.defaultDialog(
            title: 'Error',
            middleText: 'Error al procesar la solicitud',
            onConfirm: () => Get.back(),
            textConfirm: 'Aceptar',
            confirmTextColor: Colors.white,
            buttonColor: primaryColorApp,
          );
        }
      },
      child: BlocBuilder<EnterpriseBloc, EnterpriseState>(
        builder: (context, state) {
          if (state is EnterpriseLoading) {
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
