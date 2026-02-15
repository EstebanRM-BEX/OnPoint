/// Domain entity for user data.
class UserData {
  final String name;
  final String email;
  final String rol;
  final String image;

  const UserData({
    required this.name,
    required this.email,
    required this.rol,
    this.image = '',
  });
}
