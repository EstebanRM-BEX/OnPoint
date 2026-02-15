/// Domain entity for authenticated user.
/// This is a pure business object without any framework dependencies.
class User {
  final int uid;
  final String name;
  final String username;

  const User({
    required this.uid,
    required this.name,
    required this.username,
  });
}
