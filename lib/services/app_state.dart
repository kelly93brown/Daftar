import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // الحماية والخصوصية
  bool hideBalances = false;
  bool isPasscodeEnabled = false;
  String passcode = "1234";
  bool isBiometricEnabled = false;

  // المظهر والتخصيص
  ThemeMode themeMode = ThemeMode.light;
  double fontScale = 1.0; // 80% to 140%
  bool invertDebitCreditColors = false; // افتراضياً: أخذ=أحمر، دفع=أخضر

  // المسميات القابلة للتخصيص
  String takeLabel = "أخذ";
  String payLabel = "دفع";

  // النسخ الاحتياطي التلقائي
  bool autoBackupEnabled = true;
  int autoBackupHours = 24;

  // إعدادات الطباعة
  bool printHideInfo = false;
  bool printShowTime = true;
  String printDateFormat = "yyyy-MM-dd";

  // قوالب الرسائل
  String singleMessageTemplate =
      "العميل: {customer}\n{type}: {amount} {currency}\n{note}\nالاجمالي: {total} {currency}\nالتاريخ: {date}";

  String multipleMessageTemplate =
      "العميل: {customer}\nالعمليات:\n{items}\nالرصيد الإجمالي: {total} {currency}";

  // الوحدات والعملات الافتراضية
  late List<UnitCurrency> units;
  late List<AccountParty> parties;
  late List<LedgerEntry> entries;
  late List<PdfColumnConfig> pdfColumns;

  AppState() {
    _initDefaults();
  }

  void _initDefaults() {
    final goldUnitId = UuidUtil.generate();
    final dzdCurrencyId = UuidUtil.generate();
    final ringUnitId = UuidUtil.generate();

    units = [
      UnitCurrency(
        id: goldUnitId,
        name: 'ذهب (عيار 18)',
        symbol: 'g',
        code: 'XAU',
        kind: UnitKind.weight,
        decimalPlaces: 3,
      ),
      UnitCurrency(
        id: dzdCurrencyId,
        name: 'دينار جزائري',
        symbol: 'DA',
        code: 'DZD',
        kind: UnitKind.currency,
        decimalPlaces: 2,
      ),
      UnitCurrency(
        id: ringUnitId,
        name: 'خواتم مصوغة',
        symbol: 'قطعة',
        code: 'RNG',
        kind: UnitKind.weight,
        decimalPlaces: 0,
      ),
    ];

    // أطراف افتراضية (زبائن وصاغة)
    final p1 = UuidUtil.generate();
    final p2 = UuidUtil.generate();
    final p3 = UuidUtil.generate();

    parties = [
      AccountParty(id: p1, name: 'مجوهرات الأمانة (ورشة)', type: PartyType.supplier, phone: '0550123456', category: 'موردين'),
      AccountParty(id: p2, name: 'الحاج بلقاسم', type: PartyType.customer, phone: '0661987654', category: 'عملاء'),
      AccountParty(id: p3, name: 'صياغة النور', type: PartyType.customer, phone: '0770334455', category: 'عملاء'),
    ];

    // معاملات أولية لتوضيح الرصيد المزدوج
    entries = [
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p2,
        unitId: goldUnitId,
        rawAmount: 25450, // 25.450 g ذهب
        type: TransactionType.take,
        date: DateTime.now().subtract(const Duration(days: 2)),
        note: 'سوار عيار 18 كسر',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p2,
        unitId: dzdCurrencyId,
        rawAmount: 15000000, // 150,000.00 DA
        type: TransactionType.pay,
        date: DateTime.now().subtract(const Duration(days: 1)),
        note: 'دفعة نقدية باليد',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p1,
        unitId: goldUnitId,
        rawAmount: 100000, // 100.000 g
        type: TransactionType.pay,
        date: DateTime.now().subtract(const Duration(days: 5)),
        note: 'طلبية سبائك صافي',
      ),
    ];

    pdfColumns = [
      PdfColumnConfig(id: 'seq', title: 'الرقم / التسلسل', isVisible: false),
      PdfColumnConfig(id: 'details', title: 'البيان / التفاصيل', isVisible: true),
      PdfColumnConfig(id: 'pay', title: 'دفع (دائن)', isVisible: true),
      PdfColumnConfig(id: 'take', title: 'أخذ (مدين)', isVisible: true),
      PdfColumnConfig(id: 'balance', title: 'الرصيد', isVisible: true),
      PdfColumnConfig(id: 'date', title: 'التاريخ', isVisible: true),
    ];
  }

  // ألوان المعاملات (ديناميكية وفق إعدادات العكس)
  Color get debitColor => invertDebitCreditColors ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
  Color get creditColor => invertDebitCreditColors ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
  Color get debitBg => invertDebitCreditColors ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
  Color get creditBg => invertDebitCreditColors ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

  // حساب الأرصدة المزدوجة لكل طرف
  Map<String, int> getBalancesForParty(String partyId) {
    final Map<String, int> balances = {};
    for (var u in units.where((element) => !element.isDeleted)) {
      balances[u.id] = 0;
    }

    final activeEntries = entries.where((e) => e.partyId == partyId && !e.isDeleted);
    for (var entry in activeEntries) {
      int current = balances[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        current += entry.rawAmount; // مدين (عليه)
      } else {
        current -= entry.rawAmount; // دائن (له)
      }
      balances[entry.unitId] = current;
    }
    return balances;
  }

  // حساب إجمالي الأرصدة العامة في المتجر (ذهب ونقد)
  Map<String, int> getTotalStoreBalances() {
    final Map<String, int> totals = {};
    for (var u in units.where((element) => !element.isDeleted)) {
      totals[u.id] = 0;
    }
    for (var entry in entries.where((e) => !e.isDeleted)) {
      int current = totals[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        current += entry.rawAmount;
      } else {
        current -= entry.rawAmount;
      }
      totals[entry.unitId] = current;
    }
    return totals;
  }

  // إضافة معاملة فردية أو مركبة
  void addTransactions(List<LedgerEntry> newEntries) {
    entries.addAll(newEntries);
    notifyListeners();
  }

  void toggleHideBalances() {
    hideBalances = !hideBalances;
    notifyListeners();
  }

  void updateTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void updateFontScale(double scale) {
    fontScale = scale;
    notifyListeners();
  }

  void updateInvertColors(bool invert) {
    invertDebitCreditColors = invert;
    notifyListeners();
  }

  void updateLabels(String take, String pay) {
    takeLabel = take;
    payLabel = pay;
    notifyListeners();
  }
}
