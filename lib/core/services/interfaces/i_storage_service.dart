abstract class IStorageService {
  Future<void> init();

  String get urlWebsite;
  set urlWebsite(String value);
  void removeUrlWebsite();

  String get nameDatabase;
  set nameDatabase(String value);

  List<int> get intList;
  set intList(List<int> value);

  Future<bool> clear();
}
