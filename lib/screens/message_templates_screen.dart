import 'package:flutter/material.dart';
import '../services/app_state.dart';

class MessageTemplatesScreen extends StatefulWidget {
  final AppState state;
  final bool isMultiple;

  const MessageTemplatesScreen({super.key, required this.state, required this.isMultiple});

  @override
  State<MessageTemplatesScreen> createState() => _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState extends State<MessageTemplatesScreen> {
  late TextEditingController _templateCtrl;

  @override
  void initState() {
    super.initState();
    _templateCtrl = TextEditingController(
      text: widget.isMultiple ? widget.state.multipleMessageTemplate : widget.state.singleMessageTemplate,
    );
  }

  @override
  void dispose() {
    _templateCtrl.dispose();
    super.dispose();
  }

  void _insertChip(String tag) {
    final text = _templateCtrl.text;
    final selection = _templateCtrl.selection;
    final newText = selection.isValid
        ? text.replaceRange(selection.start, selection.end, tag)
        : '$text $tag';
    _templateCtrl.text = newText;
    _templateCtrl.selection = TextSelection.collapsed(offset: _templateCtrl.text.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);
    final chips = [
      {'tag': '{customer}', 'label': 'اسم العميل', 'color': Colors.blue},
      {'tag': '{amount}', 'label': 'المبلغ', 'color': Colors.green},
      {'tag': '{currency}', 'label': 'العملة/الوحدة', 'color': Colors.amber},
      {'tag': '{type}', 'label': 'نوع العملية', 'color': Colors.purple},
      {'tag': '{total}', 'label': 'الرصيد الإجمالي', 'color': Colors.indigo},
      {'tag': '{date}', 'label': 'التاريخ', 'color': Colors.teal},
      {'tag': '{note}', 'label': 'التفاصيل', 'color': Colors.brown},
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: Text(
            widget.isMultiple ? 'قالب الرسائل المتعددة' : 'قالب الرسالة',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك النقر على المتغيرات أدناه لإدراجها تلقائياً داخل قالب رسالة المشاركة.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0369A1), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                ),
                child: TextField(
                  controller: _templateCtrl,
                  maxLines: 7,
                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'اكتب نص القالب هنا...'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اضغط على المتغير لإضافته:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips.map((c) {
                  return ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: (c['color'] as MaterialColor).shade300),
                    label: Text(
                      '${c['label']} ${c['tag']}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c['color'] as Color),
                    ),
                    onPressed: () => _insertChip(c['tag'] as String),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (widget.isMultiple) {
                          widget.state.multipleMessageTemplate = _templateCtrl.text;
                        } else {
                          widget.state.singleMessageTemplate = _templateCtrl.text;
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        _templateCtrl.text = widget.isMultiple
                            ? "العميل: {customer}\nالعمليات:\n{items}\nالرصيد الإجمالي: {total} {currency}"
                            : "العميل: {customer}\n{type}: {amount} {currency}\n{note}\nالاجمالي: {total} {currency}\nالتاريخ: {date}";
                      });
                    },
                    child: const Text('تلقائي', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
