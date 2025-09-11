enum UserRole {
  client,
  manager,
  admin,
  unknown
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.manager:
        return 'manager';
      case UserRole.admin:
        return 'admin';
      default:
        return 'unknown';
    }
  }

  static UserRole fromString(String? role) {
    switch (role) {
      case 'client':
        return UserRole.client;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }
} 