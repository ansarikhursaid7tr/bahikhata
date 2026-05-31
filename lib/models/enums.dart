/// Shared enums used across the BahiKhata app.

/// User roles for access control.
enum UserRole {
  owner,
  admin,
  manager,
  staff;

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.staff:
        return 'Staff';
    }
  }

  bool get canManageRates => this == owner || this == admin || this == manager;
  bool get canManageStaff => this == owner || this == admin || this == manager;
  bool get canManageUsers => this == owner || this == admin;
  bool get canAddEntries => this != staff;
  bool get canEditEntries => this == owner || this == admin;
  bool get canViewAllData => this != staff;
  bool get canExport => this == owner || this == admin;
}

/// Business types for organization flexibility.
enum BusinessType {
  tailorShop,
  generalShop,
  personalLedger,
  workshop,
  other;

  String get displayName {
    switch (this) {
      case BusinessType.tailorShop:
        return 'Tailor Shop';
      case BusinessType.generalShop:
        return 'General Shop';
      case BusinessType.personalLedger:
        return 'Personal Ledger';
      case BusinessType.workshop:
        return 'Workshop';
      case BusinessType.other:
        return 'Other';
    }
  }
}

/// Staff types — extensible for different business types.
enum StaffType {
  tailor,
  helper,
  master,
  other;

  String get displayName {
    switch (this) {
      case StaffType.tailor:
        return 'Tailor';
      case StaffType.helper:
        return 'Helper';
      case StaffType.master:
        return 'Master';
      case StaffType.other:
        return 'Other';
    }
  }
}

/// Types of money entries.
enum MoneyEntryType {
  advance,
  partialPayment,
  finalPayment,
  deduction,
  bonus,
  other;

  String get displayName {
    switch (this) {
      case MoneyEntryType.advance:
        return 'Advance';
      case MoneyEntryType.partialPayment:
        return 'Partial Payment';
      case MoneyEntryType.finalPayment:
        return 'Final Payment';
      case MoneyEntryType.deduction:
        return 'Deduction';
      case MoneyEntryType.bonus:
        return 'Bonus';
      case MoneyEntryType.other:
        return 'Other';
    }
  }

  /// Whether this type increases or decreases the payable balance.
  MoneyEffect get effect {
    switch (this) {
      case MoneyEntryType.bonus:
        return MoneyEffect.increasePayable;
      default:
        return MoneyEffect.decreasePayable;
    }
  }
}

/// Effect of a money entry on payable balance.
enum MoneyEffect {
  decreasePayable,
  increasePayable;

  String get displayName {
    switch (this) {
      case MoneyEffect.decreasePayable:
        return 'Decreases Payable';
      case MoneyEffect.increasePayable:
        return 'Increases Payable';
    }
  }
}
