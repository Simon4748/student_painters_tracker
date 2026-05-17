class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String branchId;
  final String branchName;
  final String divisionName;
  final String color;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    required this.branchId,
    required this.branchName,
    required this.divisionName,
    required this.color,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      role: map['role'] as String,
      branchId: map['branch_id'] as String,
      branchName: map['branches']['name'] as String,
      divisionName: map['branches']['divisions']['name'] as String,
      color: map['color'] as String,
    );
  }

  bool get isMarketer => role == 'marketer';
  bool get isBranchManager => role == 'branch_manager';
  bool get isGeneralManager => role == 'general_manager';
  bool get isExecutive => role == 'executive';

  bool get canEditZones =>
      isBranchManager || isGeneralManager || isExecutive;
}