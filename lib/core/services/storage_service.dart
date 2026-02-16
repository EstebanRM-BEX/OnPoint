import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms_app/core/services/interfaces/i_storage_service.dart';

@LazySingleton(as: IStorageService)
class StorageService implements IStorageService {
  late SharedPreferences _prefs;

  @override
  @PostConstruct(preResolve: true)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Backing fields for in-memory caching if needed (mirroring original impl)
  String _urlWebsite = '';
  String _nameDatabase = '';

  @override
  String get urlWebsite {
    final response = _prefs.getString('urlWebsite') ?? _urlWebsite;
    return response;
  }

  @override
  set urlWebsite(String urlWebsite) {
    _urlWebsite = urlWebsite;
    _prefs.setString('urlWebsite', urlWebsite);
  }

  @override
  void removeUrlWebsite() {
    _prefs.remove('urlWebsite');
  }

  @override
  String get nameDatabase {
    return _prefs.getString('nameDatabase') ?? _nameDatabase;
  }

  @override
  set nameDatabase(String nameDatabase) {
    _nameDatabase = nameDatabase;
    _prefs.setString('nameDatabase', nameDatabase);
  }

  @override
  List<int> get intList {
    return _prefs.getStringList('intList')?.map((e) => int.parse(e)).toList() ??
        [];
  }

  @override
  set intList(List<int> intList) {
    _prefs.setStringList('intList', intList.map((e) => e.toString()).toList());
  }

  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
