import 'package:sqflite/sqflite.dart';

/// SQLite limita las variables `?` por consulta (999 en versiones antiguas de
/// Android). Una cláusula `IN (?,?,...)` con miles de ids lanza
/// "too many SQL variables"; estas ayudas la parten en tandas.
const kSqlVariableChunk = 500;

Iterable<List<T>> sqlChunks<T>(
  List<T> values, {
  int size = kSqlVariableChunk,
}) sync* {
  for (var i = 0; i < values.length; i += size) {
    yield values.sublist(
      i,
      i + size > values.length ? values.length : i + size,
    );
  }
}

/// `SELECT [columns] FROM table WHERE inColumn IN (values)` sin pasar del
/// límite de variables: consulta por tandas y junta las filas.
Future<List<Map<String, Object?>>> queryWhereIn(
  DatabaseExecutor db,
  String table, {
  required String inColumn,
  required List<Object?> values,
  List<String>? columns,
}) async {
  final rows = <Map<String, Object?>>[];
  for (final chunk in sqlChunks(values)) {
    rows.addAll(
      await db.query(
        table,
        columns: columns,
        where: '$inColumn IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      ),
    );
  }
  return rows;
}
