class UserProfile {
  final String? name;
  final String? headline;
  final String? company;
  final String? location;
  final String? bio;
  final List<String> skills;
  final int? experienceYears;
  final String? portfolioUrl;
  final String? linkedinUrl;

  UserProfile({
    this.name,
    this.headline,
    this.company,
    this.location,
    this.bio,
    this.skills = const [],
    this.experienceYears,
    this.portfolioUrl,
    this.linkedinUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserProfile();
    return UserProfile(
      name: json['name'],
      headline: json['headline'],
      company: json['company'],
      location: json['location'],
      bio: json['bio'],
      skills: List<String>.from(json['skills'] ?? []),
      experienceYears: json['experienceYears'],
      portfolioUrl: json['portfolioUrl'],
      linkedinUrl: json['linkedinUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'headline': headline,
    'company': company,
    'location': location,
    'bio': bio,
    'skills': skills,
    'experienceYears': experienceYears,
    'portfolioUrl': portfolioUrl,
    'linkedinUrl': linkedinUrl,
  };
}

class User {
  final String id;
  final String email;
  final String role;
  final bool profileCompleted;
  final UserProfile profile;

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.profileCompleted,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      email: json['email'],
      role: json['role'],
      profileCompleted: json['profileCompleted'] ?? false,
      profile: UserProfile.fromJson(json['profile']),
    );
  }
}