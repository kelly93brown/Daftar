import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/app_drawer.dart';
import 'customer_ledger_screen.dart';
import 'quick_add_dialog.dart';

class HomeScreen extends StatefulWidget {
  final AppState state;
  const HomeScreen({super.key, required this.state});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    const primaryTeal = Color(0xFF0D4E42);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      // تم تغيير drawer إلى endDrawer لتفتح القائمة من اليسار
      endDrawer: AppSideDrawer(state: state),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        title: Text(
          state.storeNameAr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'إخفاء/إظهار الأرصدة',
            icon: Icon(state.hideBalances ? Icons.visibility_off : Icons.visibility, color: Colors.white),
            onPressed: state.toggleHideBalances,
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            _buildDoubleBalanceSummary(state),
            _buildQuickAccessCategories(state),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0 ? 'سجل الزبائن' : 'سجل الموردين والورش',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    '${state.parties.where((p) => !p.isDeleted).length} حساب نشط',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            ...state.parties.where((p) => !p.isDeleted).map((party) {
              final balances = state.getBalancesForParty(party.id);
              return _buildPartyCard(context, state, party, balances);
            }),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryTeal,
        elevation: 6,
        icon: const Icon(Icons.add_circle, color: Colors.white, size: 26),
        label: const Text('إضافة معاملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        onPressed: () => showQuickAddModal(context, state),
      ),
    );
  }

  Widget _buildDoubleBalanceSummary(AppState state) {
    if (state.hideBalances) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0D4E42), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('الأرصدة مخفية (حماية الخصوصية)', style: TextStyle(color: Colors.white70)),
            Icon(Icons.lock_outline, color: Colors.amber),
          ],
        ),
      );
    }

    final totals = state.getTotalStoreBalances();
    const primaryTeal = Color(0xFF0D4E42);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('إجمالي الأرصدة المعلقة (في السوق)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.amberAccent, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: state.units.where((u) => !u.isDeleted).map((unit) {
              final raw = totals[unit.id] ?? 0;
              final display = unit.formatValue(raw.abs());
              final isPositive = raw >= 0;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(unit.kind == UnitKind.weight ? Icons.scale : Icons.attach_money, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(unit.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$display ${unit.symbol}',
                        style: TextStyle(
                          color: isPositive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCategories(AppState state) {
    final categories = [
      {'title': 'الزبائن', 'icon': Icons.people},
      {'title': 'الموردين', 'icon': Icons.storefront},
      {'title': 'المصاريف', 'icon': Icons.receipt_long},
      {'title': 'المذكرة', 'icon': Icons.edit_note},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(categories.length, (idx) {
          final item = categories[idx];
          final isSelected = _selectedTabIndex == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = idx),
              child: Container(
                margin: EdgeInsets.only(left: idx == 3 ? 0 : 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D4E42) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Icon(item['icon'] as IconData, color: isSelected ? Colors.white : const Color(0xFF0D4E42), size: 22),
                    const SizedBox(height: 4),
                    Text(
                      item['title'] as String,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPartyCard(BuildContext context, AppState state, AccountParty party, Map<String, int> balances) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2EFEA),
          child: Text(party.name.isNotEmpty ? party.name[0] : '?', style: const TextStyle(color: Color(0xFF0D4E42), fontWeight: FontWeight.bold)),
        ),
        title: Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Wrap(
          spacing: 6,
          children: state.units.where((u) => !u.isDeleted && (balances[u.id] ?? 0) != 0).map((u) {
            final val = balances[u.id] ?? 0;
            final isPositive = val >= 0;
            return Text(
              state.hideBalances ? '••••' : '${u.formatValue(val.abs())} ${u.symbol}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositive ? state.creditColor : state.debitColor,
              ),
            );
          }).toList(),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerLedgerScreen(state: state, party: party)));
        },
      ),
    );
  }
}
