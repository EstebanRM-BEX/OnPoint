// ignore_for_file: unrelated_type_equality_checks

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/network/network_info.dart';
import 'package:wms_app/presentation/global/blocs/network/connection_status_cubit.dart';
import 'package:wms_app/src/presentation/providers/network/cubit/warning_widget_cubit.dart';
import 'package:wms_app/src/presentation/views/conteo/screens/bloc/conteo_bloc.dart';
import 'package:wms_app/src/presentation/views/wms_picking/modules/Batchs/screens/widgets/others/dialog_loadingPorduct_widget.dart';
import 'package:wms_app/src/presentation/widgets/dynamic_SearchBar_widget.dart';
import 'package:get/get.dart';

class SearchLocationConteoScreen extends StatefulWidget {
  const SearchLocationConteoScreen({super.key});

  @override
  State<SearchLocationConteoScreen> createState() =>
      _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationConteoScreen> {
  int? selectedIndex;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _locationListScrollController = ScrollController();
  Timer? _debounce;
  bool _isLoadingDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.animation?.isCompleted ?? true) {
        _onRouteReady();
      } else {
        route!.animation!.addStatusListener(_onRouteAnimationStatus);
      }
    });
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      ModalRoute.of(context)
          ?.animation
          ?.removeStatusListener(_onRouteAnimationStatus);
      _onRouteReady();
    }
  }

  void _onRouteReady() {
    if (!mounted) return;
    final bloc = context.read<ConteoBloc>();
    final needsLoad = (bloc.ordenConteo.filterType == 'category' ||
            bloc.ordenConteo.filterType == 'product') &&
        bloc.ubicaciones.isEmpty;
    if (needsLoad) {
      _showLoadingDialog();
    } else {
      _searchFocusNode.requestFocus();
    }
  }

  void _showLoadingDialog() {
    if (_isLoadingDialogShowing || !mounted) return;
    _isLoadingDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: DialogLoading(message: "Cargando ubicaciones..."),
      ),
    ).then((_) => _isLoadingDialogShowing = false);
  }

  void _closeLoadingDialog() {
    if (!_isLoadingDialogShowing || !mounted) return;
    _isLoadingDialogShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _locationListScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bloc = context.read<ConteoBloc>();

    return BlocListener<ConteoBloc, ConteoState>(
      listenWhen: (prev, curr) =>
          curr is LoadLocationsLoading ||
          curr is LoadLocationsSuccess ||
          curr is LoadLocationsFailure,
      listener: (context, state) {
        if (state is LoadLocationsLoading) {
          _showLoadingDialog();
        } else if (state is LoadLocationsSuccess) {
          _closeLoadingDialog();
          bloc.add(SearchLocationEvent(''));
          _searchFocusNode.requestFocus();
        } else if (state is LoadLocationsFailure) {
          _closeLoadingDialog();
          Get.snackbar(
            '360 Software Informa',
            state.error,
            backgroundColor: Colors.white,
            colorText: Colors.red[800],
            icon: const Icon(Icons.error_outline, color: Colors.red),
            duration: const Duration(seconds: 3),
          );
        }
      },
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
        backgroundColor: primaryColorApp,
        body: SafeArea(
          child: Container(
            color: Colors.white,
            width: size.width,
            height: size.height,
            child: Column(
              children: [
                _AppBarInfo(size: size),
                _buildSearchBar(context, bloc, size),
                Expanded(
                  child: BlocBuilder<ConteoBloc, ConteoState>(
                    buildWhen: (prev, curr) =>
                        curr is SearchLocationSuccess ||
                        curr is SearchLoading ||
                        curr is SearchFailure ||
                        curr is LoadNewProductSuccess ||
                        curr is LoadLocationsSuccess,
                    builder: (context, state) {
                      return _buildLocationList(context, bloc, size);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (selectedIndex != null) _buildSelectButton(bloc, size),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildSearchBar(BuildContext context, ConteoBloc bloc, Size size) {
    return DynamicSearchBar(
      controller: bloc.searchControllerLocation,
      focusNode: _searchFocusNode,
      hintText: "Buscar ubicación",
      onSearchChanged: (value) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          bloc.add(SearchLocationEvent(value));
        });
      },
      onSearchCleared: () {
        // DynamicSearchBar ya llama controller.clear() antes de este callback
        bloc.add(SearchLocationEvent(''));
        _searchFocusNode.requestFocus();
      },
      onTap: () {},
    );
  }

  Widget _buildLocationList(
      BuildContext context, ConteoBloc bloc, Size size) {
    final ubicaciones = bloc.ubicacionesFiltersSearch;

    if (ubicaciones.isEmpty) {
      return const Center(
        child: Text('No se encontraron ubicaciones',
            style: TextStyle(fontSize: 14, color: grey)),
      );
    }

    return Scrollbar(
      controller: _locationListScrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _locationListScrollController,
        itemCount: ubicaciones.length,
        itemBuilder: (context, index) {
        final ubicacion = ubicaciones[index];
        final isSelected = selectedIndex == index;
        final barcode = ubicacion.barcode;
        final barcodeEmpty = barcode == false ||
            barcode == null ||
            barcode.toString().isEmpty;

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: GestureDetector(
            onTap: () => setState(
                () => selectedIndex = isSelected ? null : index),
            child: Card(
              elevation: 1,
              color: isSelected ? Colors.green[100] : white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Nombre: ',
                            style:
                                TextStyle(color: black, fontSize: 12)),
                        Text(
                          ubicacion.name ?? '',
                          style: const TextStyle(
                              color: primaryColorApp, fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Barcode: ',
                            style:
                                TextStyle(color: black, fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          barcodeEmpty
                              ? 'Sin barcode'
                              : barcode.toString(),
                          style: TextStyle(
                            color:
                                barcodeEmpty ? red : primaryColorApp,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildSelectButton(ConteoBloc bloc, Size size) {
    return ElevatedButton(
      onPressed: () {
        if (selectedIndex == null) return;
        final selectedLocation =
            bloc.ubicacionesFiltersSearch[selectedIndex!];

        bloc.add(ValidateFieldsEvent(field: "location", isOk: true));
        bloc.add(ChangeLocationIsOkEvent(true, selectedLocation, 0, 0, 0));

        FocusScope.of(context).unfocus();
        setState(() => selectedIndex = null);

        Navigator.pushReplacementNamed(context, 'new-product-conteo');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColorApp,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: Size(size.width * 0.9, 40),
      ),
      child: const Text("Seleccionar", style: TextStyle(color: white)),
    );
  }
}

class _AppBarInfo extends StatelessWidget {
  const _AppBarInfo({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, connectionStatus) {
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
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, 'new-product-conteo'),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: size.width * 0.2),
                    child: const Text('UBICACIONES',
                        style: TextStyle(color: white, fontSize: 18)),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
