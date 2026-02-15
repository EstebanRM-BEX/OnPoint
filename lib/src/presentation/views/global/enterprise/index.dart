// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:get/get.dart';
import 'package:wms_app/src/core/constans/colors.dart';
import 'package:wms_app/src/core/utils/validator_utils.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/global/enterprise/bloc/entreprise_bloc.dart';
import 'package:wms_app/src/presentation/views/global/login/widgets/list_database.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/keyboard_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectEnterpricePage extends StatelessWidget {
  const SelectEnterpricePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EntrepriseBloc(),
      child: BlocConsumer<EntrepriseBloc, EntrepriseState>(
        listener: (context, state) {
          print('state $state');

          //estado de error
          if (state is EntrepriseFailure) {
            showScrollableErrorDialog(state.error);
          }

          if (state is EntrepriseSuccess) {
            showModalBottomSheet(
                context: context,
                builder: (c) => DetailClientSale(
                      listDB: context.read<EntrepriseBloc>().entrepriceList,
                    ));
          }
        },
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async {
              return false;
            },
            child: Scaffold(
              body: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        colors: [primaryColorApp, secondary, primaryColorApp])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const WarningWidgetCubit(),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25, bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Text(
                            "Bienvenido a OnPoint",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22),
                          )),

                          Center(
                            child: Text(
                                "Version: ${context.read<UserBloc>().versionApp}",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          )
                          //FadeIn(duration: const  Duration(microseconds: 3), child: const Text("Bienvenido a BEXMovil Provigas", style: TextStyle(color: Colors.white, fontSize: 18),)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 5),
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(40),
                                topRight: Radius.circular(40))),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 30, right: 30),
                                  child: _loginForm()),
                              Visibility(
                                visible: context
                                    .read<UserBloc>()
                                    .fabricante
                                    .contains("Zebra"),
                                child: CustomKeyboard(
                                    isLogin: true,
                                    controller: context
                                        .read<EntrepriseBloc>()
                                        .entrepriceController,
                                    onchanged: () {}),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ignore: camel_case_types
class _loginForm extends StatelessWidget {
  _loginForm();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formkey,
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
                      offset: const Offset(0, 10))
                ]),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: TextFormField(
                    autocorrect: false,
                    autofocus: true,
                    showCursor: true,
                    controller:
                        context.read<EntrepriseBloc>().entrepriceController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                        disabledBorder: const OutlineInputBorder(),
                        hintText: "Ingrese la url",
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                            onPressed: () {
                              context
                                  .read<EntrepriseBloc>()
                                  .entrepriceController
                                  .clear();
                            },
                            icon: Icon(
                              Icons.clear,
                              color: primaryColorApp,
                              size: 20,
                            ))),
                    validator: ((value) => Validator.isEmpty(value, context)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 5),
            height: context.read<EntrepriseBloc>().recentUrls.isEmpty
                ? 150
                : context.read<UserBloc>().fabricante.contains("Zebra")
                    ? 150
                    : 200, // Altura de la lista de URLs recientes
            child: ListView.builder(
              padding: const EdgeInsets.all(0),
              itemCount: context.read<EntrepriseBloc>().recentUrls.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      Icons.history,
                      color: primaryColorApp,
                      size: 20,
                    ),
                    title: Text(
                        context.read<EntrepriseBloc>().recentUrls[index].url,
                        style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                        context.read<EntrepriseBloc>().recentUrls[index].fecha,
                        style: const TextStyle(fontSize: 10)),
                    trailing: IconButton(
                      icon:
                          Icon(Icons.delete, size: 20, color: Colors.grey[400]),
                      onPressed: () {
                        context.read<EntrepriseBloc>().add(DeleteUrl(
                            context
                                .read<EntrepriseBloc>()
                                .recentUrls[index]
                                .url,
                            index));
                      },
                    ),
                    onTap: () {
                      context.read<EntrepriseBloc>().entrepriceController.text =
                          context
                              .read<EntrepriseBloc>()
                              .recentUrls[index]
                              .url; // Cambiar la URL
                    },
                  ),
                );
              },
            ),
          ),
          MaterialButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              disabledColor: Colors.grey,
              elevation: 0,
              minWidth: double.infinity,
              color: primaryColorApp,
              onPressed: () async {
                FocusScope.of(context).unfocus();

                if (!_formkey.currentState!.validate()) return;

                try {
                  final result = await InternetAddress.lookup('example.com');
                  if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
                    context
                        .read<EntrepriseBloc>()
                        .add(EntrepriseButtonPressed());
                  }
                } catch (e) {
                  Get.defaultDialog(
                    title: '360 Software Informa',
                    titleStyle: TextStyle(color: Colors.red, fontSize: 18),
                    middleText: 'Error al procesar la solicitud',
                    middleTextStyle: TextStyle(color: black, fontSize: 14),
                    backgroundColor: Colors.white,
                    radius: 10,
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColorApp,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Aceptar', style: TextStyle(color: white)),
                      ),
                    ],
                  );
                }
              },
              child: BlocBuilder<EntrepriseBloc, EntrepriseState>(
                builder: (context, state) {
                  if (state is EntrepriseLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }
                  return const Text(
                    "Consultar",
                    style: TextStyle(color: Colors.white),
                  );
                },
              )),
        ],
      ),
    );
  }
}
