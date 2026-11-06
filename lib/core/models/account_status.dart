enum AccountStatus {
  active,
  inactive,
  pendingActivation,
  suspended,
  unknown;

  static AccountStatus fromApi(Object? value) => switch (value) {
        'ACTIVE' => AccountStatus.active,
        'INACTIVE' => AccountStatus.inactive,
        'PENDING_ACTIVATION' => AccountStatus.pendingActivation,
        'SUSPENDED' => AccountStatus.suspended,
        _ => AccountStatus.unknown,
      };

  String get apiValue => switch (this) {
        AccountStatus.active => 'ACTIVE',
        AccountStatus.inactive => 'INACTIVE',
        AccountStatus.pendingActivation => 'PENDING_ACTIVATION',
        AccountStatus.suspended => 'SUSPENDED',
        AccountStatus.unknown => 'UNKNOWN',
      };

  String get label => switch (this) {
        AccountStatus.active => 'Active',
        AccountStatus.inactive => 'Inactive',
        AccountStatus.pendingActivation => 'Pending activation',
        AccountStatus.suspended => 'Suspended',
        AccountStatus.unknown => 'Unknown',
      };
}
