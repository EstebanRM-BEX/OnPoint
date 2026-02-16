// ignore_for_file: unused_field

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wms_app/core/constants/colors.dart';
import 'package:wms_app/core/utils/prefs/pref_utils.dart';
import 'package:wms_app/src/presentation/views/wms_packing/presentation/print/models/mode_print_model.dart';
import 'dart:ui' as ui;


class PrintDialog extends StatefulWidget {
  const PrintDialog({super.key, required this.model});

  final PrintModel model;

  @override
  State<PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<PrintDialog> {
  String _info = "";
  String _msj =
      'Activa el bluetooth o concede el permiso de dispsotivos cercanos para buscar impresoras';
  bool connected = false;
  List<BluetoothInfo> items = [];

  bool _progress = false;
  String _msjprogress = "";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _msj,
              style: TextStyle(color: black),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      getBluetoots();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Visibility(
                          visible: _progress,
                          child: const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 1, backgroundColor: primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _progress ? _msjprogress : "Buscar",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                      onPressed: connected ? disconnect : null,
                      style: ElevatedButton.styleFrom(
                        maximumSize: const Size(100, 50),
                        backgroundColor: grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(
                        Icons.print_disabled,
                        color: Colors.white,
                        size: 30,
                      )),
                ],
              ),
            ),
            Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: Colors.grey.withAlpha(50),
                ),
                child: ListView.builder(
                  itemCount: items.isNotEmpty ? items.length : 0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        String mac = items[index].macAdress;
                        connect(mac);
                      },
                      title: Text('Nombre: ${items[index].name}'),
                      subtitle:
                          Text("Dirección MAC: ${items[index].macAdress}"),
                    );
                  },
                )),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: connected ? printTest : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColorApp,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Imprimir',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }




  Future<void> initPlatformState() async {
    String platformVersion;
    int porcentbatery = 0;
    try {
      platformVersion = await PrintBluetoothThermal.platformVersion;
      porcentbatery = await PrintBluetoothThermal.batteryLevel;
    } catch (e) {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;
    final bool result = await PrintBluetoothThermal.bluetoothEnabled;
    print("Bluetooth activado: $result");
    if (result) {
      _msj = "Bluetooth activado, por favor busca y conecta";
    } else {
      _msj = "Bluetooth no activado";
    }
    setState(() {
      _info = "$platformVersion ($porcentbatery% batería)";
    });
  }





  Future<void> getBluetoots() async {
    setState(() {
      _progress = true;
      _msjprogress = "Espera";
      items = [];
    });
    final List<BluetoothInfo> listResult =
        await PrintBluetoothThermal.pairedBluetooths;

    setState(() {
      _progress = false;
    });

    if (listResult.isEmpty) {
      _msj =
          "No hay dispositivos vinculados, ve a ajustes y vincula la impresora";
    } else {
      _msj = "Toca un elemento de la lista para conectar";
    }

    setState(() {
      items = listResult;
    });
  }

  Future<void> connect(String mac) async {
    setState(() {
      _progress = true;
      _msjprogress = "Conectando...";
      connected = false;
    });
    final bool result =
        await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    print("Estado conectado $result");
    if (result) connected = true;
    setState(() {
      _progress = false;
    });
  }

  Future<void> disconnect() async {
    final bool status = await PrintBluetoothThermal.disconnect;
    setState(() {
      connected = false;
    });
    print("Estado desconectado $status");
  }

  Future<void> printTest() async {
    bool conexionStatus = await PrintBluetoothThermal.connectionStatus;
    if (conexionStatus) {
      bool result = false;
      List<int> ticket = await testTicket();
      result = await PrintBluetoothThermal.writeBytes(ticket);
      print("Resultado de la prueba de impresión:  $result");
    } else {
      print("Estado de conexión de la prueba de impresión: $conexionStatus");
      setState(() {
        disconnect();
      });
    }
  }

  Future<List<int>> testTicket() async {
    List<int> bytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58,
        profile); 
        
        // Ajusta el tamaño del papel según sea necesario

    bytes += generator.reset();
    // Texto

    bytes += generator.text("""^XA
        ^FX Top section with logo, name and address.
        ^CF0,60
        ^FO50,50^GB100,100,100^FS
        ^FO75,75^FR^GB100,100,100^FS
        ^FO93,93^GB40,40,40^FS
        ^FO220,50^FDIntershipping, Inc.^FS
        ^CF0,30
        ^FO220,115^FD1000 Hola nevado ^FS
        ^FO220,155^FDShelbyville TN 38102^FS
        ^FO220,195^FDUnited States (USA)^FS
        ^FO50,250^GB700,3,3^FS
        ^XZ""",
        styles: const PosStyles(align: PosAlign.center, bold: true));



        
    // bytes += generator.text('Batch: ${widget.model.batchName}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Zona TMS: ${widget.model.zonaEntregaTms}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Operacion: ${widget.model.pickingTypeId}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Pedido: ${widget.model.namePedido}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Referencia: ${widget.model.referencia}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Contacto: ${widget.model.contactoName}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text('Empaque: ${widget.model.namePaquete}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes += generator.text(
    //     'Cant productos empaque: ${widget.model.cantProductoPack}',
    //     styles: const PosStyles(align: PosAlign.center));
    // bytes +=
    //     generator.text('', styles: const PosStyles(align: PosAlign.center));
    
    

    // Generar el código QR como Uint8List
    final Uint8List qrUint8List = await _generateQrUint8List();

    // Convertir Uint8List a una imagen manipulable
    final img.Image? qrImage = img.decodeImage(qrUint8List);

    // Agregar la imagen del código QR a los bytes de impresión
    if (qrImage != null) {
      // Asegúrate de que la imagen esté centrada
      bytes += generator.image(qrImage, align: PosAlign.center);
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }







  Future<Uint8List> _generateQrUint8List() async {
    // Definir el tamaño del código QR (ajusta según el ancho del papel)
    const qrSize = 200.0; // Tamaño en píxeles

    // Crear un PictureRecorder para capturar la imagen
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    var url = await PrefUtils.getEnterprise();

    url = '$url/package/info/${widget.model.namePaquete}';

    // Generar el código QR
    final qrPainter = QrPainter(
      data: url,

      version: QrVersions.auto,
      color: Colors.black,
      emptyColor: Colors.white,
    );

    // Pintar el código QR en el canvas
    qrPainter.paint(canvas, const Size(qrSize, qrSize));

    // Convertir el PictureRecorder en una imagen
    final picture = recorder.endRecording();
    final image = await picture.toImage(qrSize.toInt(), qrSize.toInt());

    // Convertir la imagen en bytes (Uint8List)
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    return pngBytes;
  }
}
