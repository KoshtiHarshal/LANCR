class User {
  final String id;
  final String email;
  final String role; // 'freelancer' or 'client'
  final bool profileCompleted;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.profileCompleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      email: json['email'],
      role: json['role'],
      profileCompleted: json['profileCompleted'] ?? false,
    );
  }
}