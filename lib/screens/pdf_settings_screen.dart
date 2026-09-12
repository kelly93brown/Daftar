import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class PdfSettingsScreen extends StatefulWidget {
  final AppState state;
  const PdfSettingsScreen({super.key, required this.state});

  @override
  State<PdfSettingsScreen> createState() => _PdfSettingsScreenState();
}

class _PdfSettingsScreenState extends State<PdfSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final columns = widget.state.pdfColumns;
    const primaryTeal = Color(0xFF0D4E42);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text('(PDF) إعدادات أعمدة التقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // بطاقة المعاينة المباشرة للجدول
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('معاينة مباشرة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('PDF A4', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: columns.where((c) => c.isVisible).map((c) {
                          return Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(c.title.split(' ')[0], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                      TableRow(
                        children: columns.where((c) => c.isVisible).map((c) {
                          String sample = c.id == 'date' ? '2026-08-30' : (c.id == 'balance' ? '5,000' : 'بيان');
                          return Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(sample, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // تلميح الاستخدام
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اسحب لإعادة الترتيب، واضغط على المفتاح لإظهار أو إخفاء الحقل',
                      style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // قائمة السحب والترتيب (Reorderable List)
            Expanded(
              child: ReorderableListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = columns.removeAt(oldIndex);
                    columns.insert(newIndex, item);
                  });
                },
                children: [
                  for (int index = 0; index < columns.length; index++)
                    Container(
                      key: ValueKey(columns[index].id),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
                      ),
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.drag_indicator, color: Colors.grey),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey.shade200,
                              child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                          ],
                        ),
                        title: Text(columns[index].title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        trailing: Switch(
                          value: columns[index].isVisible,
                          activeColor: primaryTeal,
                          onChanged: (val) {
                            setState(() => columns[index].isVisible = val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
