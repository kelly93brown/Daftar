import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class UnitsScreen extends StatefulWidget {
  final AppState state;
  const UnitsScreen({super.key, required this.state});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  void _openUnitModal({UnitCurrency? existingUnit}) {
    final nameCtrl = TextEditingController(text: existingUnit?.name ?? '');
    final symbolCtrl = TextEditingController(text: existingUnit?.symbol ?? '');
    final decimalCtrl = TextEditingController(text: existingUnit != null ? '${existingUnit.decimalPlaces}' : '2');
    UnitKind kind = existingUnit?.kind ?? UnitKind.weight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(top: 16, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 12),
                  Text(existingUnit == null ? 'إضافة وحدة أو عملة' : 'تعديل الوحدة', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
                  const SizedBox(height: 14),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم (مثال: ذهب / دولار)', filled: true, fillColor: Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  TextField(controller: symbolCtrl, decoration: const InputDecoration(labelText: 'الرمز (مثال: g / USD)', filled: true, fillColor: Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  TextField(controller: decimalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد الأرقام بعد الفاصلة', filled: true, fillColor: Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: RadioListTile<UnitKind>(title: const Text('وزن ذهب'), value: UnitKind.weight, groupValue: kind, onChanged: (v) => setModalState(() => kind = v!))),
                      Expanded(child: RadioListTile<UnitKind>(title: const Text('نقد / عملة'), value: UnitKind.currency, groupValue: kind, onChanged: (v) => setModalState(() => kind = v!))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        if (nameCtrl.text.isNotEmpty && symbolCtrl.text.isNotEmpty && decimalCtrl.text.isNotEmpty) {
                          int dec = int.tryParse(decimalCtrl.text) ?? 0;
                          if (existingUnit == null) {
                            widget.state.addUnit(UnitCurrency(
                              id: UuidUtil.generate(),
                              name: nameCtrl.text.trim(),
                              symbol: symbolCtrl.text.trim(),
                              code: symbolCtrl.text.trim().toUpperCase(),
                              kind: kind,
                              decimalPlaces: dec,
                            ));
                          } else {
                            widget.state.updateUnit(existingUnit.id, nameCtrl.text.trim(), symbolCtrl.text.trim(), dec);
                          }
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(existingUnit == null ? 'إضافة' : 'حفظ التعديلات', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showUnitOptions(UnitCurrency unit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 14),
              Text(unit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF0D4E42)),
                title: const Text('تعديل الوحدة', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openUnitModal(existingUnit: unit);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف الوحدة', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.state.deleteUnit(unit.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);
    final units = widget.state.units.where((u) => !u.isDeleted).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text('العملات والوحدات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 28), onPressed: () => _openUnitModal()),
          ],
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFFE2EFEA), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('عدد الحسابات', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 12)),
                  Text('الفاصلة', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 12)),
                  Text('الرمز والاسم', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: units.length,
                itemBuilder: (ctx, idx) {
                  final u = units[idx];
                  final count = widget.state.getAccountsCountForUnit(u.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)]),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(backgroundColor: const Color(0xFFF1F5F4), child: Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryTeal))),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${u.decimalPlaces}', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              Text(u.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 8),
                              Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _showUnitOptions(u),
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
