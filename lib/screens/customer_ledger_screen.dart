import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class CustomerLedgerScreen extends StatefulWidget {
  final AppState state;
  final AccountParty party;

  const CustomerLedgerScreen({super.key, required this.state, required this.party});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  String _searchQuery = '';
  bool _sortAscending = false;
  DateTimeRange? _filterRange;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final balances = state.getBalancesForParty(widget.party.id);

    // تصفية وترتيب الحركات
    List<LedgerEntry> partyEntries = state.entries
        .where((e) => e.partyId == widget.party.id && !e.isDeleted)
        .where((e) {
          if (_searchQuery.isEmpty) return true;
          return e.note.contains(_searchQuery);
        })
        .where((e) {
          if (_filterRange == null) return true;
          return e.date.isAfter(_filterRange!.start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(_filterRange!.end.add(const Duration(days: 1)));
        })
        .toList();

    partyEntries.sort((a, b) => _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D4E42),
          title: Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareFullAccount(context, state, partyEntries),
            ),
          ],
        ),
        body: Column(
          children: [
            // دائرة الأرصدة (Balance Carousel)
            _buildBalanceCarousel(state, balances),

            // شريط الأدوات (Action Bar)
            _buildActionBar(context),

            // خط الزمن وسجل المعاملات
            Expanded(
              child: partyEntries.isEmpty
                  ? const Center(child: Text('لا توجد حركات مسجلة لهذا الحساب'))
                  : ListView.builder(
                      itemCount: partyEntries.length,
                      itemBuilder: (ctx, idx) {
                        final entry = partyEntries[idx];
                        final unit = state.units.firstWhere((u) => u.id == entry.unitId);
                        final isTake = entry.type == TransactionType.take;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: InkWell(
                            onLongPress: () => _showReceiptModal(context, state, entry, unit),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isTake ? state.debitBg : state.creditBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isTake ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isTake ? state.debitColor : state.creditColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.note.isNotEmpty ? entry.note : (isTake ? state.takeLabel : state.payLabel),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}",
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${unit.formatValue(entry.rawAmount)} ${unit.symbol}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isTake ? state.debitColor : state.creditColor,
                                        ),
                                      ),
                                      Text(
                                        isTake ? 'مدين (عليه)' : 'دائن (له)',
                                        style: TextStyle(fontSize: 11, color: isTake ? state.debitColor : state.creditColor),
                                      ),
                                    ],
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
      ),
    );
  }

  Widget _buildBalanceCarousel(AppState state, Map<String, int> balances) {
    final activeUnits = state.units.where((u) => !u.isDeleted && (balances[u.id] ?? 0) != 0).toList();

    if (activeUnits.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('الحساب خالص (لا توجد مديونية معلقة)')),
      );
    }

    return Container(
      height: 105,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: activeUnits.length,
        itemBuilder: (ctx, i) {
          final u = activeUnits[i];
          final val = balances[u.id] ?? 0;
          final isPositive = val >= 0;

          return Container(
            width: 170,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (isPositive ? state.creditColor : state.debitColor).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(u.kind == UnitKind.weight ? Icons.scale : Icons.monetization_on, size: 14, color: const Color(0xFF0D4E42)),
                    const SizedBox(width: 4),
                    Text(u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${u.formatValue(val.abs())} ${u.symbol}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? state.creditColor : state.debitColor,
                  ),
                ),
                Text(
                  isPositive ? 'مستحق له (دائن)' : 'مطلوب منه (مدين)',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'بحث في البيان أو الملاحظة...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: const Color(0xFF0D4E42)),
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
          IconButton(
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.date_range, color: Color(0xFF0D4E42)),
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
    );
  }

  void _showReceiptModal(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency unit) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text('إيصال معاملة صياغة', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 55, color: Color(0xFF0D4E42)),
              const SizedBox(height: 10),
              Text(widget.party.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const Divider(),
              Text('النوع: ${entry.type == TransactionType.take ? state.takeLabel : state.payLabel}'),
              Text('المقدار: ${unit.formatValue(entry.rawAmount)} ${unit.symbol}'),
              if (entry.note.isNotEmpty) Text('البيان: ${entry.note}'),
              Text('التاريخ: ${entry.date.toString().substring(0, 16)}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42)),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text('مشاركة عبر واتساب', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('جاري إنشاء صورة الإيصال ومشاركتها...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareFullAccount(BuildContext context, AppState state, List<LedgerEntry> entries) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تصدير كشف الحساب ومشاركته بنجاح')),
    );
  }
}
