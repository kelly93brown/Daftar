import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

void showQuickAddModal(BuildContext context, AppState state) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: QuickAddModalContent(state: state),
    ),
  );
}

class QuickAddModalContent extends StatefulWidget {
  final AppState state;
  const QuickAddModalContent({super.key, required this.state});

  @override
  State<QuickAddModalContent> createState() => _QuickAddModalContentState();
}

class _QuickAddModalContentState extends State<QuickAddModalContent> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedPartyId;
  late String _primaryUnitId;
  String? _secondaryUnitId;
  bool _isComposite = false;

  final TextEditingController _primaryAmountCtrl = TextEditingController();
  final TextEditingController _secondaryAmountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.state.parties.isNotEmpty) {
      _selectedPartyId = widget.state.parties.first.id;
    }
    _primaryUnitId = widget.state.units.first.id;
    if (widget.state.units.length > 1) {
      _secondaryUnitId = widget.state.units[1].id;
    }
  }

  @override
  void dispose() {
    _primaryAmountCtrl.dispose();
    _secondaryAmountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit(TransactionType type) {
    if (_selectedPartyId == null) return;

    final primaryUnit = widget.state.units.firstWhere((u) => u.id == _primaryUnitId);
    final primaryRaw = primaryUnit.parseInput(_primaryAmountCtrl.text);

    if (primaryRaw <= 0 && !_isComposite) return;

    final compositeId = _isComposite ? UuidUtil.generate() : null;
    final List<LedgerEntry> entries = [];

    if (primaryRaw > 0) {
      entries.add(
        LedgerEntry(
          id: UuidUtil.generate(),
          compositeGroupId: compositeId,
          partyId: _selectedPartyId!,
          unitId: _primaryUnitId,
          rawAmount: primaryRaw,
          type: type,
          date: _selectedDate,
          note: _noteCtrl.text.trim(),
        ),
      );
    }

    if (_isComposite && _secondaryUnitId != null) {
      final secUnit = widget.state.units.firstWhere((u) => u.id == _secondaryUnitId);
      final secRaw = secUnit.parseInput(_secondaryAmountCtrl.text);
      if (secRaw > 0) {
        entries.add(
          LedgerEntry(
            id: UuidUtil.generate(),
            compositeGroupId: compositeId,
            partyId: _selectedPartyId!,
            unitId: _secondaryUnitId!,
            rawAmount: secRaw,
            type: type,
            date: _selectedDate,
            note: _noteCtrl.text.trim(),
          ),
        );
      }
    }

    if (entries.isNotEmpty) {
      widget.state.addTransactions(entries);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final primaryUnit = state.units.firstWhere((u) => u.id == _primaryUnitId);
    final isPrimaryWeight = primaryUnit.kind == UnitKind.weight;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مؤشر السحب
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 12),
            const Text(
              'إضافة معاملة سريعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42)),
            ),
            const SizedBox(height: 16),

            // منتقي التاريخ والطرف
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPartyId,
                    decoration: InputDecoration(
                      labelText: 'اسم الزبون / المورد',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: state.parties.where((p) => !p.isDeleted).map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPartyId = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0D4E42)),
                          const SizedBox(height: 4),
                          Text(
                            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // الحقل الأساسي (التسمية الديناميكية: الوزن / المبلغ)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _primaryAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isPrimaryWeight ? 'الوزن (${primaryUnit.symbol})' : 'المبلغ (${primaryUnit.symbol})',
                      hintText: isPrimaryWeight ? 'مثال: 12.450' : 'مثال: 50000',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _primaryUnitId,
                    decoration: InputDecoration(
                      labelText: 'الوحدة',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: state.units.where((u) => !u.isDeleted).map((u) {
                      return DropdownMenuItem(value: u.id, child: Text(u.symbol));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _primaryUnitId = val);
                    },
                  ),
                ),
              ],
            ),

            // زر المعاملة المركبة (Progressive Disclosure)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(_isComposite ? Icons.close : Icons.add_circle_outline, size: 18),
                label: Text(
                  _isComposite ? 'إلغاء المعاملة المركبة' : '+ إضافة وحدة أخرى (معاملة مركبة)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => setState(() => _isComposite = !_isComposite),
              ),
            ),

            // سطر المعاملة المركبة عند التفعيل
            if (_isComposite) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _secondaryAmountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ / الوزن الإضافي',
                        filled: true,
                        fillColor: const Color(0xFFFFF9E6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _secondaryUnitId,
                      decoration: InputDecoration(
                        labelText: 'الوحدة 2',
                        filled: true,
                        fillColor: const Color(0xFFFFF9E6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: state.units.where((u) => !u.isDeleted).map((u) {
                        return DropdownMenuItem(value: u.id, child: Text(u.symbol));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _secondaryUnitId = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // حقل التفاصيل وأيقونة الكاميرا
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      hintText: 'التفاصيل أو البيان (مثال: دفعة خاتم 3 غرام)',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0D4E42)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تفعيل الكاميرا لإرفاق صورة السند/القطعة')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),

            // زرا الإجراءين الكبيرين (أخذ ⬇️ / دفع ⬆️)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.debitColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.arrow_downward, color: Colors.white),
                    label: Text(
                      '${state.takeLabel} (مدين/عليه)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () => _submit(TransactionType.take),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.creditColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    label: Text(
                      '${state.payLabel} (دائن/له)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () => _submit(TransactionType.pay),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
