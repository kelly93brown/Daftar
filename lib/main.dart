import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// النماذج (Models) والبيانات الوهمية (Dummy Data)
// -----------------------------------------------------------------------------

class Account {
  final String id;
  final String name;
  final String phone;
  final bool isCustomer;
  double goldBalance; // موجب = لنا، سالب = علينا
  double currencyBalance; // DZD

  Account({
    required this.id,
    required this.name,
    required this.phone,
    this.isCustomer = true,
    this.goldBalance = 0.0,
    this.currencyBalance = 0.0,
  });
}

class Transaction {
  final String id;
  final String accountId;
  final DateTime date;
  final double amount;
  final String unit; // 'غرام', 'DZD', 'EUR', 'USD'
  final bool isTake; // true = أخذ (دائن لنا), false = دفع (مدين لنا)
  final String details;

  Transaction({
    required this.id,
    required this.accountId,
    required this.date,
    required this.amount,
    required this.unit,
    required this.isTake,
    this.details = '',
  });
}

class Note {
  final String title;
  final String content;
  final DateTime date;

  Note(this.title, this.content, this.date);
}

class AppRepo {
  static List<Account> accounts = [
    Account(id: '1', name: 'محمد الصائغ', phone: '0555123456', isCustomer: true, goldBalance: 15.5, currencyBalance: -15000),
    Account(id: '2', name: 'أحمد تجزئة', phone: '0666987654', isCustomer: true, goldBalance: -5.0, currencyBalance: 45000),
    Account(id: '3', name: 'مورد الذهب دبي', phone: '0777111222', isCustomer: false, goldBalance: -150.0, currencyBalance: 0),
  ];

  static List<Transaction> transactions = [
    Transaction(id: 't1', accountId: '1', date: DateTime.now().subtract(const Duration(days: 1)), amount: 10.5, unit: 'غرام', isTake: true, details: 'ذهب مكسر'),
    Transaction(id: 't2', accountId: '1', date: DateTime.now(), amount: 15000, unit: 'DZD', isTake: false, details: 'أجرة تصنيع'),
  ];

  static List<Note> notes = [
    Note('طلبية طاقم زفاف', 'تجهيز طاقم عيار 18 بوزن 45 غرام قبل نهاية الشهر.', DateTime.now()),
  ];
}

// -----------------------------------------------------------------------------
// نقطة الدخول (Entry Point) وإعدادات التطبيق
// -----------------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دفتر المجوهرات',
      // إجبار التطبيق على الاتجاه من اليمين لليسار (RTL) لدعم العربية
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50), // لون أزرق داكن/رمادي عملي
          primary: const Color(0xFF2C3E50),
          secondary: const Color(0xFFD4AF37), // لون ذهبي للمسات
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // خلفية مريحة للعين
        fontFamily: 'Tahoma', // خط افتراضي واضح
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
      ),
      home: const LockScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 1: شاشة الأمان والقفل
