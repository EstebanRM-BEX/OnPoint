# Descripción

<!-- Qué cambia y por qué -->

## Checklist de memoria y ciclo de vida

- [ ] Todo `TextEditingController` / `FocusNode` / `ScrollController` nuevo está en el getter `disposables` del `DisposableControllersMixin` (o tiene su `.dispose()` en pantallas no migradas)
- [ ] Todo `.listen()` guarda la `StreamSubscription` y la cancela en `dispose()` / `close()`
- [ ] Todo `Timer` / `Timer.periodic` tiene su `.cancel()` en `dispose()`
- [ ] Todo `addObserver(this)` tiene su `removeObserver(this)` simétrico
- [ ] Los callbacks async que usan `context` / `setState` verifican `mounted` antes
- [ ] Si es una pantalla de pick: el cambio se aplicó en **ambas** versiones gemelas (`src/` y `features/picking/`)

## Checklist general

- [ ] `flutter analyze` sin errores nuevos
- [ ] `flutter test` en verde (leak_tracker activo detecta controllers sin dispose)
- [ ] Probado en dispositivo Zebra si toca pantallas de escaneo
