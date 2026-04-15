import '../../sessions/domain/session_type.dart';

enum StatsScope {
  company,
  division,
  branch,
  me,
}

class UserStats {
  final String userId;
  final String name;
  final String role;
  final String branchId;
  final String branchName;
  final String divisionName;
  final Map<SessionType, double> hoursByType;

  const UserStats({
    required this.userId,
    required this.name,
    required this.role,
    required this.branchId,
    required this.branchName,
    required this.divisionName,
    required this.hoursByType,
  });

  double get totalHours =>
      hoursByType.values.fold(0, (sum, value) => sum + value);

  double hoursForType(SessionType? type) {
    if (type == null) return totalHours;
    return hoursByType[type] ?? 0;
  }
}

class BranchStats {
  final String branchId;
  final String branchName;
  final String divisionName;
  final Map<SessionType, double> hoursByType;

  const BranchStats({
    required this.branchId,
    required this.branchName,
    required this.divisionName,
    required this.hoursByType,
  });

  double get totalHours =>
      hoursByType.values.fold(0, (sum, value) => sum + value);

  double hoursForType(SessionType? type) {
    if (type == null) return totalHours;
    return hoursByType[type] ?? 0;
  }
}