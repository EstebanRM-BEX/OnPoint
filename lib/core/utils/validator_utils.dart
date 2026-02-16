import 'package:flutter/material.dart';

class Validator {
  Validator();

  static String? isEmpty(String? value, BuildContext context) {
    if (value?.isEmpty ?? true) {
      return "Este campo es obligatorio";
    } else {
      return null;
    }
  }
  //meotod para validar un campo de tipo Datetime
  static String? isDate(DateTime? value, BuildContext context) {
    if (value == null) {
      return "Este campo es obligatorio";
    } else {
      return null;
    }
  }




  //validacion de email
  static String? email(String? value, BuildContext context) {
    String pattern =
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+";
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value!)) {
      return "Correo invalido";
    } else {
      return null;
    }
  }





  static String? passwordConfirm(
      String? value, String? password, BuildContext context) {
    if (value! != password) {
      return "Las contraseñas no coinciden";
    } else {
      return null;
    }
  }


  //validar pin de seguridad solo acepta numeros y minimo y maximo 6 numeros
  static String? pin(String? value, BuildContext context) {
    String pattern = r'^[0-9]{6}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value!)) {
      return "Solo acepta números y debe tener 6 dígitos";
    } else {
      return null;
    }
  }


//validacion para que la contraseña tenga al menos 8 caracteres
  static String? password(String? value, BuildContext context) {
    if (value!.length < 3) {
      return "Tener al menos 3 caracteres";
    } else {
      return null;
    }
  }

  static String? passwordRecover(String? value, BuildContext context) {
    String mayuscula = r'[A-Z]';
    String caracterEspecial = r'[^\w\d]';
    String numero = r'[0-9]';

    RegExp rMayuscula = RegExp(mayuscula);
    RegExp rCaracter = RegExp(caracterEspecial);
    RegExp rNumero = RegExp(numero);
    if (!rMayuscula.hasMatch(value!)) {
      return "Requiere una mayúscula.";
    } else if (!rCaracter.hasMatch(value)) {
      return "Requiere un carácter especial";
    } else if (!rNumero.hasMatch(value)) {
      return "Requiere un numero";
    } else if (value.length < 8) {
      return "Requiere al menos 8 caracteres";
    }
    return null;
  }


// Validar que el texto contenga algo antes de ".com"
// Validar que haya algo antes y después del punto en el dominio
static String? hasValidDomain(String? value, BuildContext context) {
  if (value == null || !value.contains('.') || value.split('.').length < 2) {
    return "La URL debe tener un formato válido";
  }

  // Verificar que haya algo antes del punto y que el último segmento tenga al menos 2 caracteres
  List<String> parts = value.split('.');
  if (parts.length < 2 || parts[0].isEmpty || parts.last.length < 2) {
    return "La URL no es válida";
  }

  return null;
}


}
