class FinanceAccount {
  final String id;
  final String name;
  final String? officialName;
  final String? mask;
  final String? type;
  final String? subtype;
  final double balanceCurrent;
  final double? balanceAvailable;

  FinanceAccount({
    required this.id,
    required this.name,
    this.officialName,
    this.mask,
    this.type,
    this.subtype,
    required this.balanceCurrent,
    this.balanceAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'officialName': officialName,
      'mask': mask,
      'type': type,
      'subtype': subtype,
      'balanceCurrent': balanceCurrent,
      'balanceAvailable': balanceAvailable,
    };
  }

  factory FinanceAccount.fromMap(Map<String, dynamic> map) {
    return FinanceAccount(
      id: map['id'],
      name: map['name'],
      officialName: map['officialName'],
      mask: map['mask'],
      type: map['type'],
      subtype: map['subtype'],
      balanceCurrent: map['balanceCurrent'],
      balanceAvailable: map['balanceAvailable'],
    );
  }
}
