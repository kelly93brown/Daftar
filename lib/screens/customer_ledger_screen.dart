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
  final Set<String> _selectedEntryIds = {};
  bool _isSelectionMode = false;

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // مفتاح مخصص لالتقاط صورة الشاشة بدل مكتبة Screenshot المسببة للخطأ
  final GlobalKey _globalKey = GlobalKey();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // دالة التقاط صورة الشاشة Native
  Future<List<int>?> _capturePng() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const primaryTeal = Color(0xFF0D4E42);

    List<LedgerEntry> partyEntries = state.entries
        .where((e) => e.partyId == widget.party.id && !e.isDeleted)
        .where((e) {
          if (_filterRange != null) {
            if (e.date.isBefore(_filterRange!.start.subtract(const Duration(days: 1))) ||
                e.date.isAfter(_filterRange!.end.add(const Duration(days: 1)))) return false;
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
          title: _isSearching
              ? TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'بحث في السجل...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : Text(widget.party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        // استخدمت RepaintBoundary لالتقاط صورة بديلة للمكتبة المحذوفة
        body: RepaintBoundary(
          key: _globalKey,
          child: Container(
            color: const Color(0xFFF4F7F6),
            child: Column(
              children: [
                _buildTopBalances(state, runningCalculators),
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
                      ? const Center(child: Text('لا توجد حركات مسجلة'))
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
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryTeal,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => showQuickAddModal(context, state, defaultPartyId: widget.party.id),
        ),
      ),
    );
  }

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isPositive ? state.creditColor.withValues(alpha: 0.3) : state.debitColor.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(u.kind == UnitKind.weight ? Icons.scale : Icons.monetization_on, size: 16, color: const Color(0xFF0D4E42)),
                      Text(u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]
                  ),
                  const SizedBox(height: 8),
                  Text('${u.symbol} ${u.formatValue(bal.abs())}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPositive ? state.creditColor : state.debitColor)),
                  Text(isPositive ? 'مستحق له (دائن)' : 'مطلوب منه (مدين)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ]
              )
            )
          );
        }).toList(),
      )
    );
  }

  Future<void> _sendTextSummary(AppState state, LedgerEntry entry, UnitCurrency unit, Map<String, int> runningCalculators, bool isWhatsApp) async {
    String msg = "العميل: ${widget.party.name}\n";
    final typeStr = entry.type == TransactionType.take ? 'عليك' : 'لك';
    msg += "$typeStr: ${unit.formatValue(entry.rawAmount)} ${unit.symbol}\n";
    if (entry.note.isNotEmpty) msg += "${entry.note}\n";
    msg += "الاجمالي $typeStr: ${unit.formatValue((runningCalculators[entry.unitId] ?? 0).abs())} ${unit.symbol}\n";
    msg += "التاريخ: ${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}";

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
                    Share.share("عملية: ${unit.formatValue(entry.rawAmount)} ${unit.symbol} | ${entry.note}");
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
                  TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'المبلغ / الوزن (${unit.symbol})', filled: true, fillColor: const Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'التفاصيل', filled: true, fillColor: const Color(0xFFF6F8F8))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: RadioListTile<TransactionType>(title: Text(state.takeLabel), value: TransactionType.take, groupValue: currentType, onChanged: (v) => setModalState(() => currentType = v!))),
                      Expanded(child: RadioListTile<TransactionType>(title: Text(state.payLabel), value: TransactionType.pay, groupValue: currentType, onChanged: (v) => setModalState(() => currentType = v!))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: currentDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setModalState(() => currentDate = picked);
                    },
                    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF6F8F8), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.calendar_today, color: Color(0xFF0D4E42)), const SizedBox(width: 8), Text("${currentDate.year}-${currentDate.month}-${currentDate.day}", style: const TextStyle(fontWeight: FontWeight.bold))])),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () { Navigator.pop(ctx); state.deleteTransaction(entry.id); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العملية'))); }, child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D4E42), padding: const EdgeInsets.symmetric(vertical: 14)), onPressed: () { final rawAmount = unit.parseInput(amountCtrl.text); if (rawAmount > 0) { state.updateTransaction(entry.id, rawAmount, currentDate, noteCtrl.text.trim(), currentType); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ'))); } }, child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
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
