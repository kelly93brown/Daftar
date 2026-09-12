import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
  String _filterName = '';
  final Set<String> _selectedEntryIds = {};
  bool _isSelectionMode = false;
  bool _sortAscending = false;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  final GlobalKey _globalKey = GlobalKey();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  void _showDateFilterSheet(BuildContext context) {
    String currentChoice = 'all';
    DateTime now = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 12),
                  const Text('حدد الفترة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D4E42))),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _buildPeriodBtn('أمس', Icons.history, currentChoice == 'yesterday', () => setSheetState(() => currentChoice = 'yesterday')),
                      const SizedBox(width: 10),
                      _buildPeriodBtn('اليوم', Icons.calendar_today_outlined, currentChoice == 'today', () => setSheetState(() => currentChoice = 'today')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPeriodBtn('هذا الشهر', Icons.calendar_view_month_outlined, currentChoice == 'this_month', () => setSheetState(() => currentChoice = 'this_month')),
                      const SizedBox(width: 10),
                      _buildPeriodBtn('آخر 7 أيام', Icons.date_range_outlined, currentChoice == 'last_7', () => setSheetState(() => currentChoice = 'last_7')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPeriodBtn('الكل', Icons.all_inclusive, currentChoice == 'all', () => setSheetState(() => currentChoice = 'all')),
                      const SizedBox(width: 10),
                      _buildPeriodBtn('الشهر الماضي', Icons.calendar_today_outlined, currentChoice == 'last_month', () => setSheetState(() => currentChoice = 'last_month')),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _buildPeriodBtn('تحديد من - إلى', Icons.date_range, false, () async {
                        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) {
                          setState(() {
                            _filterRange = picked;
                            _filterName = '${picked.start.month}/${picked.start.day} - ${picked.end.month}/${picked.end.day}';
                          });
                          Navigator.pop(ctx);
                        }
                      }),
                      const SizedBox(width: 10),
                      _buildPeriodBtn('تحديد يوم فقط', Icons.calendar_month_outlined, false, () async {
                        final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) {
                          setState(() {
                            _filterRange = DateTimeRange(start: picked, end: picked);
                            _filterName = '${picked.year}-${picked.month}-${picked.day}';
                          });
                          Navigator.pop(ctx);
                        }
                      }),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D4E42),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (currentChoice == 'all') {
                              setState(() { _filterRange = null; _filterName = ''; });
                            } else if (currentChoice == 'today') {
                              final start = DateTime(now.year, now.month, now.day);
                              setState(() { _filterRange = DateTimeRange(start: start, end: start); _filterName = 'اليوم'; });
                            } else if (currentChoice == 'yesterday') {
                              final y = now.subtract(const Duration(days: 1));
                              final start = DateTime(y.year, y.month, y.day);
                              setState(() { _filterRange = DateTimeRange(start: start, end: start); _filterName = 'أمس'; });
                            } else if (currentChoice == 'last_7') {
                              setState(() { _filterRange = DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now); _filterName = 'آخر 7 أيام'; });
                            } else if (currentChoice == 'this_month') {
                              setState(() { _filterRange = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now); _filterName = 'هذا الشهر'; });
                            } else if (currentChoice == 'last_month') {
                              final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
                              final lastDayLastMonth = DateTime(now.year, now.month, 0);
                              setState(() { _filterRange = DateTimeRange(start: firstDayLastMonth, end: lastDayLastMonth); _filterName = 'الشهر الماضي'; });
                            }
                            Navigator.pop(ctx);
                          },
                          child: const Text('موافق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F4),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPeriodBtn(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD6E4E2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF0D4E42) : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF0D4E42) : Colors.black87)),
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF0D4E42) : Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const primaryTeal = Color(0xFF0D4E42);

    List<LedgerEntry> partyEntries = state.entries
        .where((e) => e.partyId == widget.party.id && !e.isDeleted)
        .where((e) {
          if (_filterRange != null) {
            final entryDate = DateTime(e.date.year, e.date.month, e.date.day);
            final startDate = DateTime(_filterRange!.start.year, _filterRange!.start.month, _filterRange!.start.day);
            final endDate = DateTime(_filterRange!.end.year, _filterRange!.end.month, _filterRange!.end.day);
            if (entryDate.isBefore(startDate) || entryDate.isAfter(endDate)) return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final unit = state.units.firstWhere((u) => u.id == e.unitId, orElse: () => state.units.first);
            final amountStr = unit.formatValue(e.rawAmount);
            final dateStr = "${e.date.year}-${e.date.month}-${e.date.day}";
            return e.note.toLowerCase().contains(query) || amountStr.contains(query) || dateStr.contains(query);
          }
          return true;
        }).toList();

    partyEntries.sort((a, b) => _sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    final Map<String, int> runningCalculators = {};
    for (var u in state.units) runningCalculators[u.id] = 0;
    
    final chronologicalList = partyEntries.toList();
    chronologicalList.sort((a, b) => a.date.compareTo(b.date));
    final Map<String, int> rowRunningBalances = {};
    for (var entry in chronologicalList) {
      int cur = runningCalculators[entry.unitId] ?? 0;
      cur += entry.type == TransactionType.take ? -entry.rawAmount : entry.rawAmount;
      runningCalculators[entry.unitId] = cur;
      rowRunningBalances[entry.id] = cur;
    }

    final hasWeight = partyEntries.any((e) => state.units.firstWhere((u) => u.id == e.unitId, orElse: () => state.units.first).kind == UnitKind.weight);
    final hasCurrency = partyEntries.any((e) => state.units.firstWhere((u) => u.id == e.unitId, orElse: () => state.units.first).kind == UnitKind.currency);
    String dynamicAmountTitle = 'المبلغ / الوزن';
    if (hasWeight && !hasCurrency) {
      dynamicAmountTitle = 'الوزن';
    } else if (hasCurrency && !hasWeight) {
      dynamicAmountTitle = 'المبلغ';
    }

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSearching) {
          setState(() {
            _isSearching = false;
            _searchQuery = '';
            _searchCtrl.clear();
          });
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F7F6),
          appBar: AppBar(
            backgroundColor: primaryTeal,
            iconTheme: const IconThemeData(color: Colors.white),
            title: _isSearching
                ? TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'بحث...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  )
                : Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            actions: [
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _showMultiDeleteConfirmation(context, state, _selectedEntryIds.toList()),
                )
              else ...[
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchQuery = '';
                        _searchCtrl.clear();
                      }
                    });
                  },
                ),
                IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () => _openShareOptionsSheet(context, partyEntries, runningCalculators)),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      onPressed: () => _showDateFilterSheet(context),
                    ),
                    if (_filterRange != null)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ]
            ],
          ),
          body: RepaintBoundary(
            key: _globalKey,
            child: Container(
              color: const Color(0xFFF4F7F6),
              child: Column(
                children: [
                  _buildTopBalances(state, runningCalculators),

                  if (_filterRange != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(_filterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Spacer(),
                          InkWell(
                            onTap: () => setState(() { _filterRange = null; _filterName = ''; }),
                            child: const Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                  // ترويسة الجدول: تم ضبط التاريخ ليكون في أقصى اليسار عبر Align
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: primaryTeal,
                    child: Row(
                      children: [
                        const Expanded(flex: 2, child: Text('الرصيد', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                        const SizedBox(width: 16),
                        const Expanded(flex: 2, child: Text('التفاصيل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                        Expanded(flex: 2, child: Text(dynamicAmountTitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                        // في أقصى اليسار (Align left)
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () => setState(() => _sortAscending = !_sortAscending),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: Colors.amberAccent),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'التاريخ',
                                    style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: partyEntries.isEmpty
                        ? const Center(child: Text('لا يوجد'))
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
                                      _openTransactionDetailsSheet(context, state, entry, unit, runningCalculators);
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
                                        // الرصيد: تنسيق LTR (الرقم أولاً ثم الوحدة)
                                        Expanded(
                                          flex: 2,
                                          child: Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Text(
                                              state.hideBalances
                                                  ? '••••'
                                                  : '${running < 0 ? "-" : ""}${unit.formatValue(running.abs())} ${unit.symbol}',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: running >= 0 ? Colors.black87 : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Icon(isTake ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: isTake ? state.debitColor : state.creditColor, size: 20),
                                        Expanded(flex: 2, child: Text(entry.note.isNotEmpty ? entry.note : '-', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                        // المبلغ / الوزن
                                        Expanded(
                                          flex: 2,
                                          child: Text(unit.formatValue(entry.rawAmount), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isTake ? state.debitColor : state.creditColor)),
                                        ),
                                        // التاريخ بأقصى اليسار
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
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryTeal,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () => showQuickAddModal(context, state, defaultPartyId: widget.party.id),
          ),
        ),
      ),
    );
  }

  // بطاقات الرصيد العلوية مع ضبط اتجاه LTR وتكبير الخط
  Widget _buildTopBalances(AppState state, Map<String, int> runningCalculators) {
    final activeUnits = state.units.where((u) => runningCalculators[u.id] != 0 || state.entries.any((e) => e.partyId == widget.party.id && e.unitId == u.id)).toList();
    if (activeUnits.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: activeUnits.map((u) {
          final bal = runningCalculators[u.id] ?? 0;
          final isPositive = bal >= 0;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isPositive ? state.creditColor.withValues(alpha: 0.3) : state.debitColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(u.kind == UnitKind.weight ? Icons.scale : Icons.monetization_on, size: 18, color: const Color(0xFF0D4E42)),
                      Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // اتجاه LTR لعرض الرقم متبوعاً بالوحدة مع فاصل الآلاف
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${u.formatValue(bal.abs())} ${u.symbol}',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isPositive ? state.creditColor : state.debitColor),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(isPositive ? 'مستحق له (دائن)' : 'مطلوب منه (مدين)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _buildFormattedMessage(AppState state, LedgerEntry entry, UnitCurrency unit, Map<String, int> runningCalculators) {
    final typeStr = entry.type == TransactionType.take ? 'عليك' : 'لك';
    String msg = "العميل: ${widget.party.name}\n";
    msg += "$typeStr: ${unit.formatValue(entry.rawAmount)} ${unit.symbol}\n";
    if (entry.note.isNotEmpty) msg += "${entry.note}\n";
    msg += "الاجمالي $typeStr: ${unit.formatValue((runningCalculators[entry.unitId] ?? 0).abs())} ${unit.symbol}\n";
    msg += "التاريخ: ${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}";
    return msg;
  }

  Future<void> _sendTextSummary(AppState state, LedgerEntry entry, UnitCurrency unit, Map<String, int> runningCalculators, bool isWhatsApp) async {
    final msg = _buildFormattedMessage(state, entry, unit, runningCalculators);
    final encoded = Uri.encodeComponent(msg);
    final url = Uri.parse(isWhatsApp ? "https://wa.me/?text=$encoded" : "sms:?body=$encoded");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Share.share(msg);
    }
  }

  void _openTransactionDetailsSheet(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency unit, Map<String, int> runningCalculators) {
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

              _detailRow(
                'المبلغ',
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${unit.formatValue(entry.rawAmount)} ${unit.symbol}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isTake ? state.debitColor : state.creditColor),
                      ),
                    ),
                    Icon(isTake ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: isTake ? state.debitColor : state.creditColor),
                  ],
                ),
              ),
              _detailRow('العملة', Text(unit.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87))),
              _detailRow('الوقت', Text("${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
              _detailRow('التاريخ', Text("${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
              _detailRow('التفاصيل', Text(entry.note.isNotEmpty ? entry.note : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87))),
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
                    final shareText = _buildFormattedMessage(state, entry, unit, runningCalculators);
                    Share.share(shareText);
                  }),
                  _actionCircle(Icons.receipt_long, 'مشاركة الفاتورة', const Color(0xFFFCE7F3), Colors.purple, () {
                    Navigator.pop(ctx);
                    _sendTextSummary(state, entry, unit, runningCalculators, false);
                  }),
                  _actionCircle(Icons.chat, 'WhatsApp', const Color(0xFFDCFCE7), Colors.green, () {
                    Navigator.pop(ctx);
                    _sendTextSummary(state, entry, unit, runningCalculators, true);
                  }),
                  _actionCircle(Icons.message, 'SMS', const Color(0xFFFFEDD5), Colors.orange, () {
                    Navigator.pop(ctx);
                    _sendTextSummary(state, entry, unit, runningCalculators, false);
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

  // ==================== نافذة التعديل المطابقة للصورة 37 ====================
  void _openEditTransactionSheet(BuildContext context, AppState state, LedgerEntry entry, UnitCurrency initialUnit) {
    String selectedUnitId = entry.unitId;
    final amountCtrl = TextEditingController(text: initialUnit.formatValue(entry.rawAmount).replaceAll(' ', ''));
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
            final activeUnit = state.units.firstWhere((u) => u.id == selectedUnitId, orElse: () => initialUnit);
            final isWeight = activeUnit.kind == UnitKind.weight;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // نوع العملة / الوحدة
                    const Text('نوع العملة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedUnitId,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          items: state.units.where((u) => !u.isDeleted).map((u) {
                            return DropdownMenuItem(
                              value: u.id,
                              child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedUnitId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // المبلغ أو الوزن
                    Text(isWeight ? 'الوزن' : 'المبلغ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0D4E42), width: 1.5),
                      ),
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // التفاصيل
                    const Text('التفاصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: noteCtrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // التاريخ مع أيقونة الكاميرا (مطابق للصورة 37)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: currentDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setModalState(() => currentDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8F8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black87, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, size: 28, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // خيارات الراديو (أخذ / دفع)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Radio<TransactionType>(
                              value: TransactionType.take,
                              groupValue: currentType,
                              activeColor: const Color(0xFF0D4E42),
                              onChanged: (v) => setModalState(() => currentType = v!),
                            ),
                            const Text('أخذ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Row(
                          children: [
                            Radio<TransactionType>(
                              value: TransactionType.pay,
                              groupValue: currentType,
                              activeColor: const Color(0xFF0D4E42),
                              onChanged: (v) => setModalState(() => currentType = v!),
                            ),
                            const Text('دفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // زر حفظ الأخضر العريض
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D4E42),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final newUnit = state.units.firstWhere((u) => u.id == selectedUnitId);
                          final rawAmount = newUnit.parseInput(amountCtrl.text);
                          if (rawAmount > 0) {
                            state.updateTransaction(entry.id, selectedUnitId, rawAmount, currentDate, noteCtrl.text.trim(), currentType);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديل بنجاح')));
                          }
                        },
                        child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openShareOptionsSheet(BuildContext context, List<LedgerEntry> entries, Map<String, int> runningCalculators) {
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
                  _shareCircle(Icons.table_chart, 'إكسل', const Color(0xFFDCFCE7), Colors.green, () => _shareExcel(entries)),
                  _shareCircle(Icons.picture_as_pdf, 'PDF', const Color(0xFFFFE4E6), Colors.red, () => _sharePdf(entries)),
                  _shareCircle(Icons.article, 'نصية', const Color(0xFFE0F2FE), Colors.blue, () => _shareText(entries)),
                  _shareCircle(Icons.receipt, 'صورة', const Color(0xFFF3E8FF), Colors.purple, () => _shareImage()),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    Navigator.pop(context);
    final imageBytes = await _capturePng();
    if (imageBytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ledger.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'سجل ${widget.party.name}');
    }
  }

  Future<void> _shareText(List<LedgerEntry> entries) async {
    Navigator.pop(context);
    String txt = "كشف حساب: ${widget.party.name}\n\n";
    for (var e in entries) {
      final u = widget.state.units.firstWhere((u) => u.id == e.unitId);
      txt += "التاريخ: ${e.date.year}-${e.date.month}-${e.date.day} | ${e.type == TransactionType.take ? 'عليه' : 'له'} ${u.formatValue(e.rawAmount)} ${u.symbol} | ${e.note}\n";
    }
    await Share.share(txt);
  }

  Future<void> _shareExcel(List<LedgerEntry> entries) async {
    Navigator.pop(context);
    String csv = "التاريخ,المبلغ,الوحدة,النوع,التفاصيل\n";
    for (var e in entries) {
      final u = widget.state.units.firstWhere((u) => u.id == e.unitId);
      csv += "${e.date.year}-${e.date.month}-${e.date.day},${u.formatValue(e.rawAmount)},${u.symbol},${e.type == TransactionType.take ? 'مدين' : 'دائن'},${e.note}\n";
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ledger.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'ملف إكسل - ${widget.party.name}');
  }

  Future<void> _sharePdf(List<LedgerEntry> entries) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري إنشاء ملف الـ PDF...')));
    final pdf = pw.Document();
    final imageBytes = await _capturePng();
    if (imageBytes != null) {
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(pdfImage));
      }));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ledger.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'PDF - ${widget.party.name}');
    }
  }

  Widget _shareCircle(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 26, backgroundColor: bg, child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.bold)),
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
                setState(() { _selectedEntryIds.clear(); _isSelectionMode = false; });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف')));
              },
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
