import 'package:flutter/material.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  bool hideBalances = false;
  bool isPasscodeEnabled = false;
  String passcode = "1234";
  bool isBiometricEnabled = false;

  ThemeMode themeMode = ThemeMode.light;
  double fontScale = 1.0;
  bool invertDebitCreditColors = false;

  String takeLabel = "أخذ";
  String payLabel = "دفع";

  bool autoBackupEnabled = true;
  int autoBackupHours = 24;

  bool printHideInfo = false;
  bool printShowTime = true;
  String printDateFormat = "yyyy-MM-dd";

  String singleMessageTemplate =
      "العميل: {customer}\n{type}: {amount} {currency}\n{note}\nالاجمالي: {total} {currency}\nالتاريخ: {date}";

  String multipleMessageTemplate =
      "العميل: {customer}\nالعمليات:\n{items}\nالرصيد الإجمالي: {total} {currency}";

  List<String> categories = ['عام', 'عملاء', 'موردين'];

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

    // تم الإبقاء حصراً على الذهب والدينار في الواجهة الرئيسية
    units = [
      UnitCurrency(
        id: goldUnitId,
        name: 'ذهب',
        symbol: 'g',
        code: 'XAU',
        kind: UnitKind.weight,
        decimalPlaces: 3,
      ),
      UnitCurrency(
        id: dzdCurrencyId,
        name: 'دينار',
        symbol: 'DA',
        code: 'DZD',
        kind: UnitKind.currency,
        decimalPlaces: 2,
      ),
    ];

    final p1 = UuidUtil.generate();
    final p2 = UuidUtil.generate();
    final p3 = UuidUtil.generate();

    parties = [
      AccountParty(id: p1, name: 'Hamza', type: PartyType.customer, phone: '222#*', category: 'عملاء'),
      AccountParty(id: p2, name: 'adel', type: PartyType.customer, phone: '06666599791', category: 'عملاء'),
      AccountParty(id: p3, name: 'نورالدين', type: PartyType.supplier, phone: '123', category: 'موردين'),
    ];

    entries = [
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p1,
        unitId: goldUnitId,
        rawAmount: 59000,
        type: TransactionType.take,
        date: DateTime(2026, 9, 12, 5, 49),
        note: 'خاتم',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p2,
        unitId: dzdCurrencyId,
        rawAmount: 5000000,
        type: TransactionType.pay,
        date: DateTime(2025, 11, 6),
        note: 'خلص',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p2,
        unitId: dzdCurrencyId,
        rawAmount: 500000,
        type: TransactionType.take,
        date: DateTime(2025, 11, 6),
        note: 'حجرة',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p2,
        unitId: dzdCurrencyId,
        rawAmount: 400000,
        type: TransactionType.pay,
        date: DateTime(2026, 9, 10),
        note: 'dzd',
      ),
    ];

    pdfColumns = [
      PdfColumnConfig(id: 'seq', title: 'الرقم / التسلسل', isVisible: false),
      PdfColumnConfig(id: 'details', title: 'البيان / التفاصيل', isVisible: true),
      PdfColumnConfig(id: 'pay', title: 'دفع', isVisible: true),
      PdfColumnConfig(id: 'take', title: 'أخذ', isVisible: true),
      PdfColumnConfig(id: 'balance', title: 'الرصيد', isVisible: true),
      PdfColumnConfig(id: 'date', title: 'التاريخ', isVisible: true),
    ];
  }

  Color get debitColor => invertDebitCreditColors ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
  Color get creditColor => invertDebitCreditColors ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
  Color get debitBg => invertDebitCreditColors ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
  Color get creditBg => invertDebitCreditColors ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

  Map<String, int> getBalancesForParty(String partyId) {
    final Map<String, int> balances = {};
    for (var u in units.where((element) => !element.isDeleted)) {
      balances[u.id] = 0;
    }
    final activeEntries = entries.where((e) => e.partyId == partyId && !e.isDeleted);
    for (var entry in activeEntries) {
      int current = balances[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        current -= entry.rawAmount;
      } else {
        current += entry.rawAmount;
      }
      balances[entry.unitId] = current;
    }
    return balances;
  }

  Map<String, int> getTotalStoreBalances() {
    final Map<String, int> totals = {};
    for (var u in units.where((element) => !element.isDeleted)) {
      totals[u.id] = 0;
    }
    for (var entry in entries.where((e) => !e.isDeleted)) {
      int current = totals[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        current -= entry.rawAmount;
      } else {
        current += entry.rawAmount;
      }
      totals[entry.unitId] = current;
    }
    return totals;
  }

  int getPartyCountForCategory(String category) {
    return parties.where((p) => p.category == category && !p.isDeleted).length;
  }

  int getTransactionCountForUnit(String unitId) {
    return entries.where((e) => e.unitId == unitId && !e.isDeleted).length;
  }

  void addCategory(String cat) {
    if (!categories.contains(cat)) {
      categories.add(cat);
      notifyListeners();
    }
  }

  void updateCategory(String oldCat, String newCat) {
    int idx = categories.indexOf(oldCat);
    if (idx != -1) {
      categories[idx] = newCat;
      for (var p in parties) {
        if (p.category == oldCat) p.category = newCat;
      }
      notifyListeners();
    }
  }

  void deleteCategory(String cat) {
    categories.remove(cat);
    notifyListeners();
  }

  void addUnit(UnitCurrency unit) {
    units.add(unit);
    notifyListeners();
  }

  void updateUnit(UnitCurrency unit) {
    int idx = units.indexWhere((u) => u.id == unit.id);
    if (idx != -1) {
      units[idx] = unit;
      notifyListeners();
    }
  }

  void deleteUnit(String id) {
    int idx = units.indexWhere((u) => u.id == id);
    if (idx != -1) {
      units[idx].isDeleted = true;
      notifyListeners();
    }
  }

  void addParty(AccountParty party) {
    parties.add(party);
    notifyListeners();
  }

  void addTransactions(List<LedgerEntry> newEntries) {
    entries.addAll(newEntries);
    notifyListeners();
  }

  void deleteMultipleEntries(List<String> ids) {
    for (var id in ids) {
      int idx = entries.indexWhere((e) => e.id == id);
      if (idx != -1) entries[idx] = LedgerEntry(
        id: entries[idx].id,
        partyId: entries[idx].partyId,
        unitId: entries[idx].unitId,
        rawAmount: entries[idx].rawAmount,
        type: entries[idx].type,
        date: entries[idx].date,
        note: entries[idx].note,
        isDeleted: true,
      );
    }
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
