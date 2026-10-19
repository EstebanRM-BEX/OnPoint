# Pruebas en PDA — rama `fix/oom-catalogo-productos`

> Worktree `/Volumes/Baneste/appwms-fix-oom` · BD v71 · 2026-10-13
> Usar el cliente grande (~72 mil productos, ~322 mil terceros, ~19 mil ubicaciones).

## 0. Antes de instalar

- [✅] Verificar que la firma del APK coincida con la instalada (si no, `flutter run` desinstala y **borra los datos**).
- [✅] PDAs: Urovo DT50 (heap 128 MB) y Chainway / CT58.
- [ ] Instalar sobre una versión anterior (no limpia): la migración a v71 debe correr sin errores.
- [ ] Sincronizar productos, ubicaciones y terceros completos.

## 1. Arranque y sesión

- [✅] Login → home sin pausas largas ni diálogo de "cargando catálogos".
- [✅] El contador de ubicaciones del home muestra el total correcto.
- [✅] Descargar ubicaciones desde el perfil (normal y completa): mensaje "Se descargaron N ubicaciones".
- [✅] Cerrar sesión y entrar con otra empresa/almacén: no aparecen ubicaciones ni productos de la sesión anterior.
- [ ] "Eliminar base de datos" del perfil → volver a sincronizar → todo funciona.

## 2. Productos (OOM)

En cada pantalla: buscar por texto, bajar hasta cargar más, escanear (mayúsculas y minúsculas), producto inexistente.

- [✅] **Conteo**: entrar desde home, "nuevo producto", buscar, escanear. Lote preseleccionado correcto.
- [✅] **Crear transferencia**: búsqueda de productos; al seleccionar un producto no se congela.
- [✅] **Devoluciones**: escanear producto, buscar producto.
- [✅] **Inventario rápido**: buscar y escanear producto.
- [✅] **Impresión de etiquetas**: listado de productos paginado.
- [✅] **Info Rápida**: búsqueda manual de productos.

## 3. Ubicaciones

En cada pantalla: buscar por nombre y barcode, bajar (carga la siguiente página), filtrar por almacén, escanear ubicación (mayúsculas/minúsculas), código inexistente → mensaje de error. Escribir rápido no debe trabarse.

- [✅] **Recepción individual** (legacy): ubicación destino.
- [✅] **Recepción batch** (legacy): ubicación destino. Se entra por **Devoluciones → Por Batch** (no está en el diálogo de Recepción).
- [✅] **Recepción multiusuario**: destino filtrado por almacén.
- [✅] **Transferencia interna**: origen y destino.
- [✅] **Crear transferencia**: origen y destino.
- [✅] **Transferencia multiusuario**: destino filtrado por almacén.
- [✅] **Conteo**: filtros `category`, `product` y `general` (este último solo ubicaciones del almacén); `location`/`combined` siguen mostrando las de la orden.
- [✅] **Devoluciones**: ubicación destino (buscar y escanear).
- [✅] **Inventario rápido**: buscar, filtrar por almacén y escanear ubicación.
- [] **Impresión de etiquetas**: búsqueda; rango por prefijo y desde–hasta (rango muy amplio → aviso de tope).
- [ ] **Packing v2**: lista de muelles.
- [ ] **Info Rápida**:
  - [ ] Lista de ubicaciones: buscar, filtro por almacén, bajar.
  - [ ] Transferencia individual: elegir destino de la lista y escaneando; destino = origen → error.
  - [ ] Transferencia masiva: igual que la individual.
  - [ ] Editar una ubicación y volver: se ve el cambio.
- [ ] Cambio de ubicaciones desde Odoo (sync incremental / WebSocket): aparece en las búsquedas sin reiniciar.

## 4. Devoluciones — terceros

- [✅] Abrir crear devolución: sin diálogo largo de "cargando terceros".
- [✅] Buscar tercero (con y sin coincidencias), bajar para cargar más.
- [ ] Salir y volver a entrar: no reinicializa todo de nuevo.

## 5. Memoria y estabilidad

- [ ] Turno largo (~2 h) alternando Conteo → Transferencia → Devoluciones → Recepción: la RSS no crece de forma sostenida (`adb shell dumpsys meminfo <paquete>`).
- [ ] DT50: ninguna pantalla cierra la app.
- [ ] Cerrar la app a propósito (botón atrás / matar desde recientes): al reabrir **no** se reporta "Cierre en primer plano" en Crashlytics.

## 6. Después de publicar (Firebase)

- [ ] Crashlytics, 7 días: OOM `bcf7e387…` = 0; "Cierre en primer plano" solo con motivo real.
- [ ] Performance, 7 días: trazas `search_location_*` con frames lentos < 10 %.
