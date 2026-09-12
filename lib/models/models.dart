import 'dart:math';

class UuidUtil {
  static final Random _random = Random();
  static String generate() {
    return '${_hex(4)}-${_hex(2)}-${_hex(2)}-${_hex(2)}-${_hex(6)}';
  }

  static String _hex(int length) {
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < length * 2; i++) {
      sb.write(_random.nextInt(16).toRadixString(16));
    }
    return sb.toString();
  }
}

enum PartyType { customer, supplier, expense }
enum TransactionType { take, pay }
enum UnitKind { weight, currency }

class CategoryItem {
  final String id;
  String name;
  bool isDeleted;

  CategoryItem({
    required this.id,
    required this.name,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isDeleted': isDeleted};
  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] ?? UuidUtil.generate(),
        name: json['name'] ?? '',
        isDeleted: json['isDeleted'] ?? false,
      );
}

class UnitCurrency {
  final String id;
  String name;
  String symbol;
  String code;
  UnitKind kind;
  int decimalPlaces;
  bool isDeleted;

  UnitCurrency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
    required this.kind,
    this.decimalPlaces = 2,
    this.isDeleted = false,
  });

  String formatValue(int rawValue) {
    double val = rawValue / pow(10, decimalPlaces);
    return val.toStringAsFixed(decimalPlaces);
  }

  int parseInput(String input) {
    double val = double.tryParse(input.replaceAll(',', '.')) ?? 0.0;
    return (val * pow(10, decimalPlaces)).round();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'symbol': symbol,
        'code': code,
        'kind': kind.index,
        'decimalPlaces': decimalPlaces,
        'isDeleted': isDeleted,
      };

  factory UnitCurrency.fromJson(Map<String, dynamic> json) => UnitCurrency(
        id: json['id'] ?? UuidUtil.generate(),
        name: json['name'] ?? '',
        symbol: json['symbol'] ?? '',
        code: json['code'] ?? '',
        kind: UnitKind.values[json['kind'] ?? 0],
        decimalPlaces: json['decimalPlaces'] ?? 2,
        isDeleted: json['isDeleted'] ?? false,
      );
}

class AccountParty {
  final String id;
  String name;
  String phone;
  PartyType type;
  String category;
  String address;
  bool isDeleted;

  AccountParty({
    required this.id,
    required this.name,
    this.phone = '',
    this.type = PartyType.customer,
    this.category = 'عام',
    this.address = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'type': type.index,
        'category': category,
        'address': address,
        'isDeleted': isDeleted,
      };

  factory AccountParty.fromJson(Map<String, dynamic> json) => AccountParty(
        id: json['id'] ?? UuidUtil.generate(),
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        type: PartyType.values[json['type'] ?? 0],
        category: json['category'] ?? 'عام',
        address: json['address'] ?? '',
        isDeleted: json['isDeleted'] ?? false,
      );
}

class LedgerEntry {
  final String id;
  final String? compositeGroupId;
  final String partyId;
  final String unitId;
  final int rawAmount;
  final TransactionType type;
  final DateTime date;
  final String note;
  final bool isDeleted;

  LedgerEntry({
    required this.id,
    this.compositeGroupId,
    required this.partyId,
    required this.unitId,
    required this.rawAmount,
    required this.type,
    required this.date,
    this.note = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'compositeGroupId': compositeGroupId,
        'partyId': partyId,
        'unitId': unitId,
        'rawAmount': rawAmount,
        'type': type.index,
        'date': date.toIso8601String(),
        'note': note,
        'isDeleted': isDeleted,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'] ?? UuidUtil.generate(),
        compositeGroupId: json['compositeGroupId'],
        partyId: json['partyId'] ?? '',
        unitId: json['unitId'] ?? '',
        rawAmount: json['rawAmount'] ?? 0,
        type: TransactionType.values[json['type'] ?? 0],
        date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
        note: json['note'] ?? '',
        isDeleted: json['isDeleted'] ?? false,
      );
}

class PdfColumnConfig {
  final String id;
  String title;
  bool isVisible;

  PdfColumnConfig({required this.id, required this.title, this.isVisible = true});
}
