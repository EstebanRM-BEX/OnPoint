// import 'package:flutter/foundation.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Future<void> main() async {
//   sqfliteFfiInit();
//   databaseFactory = databaseFactoryFfi;

//   final db = await openDatabase(inMemoryDatabasePath, version: 1,
//       onCreate: (db, version) async {
//     await db.execute('''
//       CREATE TABLE tblproductos_inventario (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         code TEXT, product_id INTEGER, name TEXT, barcode TEXT, tracking TEXT,
//         lot_id INTEGER, lot_name TEXT, expiration_date TEXT, weight REAL,
//         weight_uom_name TEXT, volume REAL, volume_uom_name TEXT, uom TEXT,
//         location_id INTEGER, location_name TEXT, quantity REAL,
//         use_expiration_date INTEGER, category TEXT, is_synced INTEGER
//       )
//     ''');
//   });

//   // Generate 62000 maps
//   final List<Map<String, dynamic>> maps = [];
//   for (int i = 0; i < 62141; i++) {
//     maps.add({
//       'code': 'CODE$i', 'product_id': i, 'name': 'Product $i',
//       'barcode': '123456789', 'tracking': 'none', 'lot_id': 0,
//       'lot_name': '', 'expiration_date': '', 'weight': 1.5,
//       'weight_uom_name': 'kg', 'volume': 2.0, 'volume_uom_name': 'L',
//       'uom': 'PZ', 'location_id': 1, 'location_name': 'Loc A',
//       'quantity': 100.0, 'use_expiration_date': 0, 'category': 'Cat',
//       'is_synced': 1
//     });
//   }

//   print('Testing Batch Insert (All at once inside Transaction)...');
//   final s1 = Stopwatch()..start();
//   await db.transaction((txn) async {
//     final batch = txn.batch();
//     for (var m in maps) batch.insert('tblproductos_inventario', m);
//     await batch.commit(noResult: true);
//   });
//   s1.stop();
//   print('All at once took: ${s1.elapsedMilliseconds} ms');

//   await db.delete('tblproductos_inventario');

//   print('Testing Batch Insert (Chunked 2000 inside Transaction)...');
//   final s2 = Stopwatch()..start();
//   await db.transaction((txn) async {
//     var batch = txn.batch();
//     int count = 0;
//     for (var m in maps) {
//       batch.insert('tblproductos_inventario', m);
//       count++;
//       if (count % 2000 == 0) {
//         await batch.commit(noResult: true);
//         batch = txn.batch();
//       }
//     }
//     if (count % 2000 != 0) await batch.commit(noResult: true);
//   });
//   s2.stop();
//   print('Chunked 2000 took: ${s2.elapsedMilliseconds} ms');

//   await db.delete('tblproductos_inventario');

//   print('Testing Original Raw Insert of 40 (Chunked 40 inside Transaction)...');
//   final s3 = Stopwatch()..start();
//   await db.transaction((txn) async {
//     var batch = txn.batch();
//     const int chunkS = 40;
//     for(int i = 0; i < maps.length; i += chunkS) {
//       int end = (i + chunkS < maps.length) ? i + chunkS : maps.length;
//       var sublist = maps.sublist(i, end);
//       StringBuffer buf = StringBuffer('INSERT INTO tblproductos_inventario (code, product_id, name, barcode, tracking, lot_id, lot_name, expiration_date, weight, weight_uom_name, volume, volume_uom_name, uom, location_id, location_name, quantity, use_expiration_date, category, is_synced) VALUES ');
//       List<dynamic> args = [];
//       for(int j = 0; j < sublist.length; j++) {
//         if(j > 0) buf.write(',');
//         buf.write('(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
//         args.addAll(sublist[j].values.where((v) => v != null).toList());
//       }
//       batch.rawInsert(buf.toString(), args);
//     }
//     await batch.commit(noResult: true);
//   });
//   s3.stop();
//   print('Raw 40 took: ${s3.elapsedMilliseconds} ms');

// }