// -----------------------------------------------------------------------------

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String pin = '';
  final String correctPin = '1234'; // رمز افتراضي للتجربة

  void onNumberPress(String num) {
    if (pin.length < 4) {
      setState(() => pin += num);
      if (pin.length == 4) {
        if (pin == correctPin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          // رمز خاطئ، تفريغ الحقل
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرمز السري خاطئ (الرمز: 1234)')),
          );
          setState(() => pin = '');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'أدخل الرمز السري',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // مؤشر الرمز السري
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < pin.length ? Colors.white : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            // لوحة الأرقام
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 1; i <= 9; i++) _buildPinButton(i.toString()),
                  _buildPinButton('fingerprint', isIcon: true),
                  _buildPinButton('0'),
                  _buildPinButton('delete', isIcon: true, onTap: () {
                    if (pin.isNotEmpty) setState(() => pin = pin.substring(0, pin.length - 1));
                  }),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPinButton(String value, {bool isIcon = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => onNumberPress(value),
      customBorder: const CircleBorder(),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Center(
          child: isIcon
              ? Icon(
                  value == 'fingerprint' ? Icons.fingerprint : Icons.backspace_outlined,
                  color: Colors.white,
                  size: 30,
                )
              : Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 2: لوحة التحكم (Dashboard)
// -----------------------------------------------------------------------------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفتر المجوهرات', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة ملخص سريعة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_graph, color: Colors.white, size: 40),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجمالي المخزون (تقريبي)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 5),
                      Text('1,250.50 غرام', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('الأقسام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            // شبكة الأقسام
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildDashCard(context, 'الزبائن', Icons.people_alt_outlined, () => _openContacts(context, true)),
                  _buildDashCard(context, 'الموردين', Icons.local_shipping_outlined, () => _openContacts(context, false)),
                  _buildDashCard(context, 'المخزون', Icons.inventory_2_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()))),
                  _buildDashCard(context, 'المذكرة', Icons.notes, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()))),
                ],
              ),
            ),
          ],
        ),
      ),
      // زر الإضافة العائم البارز
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const QuickAddModal(),
        ),
        icon: const Icon(Icons.add, size: 30),
        label: const Text('معاملة جديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDashCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _openContacts(BuildContext context, bool isCustomer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ContactsScreen(isCustomer: isCustomer)),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 3: نافذة الإضافة السريعة (Quick Add Modal)
// تتضمن حل "المعاملات المركبة"
// -----------------------------------------------------------------------------

class QuickAddModal extends StatefulWidget {
  const QuickAddModal({super.key});

  @override
  State<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends State<QuickAddModal> {
  DateTime selectedDate = DateTime.now();
  String? selectedAccount;
  // قائمة لتخزين أسطر المعاملة (الكمية والوحدة) لدعم المعاملات المركبة
  List<Map<String, dynamic>> transactionLines = [
    {'amount': '', 'unit': 'غرام'}
  ];
  final units = ['غرام', 'DZD', 'EUR', 'USD'];

  void _addTransactionLine() {
    setState(() {
      transactionLines.add({'amount': '', 'unit': 'DZD'}); // افتراضياً العملة بعد الغرام
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مقبض السحب
            Center(
              child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إضافة معاملة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text("${selectedDate.year}/${selectedDate.month}/${selectedDate.day}"),
                )
              ],
            ),
            const SizedBox(height: 15),
            // اختيار الحساب
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'اسم الزبون / المورد',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
              items: AppRepo.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
              onChanged: (val) => setState(() => selectedAccount = val),
            ),
            const SizedBox(height: 15),
            
            // أسطر المعاملة (لدعم المعاملات المركبة)
            const Text('المبلغ / الوزن', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...transactionLines.asMap().entries.map((entry) {
              int index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        onChanged: (val) => transactionLines[index]['amount'] = val,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: transactionLines[index]['unit'],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (val) => setState(() => transactionLines[index]['unit'] = val!),
                      ),
                    ),
                    if (transactionLines.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setState(() => transactionLines.removeAt(index)),
                      )
                  ],
                ),
              );
            }).toList(),
            
            // زر إضافة وحدة أخرى
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addTransactionLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة وحدة أخرى (مركب)'),
              ),
            ),
            
            const SizedBox(height: 5),
            // التفاصيل والمرفقات
            TextField(
              decoration: InputDecoration(
                labelText: 'التفاصيل (اختياري)',
                prefixIcon: const Icon(Icons.edit_note),
                suffixIcon: IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: (){}),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 25),
            
            // أزرار الإجراء
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600, // لون الأخذ
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('أخذ ⬇️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600, // لون الدفع
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('دفع ⬆️', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 4: قوائم جهات الاتصال
// -----------------------------------------------------------------------------

class ContactsScreen extends StatelessWidget {
  final bool isCustomer;
  const ContactsScreen({super.key, required this.isCustomer});

  @override
  Widget build(BuildContext context) {
    // تصفية البيانات الوهمية بناءً على نوع الشاشة
    final accounts = AppRepo.accounts.where((a) => a.isCustomer == isCustomer).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isCustomer ? 'الزبائن' : 'الموردين', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // شريط البحث الثابت
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو رقم الهاتف...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // قائمة الحسابات
          Expanded(
            child: accounts.isEmpty 
            ? const Center(child: Text('لا توجد بيانات (Empty State)', style: TextStyle(color: Colors.grey)))
            : ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final acc = accounts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(acc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(acc.phone),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // عرض رصيد الذهب
                      Text(
                        '${acc.goldBalance > 0 ? '+' : ''}${acc.goldBalance} غرام',
                        style: TextStyle(
                          color: acc.goldBalance > 0 ? Colors.green : (acc.goldBalance < 0 ? Colors.red : Colors.grey),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // عرض رصيد العملة
                      if (acc.currencyBalance != 0)
                        Text(
                          '${acc.currencyBalance > 0 ? '+' : ''}${acc.currencyBalance.toStringAsFixed(0)} DZD',
                          style: TextStyle(
                            color: acc.currencyBalance > 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CustomerProfileScreen(account: acc)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 5: ملف الزبون وسجل المعاملات
// -----------------------------------------------------------------------------

class CustomerProfileScreen extends StatelessWidget {
  final Account account;
  const CustomerProfileScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    // جلب المعاملات الوهمية لهذا الحساب
    final txs = AppRepo.transactions.where((t) => t.accountId == account.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('كشف الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // الترويسة وبطاقات الرصيد
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              children: [
                Text(account.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(account.phone, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildBalanceCard('رصيد الذهب', account.goldBalance, 'غرام')),
                    const SizedBox(width: 15),
                    Expanded(child: _buildBalanceCard('رصيد العملة', account.currencyBalance, 'DZD')),
                  ],
                ),
              ],
            ),
          ),
          
          // شريط الأدوات (الفلتر والترتيب)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('سجل المعاملات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.date_range, size: 20), onPressed: (){}),
                    IconButton(icon: const Icon(Icons.swap_vert, size: 20), onPressed: (){}),
                  ],
                )
              ],
            ),
          ),

          // شريط السجل (Timeline)
          Expanded(
            child: txs.isEmpty 
              ? const Center(child: Text('لا توجد معاملات سابقة', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return InkWell(
                      // الإجراء الإضافي عند الضغط المطول
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: const Text('مشاركة وصل العملية كصورة'),
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.black12)),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            // أيقونة نوع العملية
                            CircleAvatar(
                              backgroundColor: tx.isTake ? Colors.green.shade50 : Colors.red.shade50,
                              child: Icon(
                                tx.isTake ? Icons.arrow_downward : Icons.arrow_upward,
                                color: tx.isTake ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 15),
                            // التفاصيل
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        tx.isTake ? 'أخذ' : 'دفع',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: tx.isTake ? Colors.green : Colors.red),
                                      ),
                                      Text("${tx.date.year}/${tx.date.month}/${tx.date.day}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text('${tx.amount} ${tx.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  if (tx.details.isNotEmpty)
                                    Text(tx.details, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, String unit) {
    bool isPositive = amount >= 0;
    Color color = isPositive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            '${amount.abs().toStringAsFixed(unit == 'غرام' ? 2 : 0)}',
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tahoma'),
          ),
          Text(unit, style: TextStyle(color: color, fontSize: 12)),
          Text(isPositive ? '(لنا)' : '(علينا)', style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشات الإضافية: المخزون، المذكرة، الإعدادات
// -----------------------------------------------------------------------------

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المخزون (مبسط)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text('إجمالي الذهب المتوفر:', style: TextStyle(fontSize: 18)),
            const Text('1,250.50 غرام', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('إضافة بضاعة جديدة'),
            )
          ],
        ),
      ),
    );
  }
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المذكرة والطلبيات')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppRepo.notes.length,
        itemBuilder: (context, index) {
          final note = AppRepo.notes[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(note.content, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('تخصيص المسميات والألوان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(leading: const Icon(Icons.text_fields), title: const Text('مسميات (أخذ/دفع)'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () {}),
          ListTile(leading: const Icon(Icons.color_lens), title: const Text('عكس ألوان الدائن والمدين'), trailing: Switch(value: false, onChanged: (v){}), onTap: () {}),
          const Divider(),
          const ListTile(
            title: Text('الأمان والنسخ الاحتياطي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(leading: const Icon(Icons.lock), title: const Text('تغيير الرمز السري'), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () {}),
          ListTile(leading: const Icon(Icons.backup), title: const Text('نسخ احتياطي محلي'), onTap: () {}),
          ListTile(leading: const Icon(Icons.cloud_upload), title: const Text('الربط مع Google Drive'), onTap: () {}),
        ],
      ),
    );
  }
}
