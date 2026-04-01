class User {
  final String id;
  final String email;
  final String role; // 'freelancer' or 'client';

  User({
    required this.id,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      role: json['role'],
    );
  }
}