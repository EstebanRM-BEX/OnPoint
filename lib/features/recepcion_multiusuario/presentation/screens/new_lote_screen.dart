import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_holo_date_picker/date_picker.dart';
import 'package:flutter_holo_date_picker/i18n/date_picker_i18n.dart';
import 'package:intl/intl.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/lote_producto.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_claim.dart';
import 'package:wms_app/features/recepcion_multiusuario/domain/entities/recepcion_session.dart';
import 'package:wms_app/features/recepcion_multiusuario/presentation/bloc/lote/recepcion_multiusuario_lote_bloc.dart';
import 'package:wms_app/shared/utils/keyboard_watchdog.dart';
import 'package:wms_app/shared/widgets/loading_dialog_mixin.dart';
import 'package:wms_app/src/presentation/providers/db/database.dart';
import 'package:wms_app/src/presentation/widgets/dialog_error_widget.dart';
import 'package:wms_app/src/presentation/widgets/expiration_badge_widget.dart';

/// Réplica de NewLoteScreen (recepción individual) para multiusuario: listar
/// lotes existentes del producto o crear uno nuevo. Los lotes son un dato de
/// producto, no de sesión — reusa los mismos endpoints (GET
/// /api/lotes/{productId}, POST /api/create_lote) vía
/// RecepcionMultiusuarioLoteBloc.
///
/// A diferencia del original, al seleccionar/crear un lote esta pantalla
/// hace `Navigator.pop(context, lote)` en vez de ida y vuelta por rutas —
/// scan_product_screen.dart espera el resultado con `Navigator.push`.
class RecepcionMultiusuarioNewLoteScreen extends StatefulWidget {
  const RecepcionMultiusuarioNewLoteScreen({
    super.key,
    required this.session,
    required this.claim,
  });

  final RecepcionSession session;
  final RecepcionClaim claim;

  @override
  State<RecepcionMultiusuarioNewLoteScreen> createState() =>
      _RecepcionMultiusuarioNewLoteScreenState();
}

