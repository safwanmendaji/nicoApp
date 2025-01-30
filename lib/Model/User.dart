// class User {
//   final int id;
//   final String name;
//   final String phone;
//   final String department;
//   final String email;

//   User({
//     required this.id,
//     required this.name,
//     required this.phone,
//     required this.department,
//     required this.email,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       id: json['Id'], // The API returns 'Id' for the user ID
//       name: json['name'],
//       phone: json['phone'],
//       department: json['department'],
//       email: json['email'],
//     );
//   }
// }

class User {
  final int id;
  final String name;
  final String phone;
  final String department;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.phone,
    required this.department,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['Id'], // Assume 'Id' is always non-null
      name: json['name'] ?? '', // Fallback to empty string if null
      phone: json['phone'] ?? '', // Fallback to empty string if null
      department: json['department'] ?? '', // Fallback to empty string if null
      email: json['email'] ?? '', // Fallback to empty string if null
    );
  }
}
