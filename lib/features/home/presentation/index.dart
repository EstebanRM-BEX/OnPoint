// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';
import 'package:wms_app/injection_container.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:wms_app/features/home/presentation/widgets/background.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_devoluciones_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_inventario_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_picking_componentes_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/dialog_picking_widget.dart';
import 'package:wms_app/features/home/presentation/widgets/widget.dart';
import 'package:wms_app/src/presentation/views/info%20rapida/modules/quick%20info/bloc/info_rapida_bloc.dart';
import 'package:wms_app/src/presentation/views/recepcion/modules/individual/screens/bloc/recepcion_bloc.dart';
import 'package:wms_app/src/presentation/views/transferencias/modules/transfer-interna/bloc/transferencia_bloc.dart';
import 'package:wms_app/features/user/presentation/bloc/user_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-batch/bloc/wms_packing_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing-consolidade/bloc/packing_consolidade_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/bloc/packing_pedido_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/packing/screens/widgets/dialog_packing_widget.dart';
import 'package:wms_app/src/presentation/views/wms_picking/bloc/wms_picking_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/blocs/batch_bloc/batch_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Añadimos el observer para escuchar el ciclo de vida de la app.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 1. Precarga de SVGs (Mantenemos esto aquí)
    final List<String> iconsToCache = [
      'picking.svg',
      'packing.svg',
      'devoluciones.svg',
      'recepcion.svg',
      'transferencia.svg',
      'inventario.svg',
      'pc.svg',
      'entrega.svg',
      'info.svg',
    ];

    for (final iconName in iconsToCache) {
      try {
        final loader = SvgAssetLoader('assets/icons/$iconName');
        svg.cache
            .putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));
      } catch (e) {
        // Ignorar errores de precarga
      }
    }

    // 2. 🚀 OPTIMIZACIÓN FINAL: Post-Frame Callback
    // Esperamos a que el primer frame se haya dibujado completamente
    // antes de saturar el hilo con peticiones a BLoCs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _onDataUser();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // 1. Mostrar el diálogo (Ya no guardamos el contexto en una variable 'dialogContext')
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return const DialogLoading(
              message: "Espere un momento...",
            );
          },
        );

        // 2. Disparar evento de carga
        context.read<UserBloc>().add(LoadInfoDeviceEventUser());

        // 3. Cierre asíncrono seguro
        Future.delayed(const Duration(seconds: 1), () {
          // ✅ CORRECCIÓN: Verificar 'mounted' asegura que el widget (HomePage) sigue vivo
          if (mounted) {
            // Usamos 'context' (el propio de HomePage).
            // 'rootNavigator: true' accede al navegador raíz donde se mostró el diálogo.
            // .pop() cierra la última ruta apilada (que es tu diálogo).
            Navigator.of(context, rootNavigator: true).pop();
          }
        });
      }
    }
  }

  void _onDataUser() async {
    context.read<HomeBloc>().add(HomeLoadData());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },

      // 1. Segundo Listener: HomeBloc (Hijo del primero)
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          print(" ❤️‍🔥 STATE: $state");

          if (state is HomeLoadErrorState) {
            Get.snackbar(
              'Error',
              'Error al cargar los datos del usuario',
              backgroundColor: white,
              colorText: primaryColorApp,
              icon: Icon(Icons.error, color: Colors.red),
            );
          }

          if (state is AppVersionUpdateState) {
            showDialog(
                context: context,
                builder: (context) {
                  return UpdateAppDialog();
                });
          }
        },
        // 3. Child Visual: RefreshIndicator y Scaffold
        child: RefreshIndicator(
          onRefresh: () async {
            // 1. Validar si el widget sigue montado antes de hacer nada
            if (!context.mounted) return;

            // mostramos dialogo
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return const DialogLoading(
                  message: "Espere un momento...",
                );
              },
            );

            //* generales
            // Usamos context.read en lugar de context.read directo si es posible capturarlo antes,
            // pero aquí está bien si validamos el contexto.
            context.read<WMSPickingBloc>().add(LoadAllNovedades(context));
            context.read<UserBloc>().add(LoadUserLocationsEvent());
            context.read<UserBloc>().add(LoadInfoDeviceEventUser());

            // esperamos 2 segundos
            await Future.delayed(const Duration(seconds: 2));

            // ✅ CORRECCIÓN CRÍTICA:
            // Verificar 'mounted' ANTES de usar el contexto o cerrar diálogos después de un await.
            if (context.mounted) {
              Navigator.pop(
                  context); // Cerrar diálogo solo si la pantalla existe
              context.read<HomeBloc>().add(AppVersionEvent());
            }
          },
          child: Scaffold(
            backgroundColor: white,
            body: Container(
              color: primaryColorApp,
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  // Background
                  RepaintBoundary(
                    child: const Background(),
                  ),

                  SizedBox(
                    width: size.width,
                    height: size.height,
                    child: SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Asegura que funcione el pull-to-refresh
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WarningWidgetCubit(),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 40, bottom: 10),
                            child: BlocBuilder<HomeBloc, HomeState>(
                                buildWhen: (previous, current) {
                              // Solo reconstruimos la tarjeta si el Home terminó de cargar
                              // o si se cargó la configuración.
                              return current is HomeLoadedState ||
                                  current is ConfigurationLoadedHomeState;
                            }, builder: (context, state) {
                              final homeBloc = context.read<HomeBloc>();

                              return Card(
                                color: const Color.fromARGB(236, 255, 255, 255),
                                elevation: 2,
                                child: Container(
                                    padding: const EdgeInsets.only(
                                        left: 10, top: 20),
                                    width: size.width,
                                    height: 150,
                                    child: Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text("Bienvenido a, ",
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color:
                                                            primaryColorApp)),
                                                // Text('WMS',
                                                Text('OnPoint',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: primaryColorApp,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10),
                                                  child: Text(
                                                      context
                                                          .read<UserBloc>()
                                                          .versionApp,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: black,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                // Cargar información del usuario
                                                context
                                                    .read<UserBloc>()
                                                    .add(LoadUserInfoEvent());

                                                showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return const DialogLoading(
                                                        message:
                                                            'Cargando información del usuario...',
                                                      );
                                                    });

                                                // // Esperar a que se carguen los datos
                                                await Future.delayed(
                                                    const Duration(seconds: 1));

                                                // // Cerrar diálogo y navegar a user
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  Navigator.pushNamed(
                                                      context, 'user');
                                                }
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(Icons.person,
                                                      color: primaryColorApp,
                                                      size: 20),
                                                  Text("Hola, ",
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          color: black)),
                                                  SizedBox(
                                                    width: size.width * 0.5,
                                                    child: Text(
                                                      homeBloc.userName,
                                                      style: TextStyle(
                                                        color: primaryColorApp,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.email,
                                                    color: primaryColorApp,
                                                    size: 18),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: size.width * 0.6,
                                                  child: Text(
                                                    homeBloc.userEmail,
                                                    style: const TextStyle(
                                                        color: black,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.storage,
                                                    color: primaryColorApp,
                                                    size: 18),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: size.width * 0.6,
                                                  child: Text(
                                                    getIt<IStorageService>()
                                                        .nameDatabase
                                                        .toString(),
                                                    style: const TextStyle(
                                                        color: black,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                )
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.security,
                                                    color: primaryColorApp,
                                                    size: 18),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: size.width * 0.4,
                                                  child: Text(
                                                    homeBloc.userRol,
                                                    style: const TextStyle(
                                                        color: black,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                //icono de verson
                                              ],
                                            ),
                                          ],
                                        ),
                                        //ICONO DE CERRAR SESION
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const CloseSession();
                                                });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                right: 20),
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                                color: white,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: Icon(Icons.logout,
                                                color: primaryColorApp),
                                          ),
                                        )
                                      ],
                                    )),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              width: size.width,
                              // height: size.height * 0.5,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          context
                                              .read<UserBloc>()
                                              .add(LoadInfoDeviceEventUser());
                                          final String rol =
                                              await PrefUtils.getUserRol();

                                          if (rol == 'picking' ||
                                              rol == 'admin') {
                                            context.read<BatchBloc>().add(
                                                LoadAllNovedadesEvent()); //
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return DialogPicking(
                                                  contextHome: context,
                                                );
                                              },
                                            );
                                          } else if (rol == '' || rol == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Cargue la configuración de su usuario"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "picking.svg",
                                          title: 'Picking',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          context
                                              .read<UserBloc>()
                                              .add(LoadInfoDeviceEventUser());
                                          final String rol =
                                              await PrefUtils.getUserRol();

                                          if (rol == 'packing' ||
                                              rol == 'admin') {
                                            context.read<WmsPackingBloc>().add(
                                                LoadAllNovedadesPackingEvent());

                                            context
                                                .read<PackingPedidoBloc>()
                                                .add(
                                                    LoadAllNovedadesPackEvent());
                                            context
                                                .read<PackingConsolidateBloc>()
                                                .add(
                                                    LoadAllNovedadesPackingConsolidateEvent());

                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return DialogPacking(
                                                  contextHome: context,
                                                );
                                              },
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "packing.svg",
                                          title: 'Packing',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          context
                                              .read<UserBloc>()
                                              .add(LoadInfoDeviceEventUser());
                                          final rol = context
                                              .read<HomeBloc>()
                                              .userRol; // Obtenemos el rol
                                          if (rol == 'reception' ||
                                              rol == 'admin') {
                                            {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return DialogDevoluciones(
                                                      contextHome: context,
                                                    );
                                                  });
                                            }
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "devoluciones.svg",
                                          title: 'Devoluciones',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          context
                                              .read<UserBloc>()
                                              .add(LoadInfoDeviceEventUser());
                                          final rol = context
                                              .read<HomeBloc>()
                                              .userRol; // Obtenemos el rol
                                          if (rol == 'reception' ||
                                              rol == 'admin') {
                                            //pedir ubicaciones
                                            context
                                                .read<RecepcionBloc>()
                                                .add(GetLocationsDestEvent());

                                            //pedir las novedades
                                            context.read<RecepcionBloc>().add(
                                                LoadAllNovedadesOrderEvent());

                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const DialogLoading(
                                                      message:
                                                          'Cargando recepciones...');
                                                });

                                            await Future.delayed(const Duration(
                                                seconds:
                                                    1)); // Ajusta el tiempo si es necesario

                                            Navigator.pop(context);
                                            Navigator.pushReplacementNamed(
                                              context,
                                              'list-ordenes-compra',
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          // count: count,
                                          urlImg: "recepcion.svg",
                                          title: 'Recepción',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final rol = context
                                              .read<HomeBloc>()
                                              .userRol; // Obtenemos el rol
                                          if (rol == 'transfer' ||
                                              rol == 'admin') {
                                            if (context
                                                .read<UserBloc>()
                                                .ubicaciones
                                                .isEmpty) {
                                              context.read<UserBloc>().add(
                                                  LoadUserLocationsEvent());
                                            }

                                            context.read<TransferenciaBloc>().add(
                                                LoadAllNovedadesTransferEvent());
                                            context
                                                .read<TransferenciaBloc>()
                                                .add(LoadLocations());

                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const DialogLoading(
                                                      message:
                                                          'Cargando interfaz...');
                                                });

                                            await Future.delayed(const Duration(
                                                seconds:
                                                    1)); // Ajusta el tiempo si es necesario

                                            Navigator.pop(context);

                                            Navigator.pushReplacementNamed(
                                              context,
                                              'transferencias',
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          // count: count,
                                          urlImg: "transferencia.svg",
                                          title: 'Transferencia',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final rol = context
                                              .read<HomeBloc>()
                                              .userRol; // Obtenemos el rol
                                          if (rol == 'inventory' ||
                                              rol == 'admin') {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return DialogInventario(
                                                    contextHome: context,
                                                  );
                                                });
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "inventario.svg",
                                          title: 'Inventario',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          if (context
                                                  .read<HomeBloc>()
                                                  .configurations
                                                  .result
                                                  ?.result
                                                  ?.accessProductionModule ==
                                              true) {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return DialogPickingComponentes(
                                                  contextHome: context,
                                                );
                                              },
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "pc.svg",
                                          title: 'Picking\nComponentes',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          if (context
                                                  .read<HomeBloc>()
                                                  .configurations
                                                  .result
                                                  ?.result
                                                  ?.accessProductionModule ==
                                              true) {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const DialogLoading(
                                                      message:
                                                          'Cargando entrega de productos...');
                                                });
                                            await Future.delayed(const Duration(
                                                seconds:
                                                    1)); // Ajusta el tiempo si es necesario
                                            Navigator.pop(context);
                                            Navigator.pushReplacementNamed(
                                              context,
                                              'list-entrada-productos',
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    "Su usuario no tiene permisos para acceder a este módulo"),
                                                duration: Duration(seconds: 4),
                                              ),
                                            );
                                          }
                                        },
                                        child: ImteModule(
                                          urlImg: "entrega.svg",
                                          title: 'Entrada\nProductos',
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          context
                                              .read<UserBloc>()
                                              .add(LoadInfoDeviceEventUser());
                                          //cargamos las ubicaciones
                                          context
                                              .read<InfoRapidaBloc>()
                                              .add(GetListLocationsEvent());
                                          //obtenemos los productos
                                          context
                                              .read<InfoRapidaBloc>()
                                              .add(GetProductsList());
                                          context.read<InfoRapidaBloc>().add(
                                              LoadConfigurationsUserInfo());

                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return const DialogLoading(
                                                    message:
                                                        'Cargando interfaz...');
                                              });

                                          await Future.delayed(const Duration(
                                              seconds:
                                                  1)); // Ajusta el tiempo si es necesario

                                          Navigator.pop(context);
                                          Navigator.pushReplacementNamed(
                                            context,
                                            'info-rapida',
                                          );
                                        },
                                        child: const ImteModule(
                                          urlImg: "info.svg",
                                          title: 'Info Rapida',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ),
    );
  }
}
