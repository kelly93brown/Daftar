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

    // تصفية المعاملات للزبون الحالي
    List<LedgerEntry> partyEntries = state.entries
        .where((e) => e.partyId == widget.party.id && !e.isDeleted)
        .where((e) {
          if (_filterRange == null) return true;
          return e.date.isAfter(_filterRange!.start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(_filterRange!.end.add(const Duration(days: 1)));
        })
        .toList();

    partyEntries.sort((a, b) => b.date.compareTo(a.date));

    // حساب الرصيد التراكمي المنفصل سطراً بسطر لكل وحدة (ذهب / دينار)
    final Map<String, int> runningCalculators = {};
    for (var u in state.units) {
      runningCalculators[u.id] = 0;
    }
    // نحسب من الأقدم للأحدث للرصيد التراكمي
    final reversedList = partyEntries.reversed.toList();
    final Map<String, int> rowRunningBalances = {};
    for (var entry in reversedList) {
      int cur = runningCalculators[entry.unitId] ?? 0;
      if (entry.type == TransactionType.take) {
        cur -= entry.rawAmount;
      } else {
        cur += entry.rawAmount;
      }
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
                onPressed: () {
                  state.entries.removeWhere((e) => _selectedEntryIds.contains(e.id));
                  setState(() {
                    _selectedEntryIds.clear();
                    _isSelectionMode = false;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () => _openShareOptionsSheet(context),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _filterRange = picked);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // ترويسة الجدول المتطابقة مع الصورة (20)
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

            // قائمة الحركات مع تمييز التحديد المتعدد
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
                                // النقر مرة واحدة يفتح نافذة الصورة 21
                                _openTransactionDetailsSheet(context, state, entry, unit);
                              }
                            },
                            onLongPress: () {
                              // النقر المطول يفعل التحديد المتعدد كالصورة 20
                              setState(() {
                                _isSelectionMode = true;
                                _selectedEntryIds.add(entry.id);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // الرصيد الصافي التراكمي
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      state.hideBalances ? '••••' : '${unit.formatValue(running)} ${unit.symbol}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: running >= 0 ? Colors.black87 : Colors.red,
                                      ),
                                    ),
                                  ),

                                  // مؤشر السهم (مثل الصورة 20)
                                  Icon(
                                    isTake ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                                    color: isTake ? state.debitColor : state.creditColor,
                                    size: 20,
                                  ),

                                  // التفاصيل
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.note.isNotEmpty ? entry.note : '-',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // المبلغ / الوزن
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      unit.formatValue(entry.rawAmount),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isTake ? state.debitColor : state.creditColor,
                                      ),
                                    ),
                                  ),

                                  // التاريخ
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}",
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
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
        // زر + العائم لإضافة حركة مباشرة لهذا العميل
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryTeal,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => showQuickAddModal(context, state, defaultPartyId: widget.party.id),
        ),
      ),
    );
  }

  // نافذة تفاصيل المعاملة السفلية (مطابقة تماماً للصورة 21)
  void _openTransactionDetailsSheet(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency unit) {
    final isTake = entry.type == TransactionType.take;

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

              // أزرار الإجراءات الدائرية الخمسة كالصورة 21
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionCircle(Icons.edit, 'تعديل', const Color(0xFFE0F2FE), Colors.blue, () => Navigator.pop(ctx)),
                  _actionCircle(Icons.share, 'مشاركة', const Color(0xFFF1F5F4), Colors.black87, () {
                    Navigator.pop(ctx);
                    _openShareOptionsSheet(context);
                  }),
                  _actionCircle(Icons.receipt_long, 'مشاركة الفاتورة', const Color(0xFFFCE7F3), Colors.purple, () => Navigator.pop(ctx)),
                  _actionCircle(Icons.chat, 'WhatsApp', const Color(0xFFDCFCE7), Colors.green, () => Navigator.pop(ctx)),
                  _actionCircle(Icons.message, 'SMS', const Color(0xFFFFEDD5), Colors.orange, () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة خيارات المشاركة الأربعة (مطابقة للصورة 22)
  void _openShareOptionsSheet(BuildContext context) {
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
              const SizedBox(height: 12),
              const Text('مشاركة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0D4E42))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shareCircle(Icons.table_chart, 'إكسل', const Color(0xFFDCFCE7), Colors.green),
                  _shareCircle(Icons.picture_as_pdf, 'PDF', const Color(0xFFFFE4E6), Colors.red),
                  _shareCircle(Icons.article, 'نصية', const Color(0xFFE0F2FE), Colors.blue),
                  _shareCircle(Icons.receipt, 'صورة', const Color(0xFFF3E8FF), Colors.purple),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          valueWidget,
        ],
      ),
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

  Widget _shareCircle(IconData icon, String label, Color bg, Color iconColor) {
    return Column(
      children: [
        CircleAvatar(radius: 26, backgroundColor: bg, child: Icon(icon, color: iconColor, size: 24)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
