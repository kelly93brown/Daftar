import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'quick_add_dialog.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final AppState state;
  final AccountParty party;

  const CustomerLedgerScreen({super.key, required this.state, required this.party});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  DateTimeRange? _filterRange;
  final Set<String> _selectedEntryIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const primaryTeal = Color(0xFF0D4E42);

    List<LedgerEntry> partyEntries = state.entries
        .where((e) => e.partyId == widget.party.id && !e.isDeleted)
        .where((e) {
          if (_filterRange == null) return true;
          return e.date.isAfter(_filterRange!.start.subtract(const Duration(days: 1))) &&
                 e.date.isBefore(_filterRange!.end.add(const Duration(days: 1)));
        }).toList();

    partyEntries.sort((a, b) => b.date.compareTo(a.date));

    final Map<String, int> runningCalculators = {};
    for (var u in state.units) runningCalculators[u.id] = 0;
    
    final reversedList = partyEntries.reversed.toList();
    final Map<String, int> rowRunningBalances = {};
    for (var entry in reversedList) {
      int cur = runningCalculators[entry.unitId] ?? 0;
      cur += entry.type == TransactionType.take ? -entry.rawAmount : entry.rawAmount;
      runningCalculators[entry.unitId] = cur;
      rowRunningBalances[entry.id] = cur;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _showMultiDeleteConfirmation(context, state, _selectedEntryIds.toList()),
              )
            else ...[
              IconButton(icon: const Icon(Icons.edit_note, color: Colors.white), onPressed: () => _openEditPartySheet(context, state)),
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => _openShareOptionsSheet(context)),
              IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                onPressed: () async {
                  final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (picked != null) setState(() => _filterRange = picked);
                },
              ),
            ]
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: primaryTeal,
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('الرصيد', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  SizedBox(width: 24),
                  Expanded(flex: 2, child: Text('التفاصيل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text('المبلغ/الوزن', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text('تاريخ ↓', textAlign: TextAlign.left, style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            ),
            Expanded(
              child: partyEntries.isEmpty
                  ? const Center(child: Text('لا توجد حركات مسجلة لهذا الحساب'))
                  : ListView.builder(
                      itemCount: partyEntries.length,
                      itemBuilder: (ctx, i) {
                        final entry = partyEntries[i];
                        final unit = state.units.firstWhere((u) => u.id == entry.unitId, orElse: () => state.units.first);
                        final running = rowRunningBalances[entry.id] ?? 0;
                        final isSelected = _selectedEntryIds.contains(entry.id);
                        final isTake = entry.type == TransactionType.take;

                        return Container(
                          color: isSelected ? const Color(0xFFD6E4E2) : (i % 2 == 0 ? Colors.white : const Color(0xFFFAFCFC)),
                          child: InkWell(
                            onTap: () {
                              if (_isSelectionMode) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedEntryIds.remove(entry.id);
                                    if (_selectedEntryIds.isEmpty) _isSelectionMode = false;
                                  } else {
                                    _selectedEntryIds.add(entry.id);
                                  }
                                });
                              } else {
                                _openTransactionDetailsSheet(context, state, entry, unit);
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedEntryIds.add(entry.id);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      state.hideBalances ? '••••' : '${unit.formatValue(running)} ${unit.symbol}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: running >= 0 ? Colors.black87 : Colors.red),
                                    ),
                                  ),
                                  Icon(isTake ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: isTake ? state.debitColor : state.creditColor, size: 20),
                                  Expanded(flex: 2, child: Text(entry.note.isNotEmpty ? entry.note : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  Expanded(
                                    flex: 2,
                                    child: Text(unit.formatValue(entry.rawAmount), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTake ? state.debitColor : state.creditColor)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text("${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}", textAlign: TextAlign.left, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryTeal,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => showQuickAddModal(context, state, defaultPartyId: widget.party.id),
        ),
      ),
    );
  }

  void _openTransactionDetailsSheet(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency unit) {
    final isTake = entry.type == TransactionType.take;

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
              Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D4E42))),
              const Divider(),
              const SizedBox(height: 8),

              _detailRow('المبلغ', Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(unit.formatValue(entry.rawAmount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isTake ? state.debitColor : state.creditColor)),
                  Icon(isTake ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: isTake ? state.debitColor : state.creditColor),
                ],
              )),
              _detailRow('العملة', Text(unit.symbol, style: const TextStyle(fontWeight: FontWeight.bold))),
              _detailRow('الوقت', Text("${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}")),
              _detailRow('تاريخ', Text("${entry.date.year}-${entry.date.month}-${entry.date.day}")),
              _detailRow('التفاصيل', Text(entry.note.isNotEmpty ? entry.note : '-')),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionCircle(Icons.edit, 'تعديل', const Color(0xFFE0F2FE), Colors.blue, () {
                    Navigator.pop(ctx);
                    _openEditTransactionSheet(context, state, entry, unit);
                  }),
                  _actionCircle(Icons.share, 'مشاركة', const Color(0xFFF1F5F4), Colors.black87, () {
                    Navigator.pop(ctx);
                    _openShareOptionsSheet(context);
                  }),
                  _actionCircle(Icons.receipt_long, 'فاتورة', const Color(0xFFFCE7F3), Colors.purple, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري تجهيز الفاتورة...')));
                  }),
                  _actionCircle(Icons.chat, 'WhatsApp', const Color(0xFFDCFCE7), Colors.green, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الربط مع واتساب جاري...')));
                  }),
                  _actionCircle(Icons.message, 'SMS', const Color(0xFFFFEDD5), Colors.orange, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم فتح الرسائل القصيرة')));
                  }),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditTransactionSheet(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency unit) {
    final amountCtrl = TextEditingController(text: unit.formatValue(entry.rawAmount));
    final noteCtrl = TextEditingController(text: entry.note);
    TransactionType currentType = entry.type;
    DateTime currentDate = entry.date;

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
                  const Text('تعديل العملية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'المبلغ / الوزن (${unit.symbol})', filled: true, fillColor: const Color(0xFFF6F8F8)),
                  ),
                  const SizedBox(height: 10),
                  
                  TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'التفاصيل', filled: true, fillColor: const Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: Text(state.takeLabel),
                          value: TransactionType.take,
                          groupValue: currentType,
                          onChanged: (v) => setModalState(() => currentType = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: Text(state.payLabel),
                          value: TransactionType.pay,
                          groupValue: currentType,
                          onChanged: (v) => setModalState(() => currentType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: currentDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setModalState(() => currentDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF0D4E42)),
                          const SizedBox(width: 8),
                          Text("${currentDate.year}-${currentDate.month}-${currentDate.day}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            state.deleteTransaction(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العملية بنجاح')));
                          },
                          child: const Text('حذف العملية', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            final rawAmount = unit.parseInput(amountCtrl.text);
                            if (rawAmount > 0) {
                              state.updateTransaction(entry.id, rawAmount, currentDate, noteCtrl.text.trim(), currentType);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات')));
                            }
                          },
                          child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditPartySheet(BuildContext context, AppState state) {
    final nameCtrl = TextEditingController(text: widget.party.name);
    final phoneCtrl = TextEditingController(text: widget.party.phone);
    String selectedCategory = widget.party.category;

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
                  const Text('إعدادات الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
                  const SizedBox(height: 16),
                  
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الحساب', filled: true, fillColor: Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف', filled: true, fillColor: Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  
                  DropdownButtonFormField<String>(
                    value: state.categories.any((c) => c.name == selectedCategory) ? selectedCategory : null,
                    decoration: const InputDecoration(labelText: 'التصنيف', filled: true, fillColor: Color(0xFFF6F8F8)),
                    items: state.categories.where((c) => !c.isDeleted).map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => selectedCategory = val); },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showDeletePartyConfirmation(context, state);
                          },
                          child: const Text('حذف الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            if (nameCtrl.text.isNotEmpty) {
                              state.updateParty(widget.party.id, nameCtrl.text.trim(), phoneCtrl.text.trim(), selectedCategory);
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل الحساب')));
                            }
                          },
                          child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeletePartyConfirmation(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الحساب "${widget.party.name}"؟ سيتم إخفاء جميع عملياته المرتبطة.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                state.deleteParty(widget.party.id);
                Navigator.pop(ctx);
                Navigator.pop(context); // العودة للصفحة الرئيسية
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الحساب')));
              },
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiDeleteConfirmation(BuildContext context, AppState state, List<String> ids) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف ${ids.length} عملية؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                for (var id in ids) state.deleteTransaction(id);
                setState(() {
                  _selectedEntryIds.clear();
                  _isSelectionMode = false;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العمليات بنجاح')));
              },
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _openShareOptionsSheet(BuildContext context) {
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
              const SizedBox(height: 12),
              const Text('مشاركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0D4E42))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shareCircle(context, Icons.table_chart, 'إكسل', const Color(0xFFDCFCE7), Colors.green),
                  _shareCircle(context, Icons.picture_as_pdf, 'PDF', const Color(0xFFFFE4E6), Colors.red),
                  _shareCircle(context, Icons.article, 'نصية', const Color(0xFFE0F2FE), Colors.blue),
                  _shareCircle(context, Icons.receipt, 'صورة', const Color(0xFFF3E8FF), Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)), valueWidget]),
    );
  }

  Widget _actionCircle(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 22, backgroundColor: bg, child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _shareCircle(BuildContext context, IconData icon, String label, Color bg, Color iconColor) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('جاري التصدير بصيغة $label...')));
      },
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundColor: bg, child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
