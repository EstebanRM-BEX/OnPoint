


import 'package:intl/intl.dart';

//formato de fecha para enviar al servidor
String formatoFecha(DateTime fecha) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(fecha);
}