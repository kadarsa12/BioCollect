import 'enums.dart';

class User {
  final int? id;
  final String name;
  final UserType? userType;
  final String? organization;
  final String? title;
  final String? specialization;
  final String? email;
  final String? avatar;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    this.userType,
    this.organization,
    this.title,
    this.specialization,
    this.email,
    this.avatar,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_type': userType?.name,
      'organization': organization,
      'title': title,
      'specialization': specialization,
      'email': email,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      userType:
          map['user_type'] != null ? UserType.values.byName(map['user_type']) : null,
      organization: map['organization'] as String?,
      title: map['title'] as String?,
      specialization: map['specialization'] as String?,
      email: map['email'] as String?,
      avatar: map['avatar'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String generateSignature() {
    final buffer = StringBuffer();
    if (title != null && title!.isNotEmpty) {
      buffer.write('$title ');
    }
    buffer.write(name);

    if (userType != null) {
      buffer.write('\n');
      switch (userType!) {
        case UserType.academicResearcher:
          buffer.write('Researcher');
          if (organization != null && organization!.isNotEmpty) {
            buffer.write(' - $organization');
          }
          break;
        case UserType.independentConsultant:
          buffer.write('Independent Environmental Consultant');
          break;
        case UserType.companyEmployee:
          buffer.write('${specialization ?? title ?? 'Professional'}');
          if (organization != null && organization!.isNotEmpty) {
            buffer.write(' - $organization');
          }
          break;
        case UserType.student:
          buffer.write('${specialization ?? 'Student'}');
          if (organization != null && organization!.isNotEmpty) {
            buffer.write(' - $organization');
          }
          break;
        case UserType.other:
          if (organization != null && organization!.isNotEmpty) {
            buffer.write(organization);
          }
          break;
      }
    }

    if (userType == UserType.academicResearcher &&
        specialization != null &&
        specialization!.isNotEmpty) {
      buffer.write('\n$specialization');
    }

    return buffer.toString();
  }
}
