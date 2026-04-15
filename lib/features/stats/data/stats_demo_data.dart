import '../../sessions/domain/session_type.dart';
import '../domain/stats_models.dart';

class StatsDemoData {
  static const String currentUserId = 'manager_1';
  static const String currentUserRole = 'Branch Manager';
  static const String currentBranchId = 'brattleboro_branch';
  static const String currentDivisionName = 'New England';

  static const List<UserStats> users = [
    UserStats(
      userId: 'manager_1',
      name: 'Simon',
      role: 'Branch Manager',
      branchId: 'brattleboro_branch',
      branchName: 'Brattleboro Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 18,
        SessionType.flyerRun: 4,
        SessionType.nowHiringFlyers: 2,
        SessionType.other: 1,
      },
    ),
    UserStats(
      userId: 'marketer_1',
      name: 'Alex',
      role: 'Marketer',
      branchId: 'brattleboro_branch',
      branchName: 'Brattleboro Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 12,
        SessionType.flyerRun: 3,
        SessionType.nowHiringFlyers: 1,
        SessionType.other: 0,
      },
    ),
    UserStats(
      userId: 'marketer_2',
      name: 'Jordan',
      role: 'Marketer',
      branchId: 'brattleboro_branch',
      branchName: 'Brattleboro Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 9,
        SessionType.flyerRun: 2,
        SessionType.nowHiringFlyers: 1,
        SessionType.other: 1,
      },
    ),
    UserStats(
      userId: 'manager_2',
      name: 'Emma',
      role: 'Branch Manager',
      branchId: 'western_mass_branch',
      branchName: 'Western Mass Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 16,
        SessionType.flyerRun: 5,
        SessionType.nowHiringFlyers: 1,
        SessionType.other: 1,
      },
    ),
    UserStats(
      userId: 'manager_3',
      name: 'Ryan',
      role: 'Branch Manager',
      branchId: 'cleveland_branch',
      branchName: 'Cleveland Branch',
      divisionName: 'Ohio',
      hoursByType: {
        SessionType.doorToDoor: 20,
        SessionType.flyerRun: 4,
        SessionType.nowHiringFlyers: 3,
        SessionType.other: 1,
      },
    ),
    UserStats(
      userId: 'manager_4',
      name: 'Mia',
      role: 'Branch Manager',
      branchId: 'detroit_branch',
      branchName: 'Detroit Branch',
      divisionName: 'Michigan',
      hoursByType: {
        SessionType.doorToDoor: 17,
        SessionType.flyerRun: 6,
        SessionType.nowHiringFlyers: 2,
        SessionType.other: 2,
      },
    ),
  ];

  static const List<BranchStats> branches = [
    BranchStats(
      branchId: 'brattleboro_branch',
      branchName: 'Brattleboro Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 39,
        SessionType.flyerRun: 9,
        SessionType.nowHiringFlyers: 4,
        SessionType.other: 2,
      },
    ),
    BranchStats(
      branchId: 'western_mass_branch',
      branchName: 'Western Mass Branch',
      divisionName: 'New England',
      hoursByType: {
        SessionType.doorToDoor: 42,
        SessionType.flyerRun: 10,
        SessionType.nowHiringFlyers: 3,
        SessionType.other: 2,
      },
    ),
    BranchStats(
      branchId: 'cleveland_branch',
      branchName: 'Cleveland Branch',
      divisionName: 'Ohio',
      hoursByType: {
        SessionType.doorToDoor: 48,
        SessionType.flyerRun: 9,
        SessionType.nowHiringFlyers: 5,
        SessionType.other: 2,
      },
    ),
    BranchStats(
      branchId: 'detroit_branch',
      branchName: 'Detroit Branch',
      divisionName: 'Michigan',
      hoursByType: {
        SessionType.doorToDoor: 44,
        SessionType.flyerRun: 11,
        SessionType.nowHiringFlyers: 4,
        SessionType.other: 3,
      },
    ),
  ];
}