class _RecepcionMultiusuarioNewLoteScreenState
    extends State<RecepcionMultiusuarioNewLoteScreen>
    with WidgetsBindingObserver, LoadingDialogMixin {
  bool _viewList = true;
  DateTime? _selectedDate;
  int? _selectedIndex;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nombreLoteController = TextEditingController();
  final TextEditingController _dateLoteController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _nombreLoteFocusNode = FocusNode();

  // Watchdog: reabre el teclado si el IME del PDA (Zebra/Urovo/Chainway) lo
  // cierra solo mientras alguno de estos campos conserva el foco.
  late final KeyboardWatchdog _kbWatchdogSearch = KeyboardWatchdog(
    state: this,
    focusNode: _searchFocusNode,
  );
  late final KeyboardWatchdog _kbWatchdogNombreLote = KeyboardWatchdog(
    state: this,
    focusNode: _nombreLoteFocusNode,
  );

  // null mientras carga: el permiso vive en tbl_configurations, no queremos
  // leerlo como "false" por falta de datos antes de que cargue.
  bool? _manageExpirationDateWithoutLot;
  bool _allowPriorExpirationDate = false;

  int? get _productId => widget.claim.productId;
  bool get _useExpirationDate => widget.claim.useExpirationDate == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final productId = _productId;
    if (productId != null) {
      context.read<RecepcionMultiusuarioLoteBloc>().add(
        FetchLotesEvent(productId),
      );
    }
    _cargarPermisos();
  }

  @override
  void didChangeMetrics() {
    _kbWatchdogSearch.onMetricsChanged();
    _kbWatchdogNombreLote.onMetricsChanged();
  }

  Future<void> _cargarPermisos() async {
    final userId = await PrefUtils.getUserId();
    final config = await DataBaseSqlite().configurationsRepository
        .getConfiguration(userId);
    if (!mounted) return;
    setState(() {
      _manageExpirationDateWithoutLot =
          config?.result?.result?.manageExpirationDateWithoutLot == true;
      _allowPriorExpirationDate =
          config?.result?.result?.allowPriorExpirationDate == true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _kbWatchdogSearch.dispose();
    _kbWatchdogNombreLote.dispose();
    _searchController.dispose();
    _nombreLoteController.dispose();
    _dateLoteController.dispose();
    _searchFocusNode.dispose();
    _nombreLoteFocusNode.dispose();
    super.dispose();
  }

  void _submitCreateLote({bool priorityExpiration = false}) {
    final productId = _productId;
    if (productId == null) return;

    // Nombre ya existente en la lista cargada.
    final state = context.read<RecepcionMultiusuarioLoteBloc>().state;
    final lotesCargados = state is RecepcionLotesLoaded
        ? state.lotes
        : const [];
    if (lotesCargados.any((l) => l.name == _nombreLoteController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El lote ya existe, ingrese otro nombre')),
      );
      return;
    }

    if (_useExpirationDate && _dateLoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha de caducidad no puede estar vacía para este producto',
          ),
        ),
      );
      return;
    }

    if (_manageExpirationDateWithoutLot == true) {
      // Nombre autogenerado a partir de la fecha, sin separadores.
      _nombreLoteController.text = DateFormat(
        'ddMMyyyyHHmmss',
      ).format(_selectedDate ?? DateTime.now());
    } else if (_nombreLoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del lote no puede estar vacío'),
        ),
      );
      return;
    }

    if (_selectedDate != null) {
      final now = DateTime.now();
      final selectedDateOnly = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final nowDateOnly = DateTime(now.year, now.month, now.day);
      if (!selectedDateOnly.isAfter(nowDateOnly) && !priorityExpiration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La fecha de caducidad debe ser mayor a la fecha actual',
            ),
          ),
        );
        return;
      }
    }

    context.read<RecepcionMultiusuarioLoteBloc>().add(
      CreateLoteEvent(
        productId: productId,
        nombreLote: _nombreLoteController.text,
        fechaVencimiento: _dateLoteController.text,
        priorityExpiration: priorityExpiration,
      ),
    );
  }

  void _handleCrearLoteTap() {
    // Atajo: si el producto no maneja fecha de vencimiento y el permiso de
    // lote sin nombre está activo, se crea directo con la fecha actual como
    // nombre, sin mostrar el formulario.
    if (!_useExpirationDate && _manageExpirationDateWithoutLot == true) {
      _nombreLoteController.text = DateFormat(
        'ddMMyyyyHHmmss',
      ).format(DateTime.now());
      context.read<RecepcionMultiusuarioLoteBloc>().add(
        CreateLoteEvent(
          productId: _productId ?? 0,
          nombreLote: _nombreLoteController.text,
          fechaVencimiento: '',
        ),
      );
    }
    setState(() => _viewList = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<
      RecepcionMultiusuarioLoteBloc,
      RecepcionMultiusuarioLoteState
    >(
      listener: (context, state) {
        if (state is CreateLoteLoading) {
          showLoadingDialog('Creando lote...');
        } else if (state is RecepcionMultiusuarioLoteLoading) {
          showLoadingDialog('Cargando lotes...');
        } else {
          hideLoadingDialog();
        }
        if (state is CreateLoteSuccess) {
          Navigator.pop(context, state.lote);
        }
        if (state is CreateLoteNeedsConfirmation) {
          if (!_allowPriorExpirationDate) {
            // Sin permiso para forzarla: mismo tratamiento que un error duro.
            showScrollableErrorDialog(state.message);
          } else {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Fecha de vencimiento anterior a hoy'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _submitCreateLote(priorityExpiration: true);
                    },
                    child: const Text('Continuar de todas formas'),
                  ),
                ],
              ),
            );
          }
        }
        if (state is CreateLoteError) {
          showScrollableErrorDialog(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: primaryColorApp,
        appBar: AppBar(
          backgroundColor: primaryColorApp,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'CREAR LOTE',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: SafeArea(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.claim.productName ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: black),
                  ),
                ),
                if (_viewList)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Card(
                      color: white,
                      elevation: 3,
                      child: TextFormField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(color: black, fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: grey,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              FocusScope.of(context).unfocus();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: grey,
                              size: 20,
                            ),
                          ),
                          hintText: 'Buscar lote',
                          hintStyle: TextStyle(color: grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _viewList ? _buildLotesList() : _buildCreateForm(),
                ),
                if (_selectedIndex != null && _viewList)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        final state = context
                            .read<RecepcionMultiusuarioLoteBloc>()
                            .state;
                        if (state is! RecepcionLotesLoaded) return;
                        final lotes = _filteredLotes(state.lotes);
                        if (_selectedIndex! >= lotes.length) return;
                        Navigator.pop(context, lotes[_selectedIndex!]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColorApp,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Seleccionar lote',
                        style: TextStyle(color: white),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_viewList) {
                              Navigator.pop(context);
                            } else {
                              setState(() => _viewList = true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (_viewList)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleCrearLoteTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'CREAR LOTE',
                              style: TextStyle(color: white),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitCreateLote(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColorApp,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'AGREGAR LOTE',
                              style: TextStyle(color: white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<LoteProducto> _filteredLotes(List<LoteProducto> lotes) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return lotes;
    return lotes
        .where((l) => (l.name ?? '').toLowerCase().contains(query))
        .toList();
  }

  Widget _buildLotesList() {
    return BlocBuilder<
      RecepcionMultiusuarioLoteBloc,
      RecepcionMultiusuarioLoteState
    >(
      builder: (context, state) {
        // El loading de la carga (RecepcionMultiusuarioLoteLoading) ya lo
        // cubre el diálogo del BlocListener — acá solo el flash inicial
        // antes de que se procese el FetchLotesEvent.
        if (state is RecepcionMultiusuarioLoteInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is RecepcionMultiusuarioLoteError) {
          return Center(
            child: Text(
              state.message,
              style: const TextStyle(color: red, fontSize: 13),
            ),
          );
        }

        final lotes = state is RecepcionLotesLoaded
            ? _filteredLotes(state.lotes)
            : const <LoteProducto>[];

        if (lotes.isEmpty) {
          return const Center(
            child: Text(
              'Este producto no tiene lotes creados',
              style: TextStyle(fontSize: 13, color: grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: lotes.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedIndex = isSelected ? null : index),
                child: Card(
                  elevation: 3,
                  color: isSelected ? Colors.green[100] : white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote: ${lotes[index].name}',
                          style: TextStyle(
                            color: primaryColorApp,
                            fontSize: 12,
                          ),
                        ),
                        ExpirationBadgeWidget(
                          expirationDate: lotes[index].expirationDate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_manageExpirationDateWithoutLot == false)
            SizedBox(
              height: 40,
              child: TextFormField(
                controller: _nombreLoteController,
                focusNode: _nombreLoteFocusNode,
                style: const TextStyle(color: black, fontSize: 14),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  _UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  labelText: 'Nombre del lote',
                  labelStyle: TextStyle(color: primaryColorApp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _nombreLoteController.clear();
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.close, color: grey),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (_useExpirationDate) ...[
            SizedBox(
              height: 40,
              child: TextFormField(
                style: const TextStyle(color: black, fontSize: 14),
                controller: _dateLoteController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      _dateLoteController.clear();
                      setState(() => _selectedDate = null);
                      FocusScope.of(context).unfocus();
                    },
                    icon: const Icon(Icons.close, color: grey),
                  ),
                  labelText: 'Fecha de caducidad',
                  labelStyle: TextStyle(color: primaryColorApp),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  final pickedDate = await DatePicker.showSimpleDatePicker(
                    context,
                    titleText: 'Seleccione una fecha',
                    confirmText: 'Seleccionar',
                    cancelText: 'Cancelar',
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 2000)),
                    dateFormat: "dd-MMMM-yyyy",
                    locale: DateTimePickerLocale.es,
                    looping: false,
                  );
                  if (pickedDate == null || !mounted) return;
                  final now = DateTime.now();
                  final normalized = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    now.hour,
                    now.minute,
                    now.second,
                  );
                  setState(() {
                    _selectedDate = normalized;
                    _dateLoteController.text = DateFormat(
                      'yyyy-MM-dd HH:mm:ss',
                    ).format(normalized);
                  });
                },
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(height: 10),
              ExpirationBadgeWidget(expirationDate: _dateLoteController.text),
            ],
          ],
        ],
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
