import 'package:flutter/material.dart';
import '../services/app_state.dart';
import 'categories_screen.dart';
import 'message_templates_screen.dart';
import 'pdf_settings_screen.dart';
import 'units_screen.dart';

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
              _buildTile(Icons.info_outline, 'المعلومات الشخصية', () => _showPersonalInfoSheet(context, state)),
              _buildTile(Icons.bookmark_border, 'التصنيف', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriesScreen(state: state)));
              }),
              _buildTile(Icons.currency_exchange, 'العملات والوحدات', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => UnitsScreen(state: state)));
              }),
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
              _buildTile(Icons.picture_as_pdf_outlined, '(PDF) إعدادات أعمدة التقارير', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PdfSettingsScreen(state: state)));
              }),
            ]),
            const SizedBox(height: 16),

            _buildSectionHeader('الأمان والخصوصية'),
            _buildCard([
              _buildTile(Icons.lock_outline, 'كلمة المرور', () => _showPasswordSecuritySheet(context, state)),
              _buildTile(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () => _showPrivacyPolicySheet(context)),
            ]),
            const SizedBox(height: 30),

// ثم أضف الدالة في آخر الملف قبل دالة _showBottomModal:

  void _showPrivacyPolicySheet(BuildContext context) {
    _showBottomModal(
      context,
      title: 'سياسة الخصوصية',
      child: const Text(
        'جميع بياناتك (العمليات، الحسابات، الأرصدة) يتم تخزينها محلياً ومشفّرة على جهازك ولا تتم مشاركتها مع أي طرف ثالث إطلاقاً.\n\nيلتزم تطبيق دفتر بالحفاظ على السرية والخصوصية التامة لحساباتك المالية.',
        style: TextStyle(height: 1.6, fontSize: 14),
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

  void _showPersonalInfoSheet(BuildContext context, AppState state) {
    final arCtrl = TextEditingController(text: state.storeNameAr);
    final enCtrl = TextEditingController(text: state.storeNameEn);
    final phCtrl = TextEditingController(text: state.storePhone);
    final adCtrl = TextEditingController(text: state.storeAddress);

    _showBottomModal(
      context,
      title: 'المعلومات الشخصية',
      child: Column(
        children: [
          TextField(controller: arCtrl, decoration: const InputDecoration(labelText: 'الاسم بالعربي')),
          const SizedBox(height: 8),
          TextField(controller: enCtrl, decoration: const InputDecoration(labelText: 'الاسم بالإنجليزي')),
          const SizedBox(height: 8),
          TextField(controller: phCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          const SizedBox(height: 8),
          TextField(controller: adCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
        ],
      ),
      onSave: () => state.updatePersonalInfo(arCtrl.text, enCtrl.text, phCtrl.text, adCtrl.text),
    );
  }

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
                  Text('${(tempScale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('معاينة الخط: تطبيق دفتر لإدارة ديون الصاغة بذكاء.', style: TextStyle(fontSize: 14 * tempScale)),
                ],
              ),
            ),
            Slider(
              value: tempScale,
              min: 0.8,
              max: 1.4,
              divisions: 6,
              activeColor: const Color(0xFF0D4E42),
              onChanged: (v) => setModalState(() => tempScale = v),
            ),
          ],
        );
      }),
      onSave: () => state.updateFontScale(tempScale),
    );
  }

  void _showDebitCreditColorsSheet(BuildContext context, AppState state) {
    bool tempInvert = state.invertDebitCreditColors;
    _showBottomModal(
      context,
      title: 'ألوان المدين والدائن',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return SwitchListTile(
          title: const Text('عكس ألوان المدين والدائن'),
          subtitle: const Text('عند التفعيل: المدين أخضر والدائن أحمر'),
          value: tempInvert,
          activeColor: const Color(0xFF0D4E42),
          onChanged: (v) => setModalState(() => tempInvert = v),
        );
      }),
      onSave: () => state.updateInvertColors(tempInvert),
    );
  }

  void _showThemeSheet(BuildContext context, AppState state) {
    ThemeMode temp = state.themeMode;
    _showBottomModal(
      context,
      title: 'المظهر',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Column(
          children: [
            RadioListTile<ThemeMode>(title: const Text('فاتح'), value: ThemeMode.light, groupValue: temp, onChanged: (v) => setModalState(() => temp = v!)),
            RadioListTile<ThemeMode>(title: const Text('داكن'), value: ThemeMode.dark, groupValue: temp, onChanged: (v) => setModalState(() => temp = v!)),
            RadioListTile<ThemeMode>(title: const Text('حسب النظام'), value: ThemeMode.system, groupValue: temp, onChanged: (v) => setModalState(() => temp = v!)),
          ],
        );
      }),
      onSave: () => state.updateTheme(temp),
    );
  }

  void _showTerminologySheet(BuildContext context, AppState state) {
    final takeCtrl = TextEditingController(text: state.takeLabel);
    final payCtrl = TextEditingController(text: state.payLabel);
    _showBottomModal(
      context,
      title: 'الترميز',
      child: Column(
        children: [
          TextField(controller: takeCtrl, decoration: const InputDecoration(labelText: 'تسمية المدين')),
          const SizedBox(height: 10),
          TextField(controller: payCtrl, decoration: const InputDecoration(labelText: 'تسمية الدائن')),
        ],
      ),
      onSave: () => state.updateLabels(takeCtrl.text.trim(), payCtrl.text.trim()),
    );
  }

  void _showPasswordSecuritySheet(BuildContext context, AppState state) {
    bool temp = state.isPasscodeEnabled;
    _showBottomModal(
      context,
      title: 'كلمة المرور',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return SwitchListTile(
          title: const Text('تمكين قفل التطبيق'),
          value: temp,
          onChanged: (v) => setModalState(() => temp = v),
        );
      }),
      onSave: () => state.isPasscodeEnabled = temp,
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    _showBottomModal(context, title: 'الإشعارات', child: const Text('الإشعارات مفعلة للتنبيهات وعمليات النسخ الاحتياطي.'));
  }

  void _showBalanceHomeSheet(BuildContext context, AppState state) {
    _showBottomModal(
      context,
      title: 'إظهار الرصيد',
      child: SwitchListTile(
        title: const Text('إظهار الرصيد بالصفحة الرئيسية'),
        value: !state.hideBalances,
        onChanged: (v) => state.toggleHideBalances(),
      ),
    );
  }

  void _showBackupIntervalSheet(BuildContext context, AppState state) {
    int hours = state.autoBackupHours;
    _showBottomModal(
      context,
      title: 'النسخ الاحتياطي',
      child: StatefulBuilder(builder: (ctx, setModalState) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => setModalState(() => hours = hours > 1 ? hours - 1 : 1)),
            Text('$hours ساعة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle), onPressed: () => setModalState(() => hours = hours < 99 ? hours + 1 : 99)),
          ],
        );
      }),
      onSave: () => state.autoBackupHours = hours,
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    if (onSave != null) onSave();
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
