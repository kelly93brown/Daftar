import 'dart:io';
import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../screens/add_account_screen.dart';
import '../screens/settings_screen.dart';

// دالة عرض إشعار علوي احترافي (يشبه إشعارات الهاتف المنسدلة)
void showTopNotification(BuildContext context, {required String title, required String message, IconData icon = Icons.check_circle}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: MediaQuery.of(ctx).padding.top + 8,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: -80.0, end: 0.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, val, child) => Transform.translate(
            offset: Offset(0, val),
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D4E42),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 18,
                    child: Icon(icon, color: Colors.amberAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    entry.remove();
  });
}

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
                final fileName = path.split('/').last;
                // إظهار الإشعار العلوي فور اكتمال النسخ
                showTopNotification(
                  context,
                  title: 'تم حفظ نسخة احتياطية',
                  message: 'تم حفظ الملف بنجاح: $fileName في مجلد Downloads/Daftar',
                  icon: Icons.cloud_done,
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
    if (files.isEmpty && Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        files = downloadDir.listSync().where((f) => f.path.endsWith('.json')).toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 12),
                  const Text('استرجاع نسخة احتياطية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
                  const SizedBox(height: 8),
                  Text(
                    files.isEmpty ? 'لا توجد ملفات نسخ احتياطية متوفرة.' : 'اختر النسخة المراد استعادتها أو حذفها:',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  if (files.isNotEmpty)
                    ...files.map((file) {
                      final name = file.path.split('/').last;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          leading: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF0D4E42)),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // زر الاستعادة
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D4E42),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final success = await state.restoreFromFile(File(file.path));
                                  if (success) {
                                    showTopNotification(
                                      context,
                                      title: 'تم استعادة النسخة الاحتياطية',
                                      message: 'تم تحديث واسترجاع جميع بيانات التطبيق بنجاح.',
                                      icon: Icons.restore_page,
                                    );
                                  }
                                },
                                child: const Text('استعادة', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(width: 6),
                              // زر الحذف
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (confirmCtx) => AlertDialog(
                                      title: const Text('حذف النسخة'),
                                      content: Text('هل تريد بالتأكيد حذف ملف النسخة الاحتياطية:\n$name؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(confirmCtx), child: const Text('إلغاء')),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () async {
                                            Navigator.pop(confirmCtx);
                                            await state.deleteBackupFile(File(file.path));
                                            setModalState(() {
                                              files.removeWhere((f) => f.path == file.path);
                                            });
                                          },
                                          child: const Text('حذف', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
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
                ],
              ),
            ),

            _sectionTitle('الإجراءات الرئيسية'),
            _drawerTile(Icons.person_add_alt, 'اضافة حساب', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddAccountScreen(state: state)));
            }),
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
            const Divider(),

            _sectionTitle('إعدادات التطبيق'),
            _drawerTile(Icons.settings_outlined, 'الاعدادات', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(state: state)));
            }),
            const SizedBox(height: 20),
            const Center(child: Text('v2.2.14', style: TextStyle(color: Colors.grey, fontSize: 12))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
