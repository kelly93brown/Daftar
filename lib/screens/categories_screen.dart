import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class CategoriesScreen extends StatefulWidget {
  final AppState state;
  const CategoriesScreen({super.key, required this.state});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void _openAddCategoryDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة تصنيف جديد'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اسم التصنيف'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42)),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  widget.state.addCategory(ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // نافذة الخيارات (تعديل / حذف) - مطابقة للصورة 26
  void _showCategoryOptionsSheet(CategoryItem cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 14),
              const Text('خيارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
              const SizedBox(height: 16),

              // خيار التعديل
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xFF0D4E42)),
                  title: const Text('تعديل', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openEditCategoryDialog(cat);
                  },
                ),
              ),

              // خيار الحذف
              Container(
                decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.state.deleteCategory(cat.id);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditCategoryDialog(CategoryItem cat) {
    final ctrl = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل التصنيف'),
          content: TextField(controller: ctrl, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42)),
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  widget.state.updateCategory(cat.id, ctrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);
    final categories = widget.state.categories.where((c) => !c.isDeleted).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              onPressed: _openAddCategoryDialog,
            ),
          ],
        ),
        body: Column(
          children: [
            // الترويسة (مطابقة للصورة 24)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE2EFEA), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('عدد الحسابات', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 13)),
                  Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 13)),
                ],
              ),
            ),

            // قائمة التصنيفات
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (ctx, idx) {
                  final cat = categories[idx];
                  final count = widget.state.getAccountsCountForCategory(cat.name);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF1F5F4),
                        child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                      ),
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      trailing: const Icon(Icons.bookmark_border, color: primaryTeal),
                      onTap: () => _showCategoryOptionsSheet(cat),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
