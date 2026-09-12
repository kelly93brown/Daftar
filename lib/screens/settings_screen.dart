import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'message_templates_screen.dart';
import 'pdf_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const primaryTeal = Color(0xFF0D4E42);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _buildSectionHeader('المعلومات الشخصية'),
            _buildCard([
              _buildTile(Icons.info_outline, 'المعلومات الشخصية', () => _showPersonalInfoSheet(context)),
              _buildTile(Icons.bookmark_border, 'التصنيف', () => _showCategoriesSheet(context)),
              _buildTile(Icons.currency_exchange, 'العملات والوحدات', () => _showUnitsSheet(context, state)),
              _buildTile(Icons.code, 'الترميز', () => _showTerminologySheet(context, state)),
            ]),
            const SizedBox(height: 16),

            _buildSectionHeader('إعدادات التطبيق'),
            _buildCard([
              _buildTile(Icons.dark_mode_outlined, 'المظهر', () => _showThemeSheet(context, state)),
              _buildTile(Icons.notifications_none, 'الإشعارات', () => _showNotificationsSheet(context)),
              _buildTile(Icons.text_fields, 'حجم الخط', () => _showFontSizeSheet(context, state)),
              _buildTile(Icons.palette_outlined, 'ألوان المدين والدائن', () => _showDebitCreditColorsSheet(context, state)),
              _buildTile(Icons.account_balance_wallet_outlined, 'إظهار الرصيد في الصفحة الرئيسية', () => _showBalanceHomeSheet(context, state)),
              _buildTile(Icons.access_time, 'وقت نسخ البيانات الى الجهاز', () => _showBackupIntervalSheet(context, state)),
            ]),
            const SizedBox(height: 16),

            _buildSectionHeader('المشاركة والطباعة'),
            _buildCard([
              _buildTile(Icons.chat_outlined, 'قالب الرسالة', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MessageTemplatesScreen(state: state, isMultiple: false)));
              }),
              _buildTile(Icons.mark_chat_unread_outlined, 'قالب الرسائل المتعددة', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => MessageTemplatesScreen(state: state, isMultiple: true)));
              }),
              _buildTile(Icons.print_outlined, 'إعدادات الطباعة', () => _showPrintSettingsSheet(context, state)),
              _buildTile(Icons.picture_as_pdf_outlined, '(PDF) إعدادات أعمدة التقارير', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PdfSettingsScreen(state: state)));
              }),
            ]),
            const SizedBox(height: 16),

            _buildSectionHeader('الأمان والخصوصية'),
            _buildCard([
              _buildTile(Icons.lock_outline, 'كلمة المرور', () => _showPasswordSecuritySheet(context, state)),
              _buildTile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () {}),
            ]),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i < children.length - 1) Divider(height: 1, color: Colors.grey.shade100, indent: 50),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F4), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0D4E42), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // نافذة المعلومات الشخصية (مطابقة لـ input_file_17.jpeg)
  void _showPersonalInfoSheet(BuildContext context) {
    _showBottomModal(
      context,
      title: 'المعلومات الشخصية',
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFF0FDF4),
            child: Icon(Icons.camera_alt, color: const Color(0xFF0D4E42), size: 30),
          ),
          const SizedBox(height: 16),
          _buildInput('الاسم بالعربي', 'مجوهرات البركة'),
          const SizedBox(height: 10),
          _buildInput('الاسم بالإنجليزي', 'Al Baraka Jewelry'),
          const SizedBox(height: 10),
          _buildInput('رقم الهاتف', '0550000000'),
          const SizedBox(height: 10),
          _buildInput('العنوان بالعربي', 'سوق الذهب المركزي'),
        ],
      ),
    );
  }

  // نافذة حجم الخط (مطابقة لـ input_file_11.jpeg)
  void _showFontSizeSheet(BuildContext context, AppState state) {
    double tempScale = state.fontScale;
    _showBottomModal(
      context,
      title: 'حجم الخط',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('معاينة حجم الخط'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0D4E42), borderRadius: BorderRadius.circular(8)),
                        child: Text('${(tempScale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'معاينة النص: تطبيق دفتر لإدارة الأموال والديون بسهولة ويسر.',
                    style: TextStyle(fontSize: 14 * tempScale, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: tempScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              activeColor: const Color(0xFF0D4E42),
              onChanged: (v) => setModalState(() => tempScale = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [Text('80%'), Text('100%'), Text('140%')],
            ),
          ],
        );
      }),
      onSave: () => state.updateFontScale(tempScale),
    );
  }

  // نافذة ألوان المدين والدائن (مطابقة لـ input_file_10.jpeg)
  void _showDebitCreditColorsSheet(BuildContext context, AppState state) {
    bool tempInvert = state.invertDebitCreditColors;
    _showBottomModal(
      context,
      title: 'ألوان المدين والدائن',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _colorPreviewBox('مدين', tempInvert ? Colors.green : Colors.red, tempInvert ? Colors.green.shade50 : Colors.red.shade50),
                _colorPreviewBox('دائن', tempInvert ? Colors.red : Colors.green, tempInvert ? Colors.red.shade50 : Colors.green.shade50),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('عكس ألوان المدين والدائن', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('عند التفعيل: المدين أخضر والدائن أحمر. الافتراضي: المدين أحمر والدائن أخضر.'),
              value: tempInvert,
              activeColor: const Color(0xFF0D4E42),
              onChanged: (v) => setModalState(() => tempInvert = v),
            ),
          ],
        );
      }),
      onSave: () => state.updateInvertColors(tempInvert),
    );
  }

  Widget _colorPreviewBox(String title, Color color, Color bg) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Column(
        children: [
          Icon(title == 'دائن' ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color, size: 30),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // نافذة المظهر (مطابقة لـ input_file_13.jpeg)
  void _showThemeSheet(BuildContext context, AppState state) {
    ThemeMode temp = state.themeMode;
    _showBottomModal(
      context,
      title: 'المظهر',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('الوضع الفاتح'),
              value: ThemeMode.light,
              groupValue: temp,
              onChanged: (v) => setModalState(() => temp = v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('الوضع الداكن'),
              value: ThemeMode.dark,
              groupValue: temp,
              onChanged: (v) => setModalState(() => temp = v!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي (حسب النظام)'),
              value: ThemeMode.system,
              groupValue: temp,
              onChanged: (v) => setModalState(() => temp = v!),
            ),
          ],
        );
      }),
      onSave: () => state.updateTheme(temp),
    );
  }

  // نافذة الترميز (مطابقة لـ input_file_14.jpeg)
  void _showTerminologySheet(BuildContext context, AppState state) {
    final takeCtrl = TextEditingController(text: state.takeLabel);
    final payCtrl = TextEditingController(text: state.payLabel);
    _showBottomModal(
      context,
      title: 'الترميز',
      child: Column(
        children: [
          TextField(controller: takeCtrl, decoration: const InputDecoration(labelText: 'تسمية المدين (أخذ / عليه)')),
          const SizedBox(height: 10),
          TextField(controller: payCtrl, decoration: const InputDecoration(labelText: 'تسمية الدائن (دفع / له)')),
        ],
      ),
      onSave: () => state.updateLabels(takeCtrl.text.trim(), payCtrl.text.trim()),
    );
  }

  // نافذة كلمة المرور (مطابقة لـ input_file_3.jpeg)
  void _showPasswordSecuritySheet(BuildContext context, AppState state) {
    bool tempPass = state.isPasscodeEnabled;
    bool tempBio = state.isBiometricEnabled;
    _showBottomModal(
      context,
      title: 'تمكين كلمة المرور',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('تمكين كلمة المرور'),
              secondary: const Icon(Icons.security),
              value: tempPass,
              onChanged: (v) => setModalState(() => tempPass = v),
            ),
            SwitchListTile(
              title: const Text('تمكين البصمة'),
              secondary: const Icon(Icons.fingerprint),
              value: tempBio,
              onChanged: (v) => setModalState(() => tempBio = v),
            ),
          ],
        );
      }),
      onSave: () {
        state.isPasscodeEnabled = tempPass;
        state.isBiometricEnabled = tempBio;
      },
    );
  }

  // نافذة وقت النسخ الاحتياطي (مطابقة لـ input_file_8.jpeg)
  void _showBackupIntervalSheet(BuildContext context, AppState state) {
    int hours = state.autoBackupHours;
    _showBottomModal(
      context,
      title: 'وقت نسخ البيانات الى الجهاز',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('تمكين النسخ التلقائي'),
              value: state.autoBackupEnabled,
              onChanged: (v) => setModalState(() => state.autoBackupEnabled = v),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, size: 36, color: Color(0xFF0D4E42)),
                  onPressed: () => setModalState(() => hours = (hours > 1) ? hours - 1 : 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('$hours ساعة', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 36, color: Color(0xFF0D4E42)),
                  onPressed: () => setModalState(() => hours = (hours < 99) ? hours + 1 : 99),
                ),
              ],
            ),
          ],
        );
      }),
      onSave: () => state.autoBackupHours = hours,
    );
  }

  void _showUnitsSheet(BuildContext context, AppState state) {
    _showBottomModal(
      context,
      title: 'الوحدات والعملات',
      child: Column(
        children: state.units.where((u) => !u.isDeleted).map((u) {
          return ListTile(
            leading: CircleAvatar(child: Text(u.symbol)),
            title: Text(u.name),
            subtitle: Text(u.kind == UnitKind.weight ? 'وزن (دقة: ${u.decimalPlaces})' : 'عملة نقدية'),
          );
        }).toList(),
      ),
    );
  }

  void _showCategoriesSheet(BuildContext context) {
    _showBottomModal(
      context,
      title: 'التصنيف',
      child: Column(
        children: const [
          ListTile(leading: Icon(Icons.folder), title: Text('عام')),
          ListTile(leading: Icon(Icons.people), title: Text('عملاء')),
          ListTile(leading: Icon(Icons.store), title: Text('موردين وورش')),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    _showBottomModal(
      context,
      title: 'الإشعارات',
      child: SwitchListTile(
        title: const Text('تمكين الإشعارات والتنبيهات'),
        value: true,
        onChanged: (v) {},
      ),
    );
  }

  void _showBalanceHomeSheet(BuildContext context, AppState state) {
    _showBottomModal(
      context,
      title: 'إظهار الرصيد في الصفحة الرئيسية',
      child: SwitchListTile(
        title: const Text('إظهار الرصيد العام'),
        value: !state.hideBalances,
        onChanged: (v) => state.toggleHideBalances(),
      ),
    );
  }

  void _showPrintSettingsSheet(BuildContext context, AppState state) {
    _showBottomModal(
      context,
      title: 'إعدادات الطباعة',
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('إخفاء المعلومات عند الطباعة'),
            value: state.printHideInfo,
            onChanged: (v) => state.printHideInfo = v,
          ),
          SwitchListTile(
            title: const Text('عرض الوقت'),
            value: state.printShowTime,
            onChanged: (v) => state.printShowTime = v,
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, String initial) {
    return TextField(
      controller: TextEditingController(text: initial),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6F8F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _showBottomModal(BuildContext context, {required String title, required Widget child, VoidCallback? onSave}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.only(top: 12, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4E42),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (onSave != null) onSave();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
