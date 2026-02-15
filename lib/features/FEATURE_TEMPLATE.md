# Feature Template - Clean Architecture

Este template sirve como guía para crear nuevos features o migrar features existentes a Clean Architecture.

## 📁 Estructura de Carpetas

```
lib/features/[feature_name]/
├── domain/
│   ├── entities/
│   │   └── [entity_name].dart
│   ├── repositories/
│   │   └── [feature]_repository.dart
│   └── usecases/
│       └── [action]_[entity].dart
├── data/
│   ├── models/
│   │   └── [entity]_model.dart
│   ├── datasources/
│   │   ├── [feature]_remote_data_source.dart
│   │   └── [feature]_local_data_source.dart
│   └── repositories/
│       └── [feature]_repository_impl.dart
└── presentation/
    ├── bloc/
    │   ├── [feature]_bloc.dart
    │   ├── [feature]_event.dart
    │   └── [feature]_state.dart
    ├── pages/
    │   └── [feature]_page.dart
    └── widgets/
        └── [widget_name].dart
```

---

## 🔄 Pasos de Migración

### 1. Crear Estructura de Carpetas

Crear las carpetas necesarias en `lib/features/[feature_name]/`.

### 2. Domain Layer

#### Entities

- Crear clases inmutables sin lógica de negocio
- Solo propiedades y constructores const
- No deben tener dependencias de frameworks

```dart
class Product {
  final int id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });
}
```

#### Repository Interface

- Definir contrato abstracto
- Usar `Either<Failure, Success>` para retornos
- No implementar lógica, solo firmas

```dart
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(int id);
}
```

#### Use Cases

- Un use case por operación de negocio
- Implementar `UseCase<Type, Params>`
- Agregar anotación `@lazySingleton`

```dart
@lazySingleton
class GetProducts implements UseCase<List<Product>, NoParams> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, List<Product>>> call(NoParams params) async {
    return await repository.getProducts();
  }
}
```

### 3. Data Layer

#### Models

- Extender entities del dominio
- Agregar `fromJson` y `toJson`
- Manejar serialización

```dart
class ProductModel extends Product {
  const ProductModel({
    required int id,
    required String name,
    required double price,
  }) : super(id: id, name: name, price: price);

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      ProductModel(
        id: json['id'],
        name: json['name'],
        price: json['price'].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };
}
```

#### Data Sources

- Separar remote y local
- Lanzar excepciones específicas
- Agregar anotación `@LazySingleton(as: Interface)`

```dart
@LazySingleton(as: ProductRemoteDataSource)
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;

  ProductRemoteDataSourceImpl(this.client);

  @override
  Future<List<ProductModel>> getProducts() async {
    final response = await client.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw ServerException('Error: ${response.statusCode}');
    }
  }
}
```

#### Repository Implementation

- Implementar interface del dominio
- Coordinar data sources
- Convertir excepciones a failures
- Agregar anotación `@LazySingleton(as: Interface)`

```dart
@LazySingleton(as: ProductRepository)
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('Sin conexión'));
    }

    try {
      final products = await remoteDataSource.getProducts();
      return Right(products);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
```

### 4. Presentation Layer

#### BLoC

- Inyectar use cases (no repositorios)
- Agregar anotación `@injectable`
- Manejar `Either` con `fold`

```dart
@injectable
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProducts getProducts;

  ProductBloc({required this.getProducts}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await getProducts(NoParams());

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductLoaded(products)),
    );
  }
}
```

#### States

- Crear estados específicos para cada escenario
- Incluir datos necesarios en cada estado

```dart
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}

class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}
```

### 5. Registrar en DI

Después de crear todos los archivos, ejecutar:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Usar en la UI

```dart
// En main.dart o donde se inicialice el BLoC
BlocProvider(create: (_) => getIt<ProductBloc>()),

// En la página
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) {
    if (state is ProductLoading) {
      return CircularProgressIndicator();
    } else if (state is ProductLoaded) {
      return ListView.builder(
        itemCount: state.products.length,
        itemBuilder: (context, index) {
          final product = state.products[index];
          return ListTile(title: Text(product.name));
        },
      );
    } else if (state is ProductError) {
      return Text(state.message);
    }
    return SizedBox.shrink();
  },
)
```

---

## ✅ Checklist de Verificación

- [ ] Entities son inmutables y sin dependencias
- [ ] Repository interface en domain (no implementación)
- [ ] Use cases implementan `UseCase<Type, Params>`
- [ ] Models extienden entities
- [ ] Data sources tienen anotaciones `@LazySingleton`
- [ ] Repository impl tiene anotación `@LazySingleton`
- [ ] BLoC tiene anotación `@injectable`
- [ ] BLoC inyecta use cases (no repositorios)
- [ ] Estados manejan todos los escenarios
- [ ] Ejecutado build_runner exitosamente
- [ ] BLoC se obtiene con `getIt<BlocName>()`

---

## 🎯 Ejemplo Completo: Feature "Inventario"

Ver el feature `home` como referencia completa en:

- `lib/features/home/domain/`
- `lib/features/home/data/`
- `lib/features/home/presentation/`

---

## 📚 Recursos

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Reso Coder - Flutter TDD](https://resocoder.com/flutter-clean-architecture-tdd/)
- [fpdart Documentation](https://pub.dev/packages/fpdart)
- [injectable Documentation](https://pub.dev/packages/injectable)
