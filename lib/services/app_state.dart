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

  String storeNameAr = "مجوهرات البركة";
  String storeNameEn = "Al Baraka Jewelry";
  String storePhone = "0550123456";
  String storeAddress = "سوق الذهب المركزي";

  bool printHideInfo = false;
  bool printShowTime = true;

  String singleMessageTemplate =
      "العميل: {customer}\n{type}: {amount} {currency}\n{note}\nالاجمالي: {total} {currency}\nالتاريخ: {date}";
  String multipleMessageTemplate =
      "العميل: {customer}\nالعمليات:\n{items}\nالرصيد الإجمالي: {total} {currency}";

  late List<CategoryItem> categories;
  late List<UnitCurrency> units;
  late List<AccountParty> parties;
  late List<LedgerEntry> entries;
  late List<PdfColumnConfig> pdfColumns;

  AppState() {
    _initDefaults();
  }

  void _initDefaults() {
    categories = [
      CategoryItem(id: UuidUtil.generate(), name: 'عام'),
      CategoryItem(id: UuidUtil.generate(), name: 'عملاء'),
      CategoryItem(id: UuidUtil.generate(), name: 'موردين'),
    ];

    final goldUnitId = UuidUtil.generate();
    final dzdCurrencyId = UuidUtil.generate();

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
      AccountParty(id: p1, name: 'Hamza', phone: '222#*', category: 'عام', type: PartyType.customer),
      AccountParty(id: p2, name: 'adel', phone: '06666599791', category: 'عملاء', type: PartyType.customer),
      AccountParty(id: p3, name: 'نورالدين', phone: '123', category: 'عملاء', type: PartyType.customer),
    ];

    entries = [
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p1,
        unitId: goldUnitId,
        rawAmount: 59000,
        type: TransactionType.take,
        date: DateTime.now(),
        note: 'خاتم',
      ),
      LedgerEntry(
        id: UuidUtil.generate(),
        partyId: p1,
        unitId: dzdCurrencyId,
        rawAmount: 400000,
        type: TransactionType.pay,
        date: DateTime.now(),
        note: 'dzd',
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

  Color get debitColor => invertDebitCreditColors ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
  Color get creditColor => invertDebitCreditColors ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32);
  Color get debitBg => invertDebitCreditColors ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
  Color get creditBg => invertDebitCreditColors ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9);

  Map<String, int> getBalancesForParty(String partyId) {
    final Map<String, int> balances = {};
    for (var u in units.where((u) => !u.isDeleted)) {
      balances[u.id] = 0;
    }
    for (var entry in entries.where((e) => e.partyId == partyId && !e.isDeleted)) {
      int current = balances[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        current += entry.rawAmount;
      } else {
        current -= entry.rawAmount;
      }
      balances[entry.unitId] = current;
    }
    return balances;
  }

  Map<String, int> getTotalStoreBalances() {
    final Map<String, int> totals = {};
    for (var u in units.where((u) => !u.isDeleted)) {
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

  int getAccountsCountForCategory(String categoryName) {
    return parties.where((p) => p.category == categoryName && !p.isDeleted).length;
  }

  int getAccountsCountForUnit(String unitId) {
    final partyIds = entries.where((e) => e.unitId == unitId && !e.isDeleted).map((e) => e.partyId).toSet();
    return partyIds.length;
  }

  void addTransactions(List<LedgerEntry> newEntries) {
    entries.addAll(newEntries);
    notifyListeners();
  }

  void addParty(AccountParty party) {
    parties.add(party);
    notifyListeners();
  }

  void addCategory(String name) {
    categories.add(CategoryItem(id: UuidUtil.generate(), name: name));
    notifyListeners();
  }

  void updateCategory(String id, String newName) {
    final cat = categories.firstWhere((c) => c.id == id);
    cat.name = newName;
    notifyListeners();
  }

  void deleteCategory(String id) {
    categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void addUnit(UnitCurrency unit) {
    units.add(unit);
    notifyListeners();
  }

  void updateUnit(String id, String name, String symbol, int decimals) {
    final u = units.firstWhere((element) => element.id == id);
    u.name = name;
    u.symbol = symbol;
    u.decimalPlaces = decimals;
    notifyListeners();
  }

  void deleteUnit(String id) {
    units.removeWhere((u) => u.id == id);
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

  void updatePersonalInfo(String ar, String en, String phone, String address) {
    storeNameAr = ar;
    storeNameEn = en;
    storePhone = phone;
    storeAddress = address;
    notifyListeners();
  }
}
