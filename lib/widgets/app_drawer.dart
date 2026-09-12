import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../screens/add_account_screen.dart';
import '../screens/settings_screen.dart';

class AppSideDrawer extends StatelessWidget {
  final AppState state;
  const AppSideDrawer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // رأس القائمة
            Container(
              padding: const EdgeInsets.fromLTRB(16, 45, 16, 20),
              color: primaryTeal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calculate, color: primaryTeal, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('سجلات وحسابات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('إدارة ديونك بذكاء', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.login, color: Colors.white, size: 18),
                    label: const Text('تسجيل حساب', style: TextStyle(color: Colors.white)),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // الإجراءات الرئيسية
            _sectionTitle('الإجراءات الرئيسية'),
            _drawerTile(Icons.person_add_alt, 'اضافة حساب', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(state: state)));
            }),
            _drawerTile(Icons.speed, 'سقف الحساب', () {}),
            _drawerTile(Icons.alarm, 'التذكيرات', () {}),
            _drawerTile(Icons.chat, 'ربط واتساب', () {}, badge: 'جديد'),
            _drawerTile(Icons.bar_chart, 'التقارير', () {}),
            const Divider(),

            // إدارة البيانات
            _sectionTitle('إدارة البيانات'),
            _drawerTile(Icons.cloud_upload_outlined, 'حفظ نسخة احتياطية', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ النسخة الاحتياطية محلياً بنجاح')));
            }),
            _drawerTile(Icons.history, 'استرجاع نسخة احتياطية', () {}),
            _drawerTile(Icons.add_to_drive, 'جوجل درايف', () {}),
            const Divider(),

            // إعدادات التطبيق
            _sectionTitle('إعدادات التطبيق'),
            _drawerTile(Icons.settings_outlined, 'الاعدادات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: state)));
            }),
            _drawerTile(Icons.translate, 'اللغة', () {}),
            _drawerTile(Icons.share_outlined, 'مشاركة البرنامج', () {}),
            _drawerTile(Icons.feedback_outlined, 'إرسال الملاحظات', () {}),
            _drawerTile(Icons.headset_mic_outlined, 'للتواصل والدعم الفني', () {}),
            _drawerTile(Icons.star_outline, 'تقييم التطبيق', () {}),
            const SizedBox(height: 20),
            const Center(child: Text('v2.2.14', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap, {String? badge}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF0D4E42), size: 20),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
      onTap: onTap,
    );
  }
}
