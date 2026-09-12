import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';

void showQuickAddModal(BuildContext context, AppState state, {String? defaultPartyId}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: QuickAddModalContent(state: state, preselectedPartyId: defaultPartyId),
    ),
  );
}

class QuickAddModalContent extends StatefulWidget {
  final AppState state;
  final String? preselectedPartyId;
  const QuickAddModalContent({super.key, required this.state, this.preselectedPartyId});

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
    // اختيار آخر شخص تم التعامل معه تلقائياً
    if (widget.preselectedPartyId != null) {
      _selectedPartyId = widget.preselectedPartyId;
    } else if (widget.state.entries.isNotEmpty) {
      final validEntries = widget.state.entries.where((e) => !e.isDeleted).toList();
      if (validEntries.isNotEmpty) {
        validEntries.sort((a, b) => b.date.compareTo(a.date));
        _selectedPartyId = validEntries.first.partyId;
      }
    }
    _selectedPartyId ??= widget.state.parties.firstWhere((p) => !p.isDeleted).id;

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

  void _openPartySearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: _PartySearchSheet(
          state: widget.state,
          selectedPartyId: _selectedPartyId,
          onSelected: (party) {
            setState(() => _selectedPartyId = party.id);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // حل مشكلة القائمة المنسدلة للوحدة بالصورة 1
  void _openUnitPicker(bool isPrimary) {
    FocusScope.of(context).unfocus(); // إغلاق الكيبورد فوراً لمنع اهتزاز النافذة
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر الوحدة أو العملة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
              const SizedBox(height: 10),
              ...widget.state.units.where((u) => !u.isDeleted).map((u) {
                return ListTile(
                  title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(u.symbol, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  onTap: () {
                    setState(() {
                      if (isPrimary) {
                        _primaryUnitId = u.id;
                      } else {
                        _secondaryUnitId = u.id;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
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
    final secUnit = _secondaryUnitId != null ? state.units.firstWhere((u) => u.id == _secondaryUnitId) : null;
    final isPrimaryWeight = primaryUnit.kind == UnitKind.weight;
    final currentParty = state.parties.firstWhere(
      (p) => p.id == _selectedPartyId,
      orElse: () => AccountParty(id: '', name: 'اختر الحساب'),
    );

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
            Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 12),
            const Text('إضافة معاملة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _openPartySearchSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFF0D4E42), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentParty.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFF0D4E42)),
                          const SizedBox(height: 4),
                          Text(
                            "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _primaryAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: isPrimaryWeight ? 'الوزن (${primaryUnit.symbol})' : 'المبلغ (${primaryUnit.symbol})',
                      hintText: isPrimaryWeight ? '12.45' : '50000',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: InkWell(
                    onTap: () => _openUnitPicker(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          Text(primaryUnit.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: Icon(_isComposite ? Icons.close : Icons.add_circle_outline, size: 18),
                label: Text(
                  _isComposite ? 'إلغاء المعاملة المركبة' : '+ إضافة وحدة أخرى',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => setState(() => _isComposite = !_isComposite),
              ),
            ),

            if (_isComposite && secUnit != null) ...[
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
                    child: InkWell(
                      onTap: () => _openUnitPicker(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                        decoration: BoxDecoration(color: const Color(0xFFFFF9E6), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            Text(secUnit.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                hintText: 'التفاصيل أو البيان',
                filled: true,
                fillColor: const Color(0xFFF6F8F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.debitColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _submit(TransactionType.take),
                    child: const Text('أخذ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.creditColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _submit(TransactionType.pay),
                    child: const Text('دفع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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

class _PartySearchSheet extends StatefulWidget {
  final AppState state;
  final String? selectedPartyId;
  final ValueChanged<AccountParty> onSelected;

  const _PartySearchSheet({required this.state, required this.selectedPartyId, required this.onSelected});

  @override
  State<_PartySearchSheet> createState() => _PartySearchSheetState();
}

class _PartySearchSheetState extends State<_PartySearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);
    final filtered = widget.state.parties.where((p) => !p.isDeleted).where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query.toLowerCase()) || p.phone.contains(_query);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              Row(
                children: const [
                  Text('اسم الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(width: 6),
                  Icon(Icons.account_balance_wallet_outlined, color: primaryTeal),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            autofocus: false,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'بحث',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF6F8F8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = filtered[i];
                final isSelected = p.id == widget.selectedPartyId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE2EFEA),
                    child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.phone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: primaryTeal) : null,
                  onTap: () => widget.onSelected(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
