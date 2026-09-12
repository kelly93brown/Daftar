import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../screens/add_account_screen.dart';
import '../screens/settings_screen.dart';

class AppSideDrawer extends StatelessWidget {
  final AppState state;
  const AppSideDrawer({super.key, required this.state});

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حفظ نسخة احتياطية'),
          content: const Text('سيتم تصدير ملف النسخة الاحتياطية وحفظه في:\nDownloads/Daftar/'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42)),
              onPressed: () async {
                Navigator.pop(ctx);
                final path = await state.exportBackup();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم حفظ النسخة بنجاح في:\n$path')),
                );
              },
              child: const Text('حفظ الآن', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) async {
    final folder = await state.getBackupFolder();
    List<FileSystemEntity> files = [];
    if (folder.existsSync()) {
      files = folder.listSync().where((f) => f.path.endsWith('.json')).toList();
    }
    
    // إذا لم تكن متوفرة في مجلد Daftar نبحث في مجلد Downloads الرئيسي
    if (files.isEmpty && Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        files = downloadDir.listSync().where((f) => f.path.endsWith('.json')).toList();
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('استرجاع نسخة احتياطية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
              const SizedBox(height: 8),
              Text(
                files.isEmpty ? 'لم يتم العثور على ملفات نسخة احتياطية في مجلد Downloads/Daftar' : 'اختر ملف النسخة الاحتياطية للاسترجاع:',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (files.isNotEmpty)
                ...files.map((file) {
                  final name = file.path.split('/').last;
                  return ListTile(
                    leading: const Icon(Icons.history, color: Color(0xFF0D4E42)),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final success = await state.restoreFromFile(File(file.path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'تم استرجاع البيانات بنجاح!' : 'فشل في استرجاع النسخة')),
                      );
                    },
                  );
                }),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(Icons.login, color: Colors.white, size: 18),
                    label: const Text('تسجيل حساب', style: TextStyle(color: Colors.white)),
                    onPressed: () => _showSnack(context, 'سيتم تفعيل ميزة مزامنة الحسابات السحابية قريباً'),
                  ),
                ],
              ),
            ),

            _sectionTitle('الإجراءات الرئيسية'),
            _drawerTile(Icons.person_add_alt, 'اضافة حساب', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(state: state)));
            }),
            _drawerTile(Icons.speed, 'سقف الحساب', () => _showSnack(context, 'ميزة تحديد سقف الدين قيد التطوير')),
            _drawerTile(Icons.alarm, 'التذكيرات', () => _showSnack(context, 'ميزة جدولة التذكيرات قيد التطوير')),
            _drawerTile(Icons.chat, 'ربط واتساب', () => _showSnack(context, 'سيتم إتاحة الربط التلقائي بـ WhatsApp قريباً'), badge: 'جديد'),
            _drawerTile(Icons.bar_chart, 'التقارير', () => _showSnack(context, 'جاري إعداد واجهة التقارير التحليلية المتقدمة')),
            const Divider(),

            _sectionTitle('إدارة البيانات'),
            _drawerTile(Icons.cloud_upload_outlined, 'حفظ نسخة احتياطية', () {
              Navigator.pop(context);
              _showBackupDialog(context);
            }),
            _drawerTile(Icons.history, 'استرجاع نسخة احتياطية', () {
              Navigator.pop(context);
              _showRestoreDialog(context);
            }),
            _drawerTile(Icons.add_to_drive, 'جوجل درايف', () => _showSnack(context, 'جاري الربط مع Google Drive...')),
            const Divider(),

            _sectionTitle('إعدادات التطبيق'),
            _drawerTile(Icons.settings_outlined, 'الاعدادات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: state)));
            }),
            _drawerTile(Icons.translate, 'اللغة', () => _showSnack(context, 'اللغة الحالية هي العربية')),
            _drawerTile(Icons.share_outlined, 'مشاركة البرنامج', () => _showSnack(context, 'شكراً لمشاركة تطبيق دفتر مع أصدقائك!')),
            _drawerTile(Icons.feedback_outlined, 'إرسال الملاحظات', () => _showSnack(context, 'جاري فتح عميل البريد الإلكتروني...')),
            _drawerTile(Icons.headset_mic_outlined, 'للتواصل والدعم الفني', () => _showSnack(context, 'سيتم تحويلك إلى فريق الدعم')),
            _drawerTile(Icons.star_outline, 'تقييم التطبيق', () => _showSnack(context, 'شكراً لتقييمك لتطبيق دفتر 5 نجوم!')),
            const SizedBox(height: 20),
            const Center(child: Text('v2.2.14', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)));
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
