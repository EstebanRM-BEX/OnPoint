class PrefKeys {
  PrefKeys._();

  static const String user = "user";
  static const String email = "email";
  static const String rol = "rol";
  static const String userId = "userId";
  static const String pass = "pass";
  static const String isLoggedIn = "isLoggedIn";
  static const String enterprise = "enterprise";
  static const String urlWebsite = "urlWebsite";
  static const String macPDA = "macPDA";
  static const String imeiPDA = "imeiPDA";
  static const String modeloPDA = "modeloPDA";
  static const String fabricantePDA = "fabricantePDA";
  static const String cookie = "cookie";
  static const String networkOverlayVisible = "networkOverlayVisible";
  static const String appInspectorVisible = "appInspectorVisible";

  // Configuración del home por dispositivo: no se borran al cerrar sesión.
  static const String homeModulesOrder = "homeModulesOrder";
  static const String homeModulesHidden = "homeModulesHidden";
  static const String homeSummaryExpanded = "homeSummaryExpanded";

  // Catálogo de productos: sobrevive al cierre de sesión (no se borra en
  // clearPrefs). Empresa (URL + BD) dueña del catálogo guardado en SQLite.
  static const String catalogEnterprise = "catalogEnterprise";
  // `server_time` y `scope` de la última sincronización exitosa del catálogo
  // (próximos `since`/`scope` de product_quants).
  static const String catalogLastSync = "catalogLastSync";
  static const String catalogScope = "catalogScope";
}