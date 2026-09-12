import 'dart:math';

// مولد UUID خفيف ومستقل بدون حزم خارجية
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

// نوع الطرف: زبون، مورد، مصروفات
enum PartyType { customer, supplier, expense }

// نوع الحركة: أخذ (مدين) / دفع (دائن)
enum TransactionType { take, pay }

// صنف الوحدة أو العملة (ذهب/وزن مقابل نقد)
enum UnitKind { weight, currency }

class UnitCurrency {
  final String id;
  String name; // غرام، دينار، كاسي، خواتم
  String symbol; // g, DA, EUR
  String code; // DZD, XAU
  UnitKind kind;
  int decimalPlaces; // 3 للوزن (مليغرام)، 2 للنقد (سنتيم)
  bool isDeleted;

  UnitCurrency({
    required this.id,
    required this.name,
    required this.symbol,
    required this.code,
    required this.kind,
    this.decimalPlaces = 3,
    this.isDeleted = false,
  });

  // تحويل الرقم الصحيح إلى نص للعرض
  String formatValue(int rawValue) {
    double val = rawValue / pow(10, decimalPlaces);
    return val.toStringAsFixed(decimalPlaces);
  }

  // تحويل النص المدخل من المستخدم إلى عدد صحيح
  int parseInput(String input) {
    double val = double.tryParse(input.replaceAll(',', '.')) ?? 0.0;
    return (val * pow(10, decimalPlaces)).round();
  }
}

class AccountParty {
  final String id;
  String name;
  String phone;
  PartyType type;
  String category; // عام، تجار كبار، ورشات...
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
}

class LedgerEntry {
  final String id;
  final String? compositeGroupId; // لربط الحركات المركبة (وزن + نقد)
  final String partyId;
  final String unitId;
  final int rawAmount; // مخزن كعدد صحيح دقيق
  final TransactionType type;
  final DateTime date;
  final String note;
  final String? imageAttachment;
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
    this.imageAttachment,
    this.isDeleted = false,
  });
}

class PdfColumnConfig {
  final String id;
  String title;
  bool isVisible;

  PdfColumnConfig({
    required this.id,
    required this.title,
    this.isVisible = true,
  });
}
