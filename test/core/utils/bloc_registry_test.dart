import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms_app/core/utils/diagnostics/bloc_registry.dart';

class _CubitA extends Cubit<int> {
  _CubitA() : super(0);
}

class _CubitB extends Cubit<int> {
  _CubitB() : super(0);
}

List<BlocInfo> _of(String name) =>
    AppBlocObserver.instance.all.where((i) => i.name == name).toList();

void main() {
  setUpAll(() => Bloc.observer = AppBlocObserver.instance);

  test(
    'un tipo cerrado varias veces aparece una sola vez como cerrado',
    () async {
      final a1 = _CubitA();
      await a1.close();
      final a2 = _CubitA();
      await a2.close();

      final infos = _of('_CubitA');
      expect(infos, hasLength(1));
      expect(infos.single.isClosed, isTrue);
    },
  );

  test(
    'si hay una instancia viva no se muestran las cerradas del mismo tipo',
    () async {
      final b1 = _CubitB();
      await b1.close();
      final b2 = _CubitB();

      final infos = _of('_CubitB');
      expect(infos, hasLength(1));
      expect(infos.single.isClosed, isFalse);

      await b2.close();
      expect(_of('_CubitB').single.isClosed, isTrue);
    },
  );

  test('dos instancias vivas del mismo tipo se muestran las dos', () async {
    final c1 = _CubitB();
    final c2 = _CubitB();

    expect(_of('_CubitB').where((i) => !i.isClosed), hasLength(2));

    await c1.close();
    await c2.close();
  });
}
