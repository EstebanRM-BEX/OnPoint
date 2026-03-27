# 🚀 Guía de Optimización para Cargas Masivas (WMS)

Esta guía detalla los 3 pilares arquitectónicos implementados en el módulo de Inventario para sincronizar más de 60,000 registros en tiempo récord.

---

## 1. Isolate-Driven Parsing (Repositorio)
**Problema:** `jsonDecode` y `.fromMap` en listas largas (>5,000 items) bloquean el hilo principal de Flutter, causando "lags" y lentitud percibida.

**Solución:** Mover todo el procesamiento de red a un hilo secundario (`compute`).

```dart
// En el Repositorio de Datos:
static Map<String, dynamic> _parseDataIsolate(String body) {
  final Map<String, dynamic> json = jsonDecode(body);
  final List<dynamic> raw = json['result']['data'];
  // Mapeamos todo en el hilo secundario
  final List<Model> items = raw.map((x) => Model.fromMap(x)).toList();
  return {'items': items};
}

Future<List<Model>> fetchData() async {
  final response = await api.get('endpoint');
  // UN SOLO viaje al isolate para decodificar Y mapear
  final result = await compute(_parseDataIsolate, response.body);
  return result['items'];
}
```

---

## 2. Raw SQL Multi-Values (Base de Datos)
**Problema:** `batch.insert(Map)` es extremadamente lento en volúmenes altos porque Flutter debe serializar miles de `Maps` y Android debe convertirlos en `ContentValues`.

**Solución:** Escribir el SQL manualmente con múltiples valores para reducir las llamadas al "Method Channel".

```dart
// En el Repository de BD:
Future<void> insertMassive(List<Model> list) async {
  await db.transaction((txn) async {
    const int chunk = 40; // Máximo seguro para no exceder 999 parámetros
    final Batch batch = txn.batch();

    for (var i = 0; i < list.length; i += chunk) {
      final sublist = list.sublist(i, Math.min(i + chunk, list.length));
      
      final buffer = StringBuffer();
      buffer.write('INSERT INTO table (col1, col2) VALUES ');
      
      final List<dynamic> args = [];
      for (var j = 0; j < sublist.length; j++) {
        if (j > 0) buffer.write(', ');
        buffer.write('(?,?,?)');
        args.addAll([sublist[j].val1, sublist[j].val2]);
      }
      // Una sola instrucción para 'chunk' elementos
      batch.rawInsert(buffer.toString(), args);
    }
    await batch.commit(noResult: true);
  });
}
```

---

## 3. Immediate State Update (BLoC)
**Problema:** Hacer un `getAllFromDB()` justo después de insertar miles de filas es un desperdicio de CPU y tiempo.

**Solución:** Usar los datos que ya están en memoria (los que devolvió la API) para actualizar el estado del BLoC y las listas locales de inmediato.

*   **Paso 1:** `await db.deleteData();`
*   **Paso 2:** `final data = await repo.fetch();`
*   **Paso 3:** `await db.insertMassive(data);`
*   **Paso 4:** `state.items = List.from(data); // Sin volver a leer de DB`

---
> [!IMPORTANT]
> **Regla de Oro**: Si la carga es masiva, la tabla siempre debe limpiarse antes (`DELETE FROM table`) para evitar usar `ConflictAlgorithm.replace`, el cual es 5x más lento que un `INSERT` puro.
