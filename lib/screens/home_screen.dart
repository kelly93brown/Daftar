import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'customer_ledger_screen.dart';
import 'quick_add_dialog.dart';
import 'settings_screen.dart';

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
    final theme = Theme.of(context);
    const primaryTeal = Color(0xFF0D4E42);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'دفتر الحسابات والذهب',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'إخفاء/إظهار الأرصدة',
            icon: Icon(
              state.hideBalances ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            onPressed: state.toggleHideBalances,
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen(state: state)),
              );
            },
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 90),
          children: [
            // بطاقة الأرصدة المزدوجة العلوية
            _buildDoubleBalanceSummary(state),

            // أقسام الوصول السريع
            _buildQuickAccessCategories(state),

            // ترويسة قائمة الأطراف/الزبائن
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 0 ? 'سجل الزبائن' : 'سجل الموردين والورشات',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    '${state.parties.where((p) => !p.isDeleted).length} حساب نشط',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            // قائمة الزبائن والموردين
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
        icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
        label: const Text(
          'معاملة جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: () => showQuickAddModal(context, state),
      ),
    );
  }

  Widget _buildDoubleBalanceSummary(AppState state) {
    final totals = state.getTotalStoreBalances();
    const primaryTeal = Color(0xFF0D4E42);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryTeal,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'إجمالي الأرصدة المعلقة (في السوق)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Icon(
                state.hideBalances ? Icons.lock_outline : Icons.account_balance_wallet_outlined,
                color: Colors.amberAccent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: state.units.where((u) => !u.isDeleted).map((unit) {
                final raw = totals[unit.id] ?? 0;
                final display = unit.formatValue(raw.abs());
                final isPositive = raw >= 0;

                return Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          Icon(
                            unit.kind == UnitKind.weight ? Icons.scale : Icons.attach_money,
                            size: 15,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit.name,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.hideBalances ? '••••••' : '$display ${unit.symbol}',
                        style: TextStyle(
                          color: isPositive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCategories(AppState state) {
    final categories = [
      {'title': 'الزبائن', 'icon': Icons.people, 'type': PartyType.customer},
      {'title': 'الموردين', 'icon': Icons.storefront, 'type': PartyType.supplier},
      {'title': 'المصاريف', 'icon': Icons.receipt_long, 'type': PartyType.expense},
      {'title': 'المذكرة', 'icon': Icons.edit_note, 'type': null},
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
              onTap: () {
                setState(() => _selectedTabIndex = idx);
              },
              child: Container(
                margin: EdgeInsets.only(left: idx == 3 ? 0 : 6),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0D4E42) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFF0D4E42),
                      size: 22,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE8F2F0),
          child: Text(
            party.name.isNotEmpty ? party.name[0] : '?',
            style: const TextStyle(color: Color(0xFF0D4E42), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          party.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (party.phone.isNotEmpty)
              Text(party.phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: state.units.where((u) => !u.isDeleted && (balances[u.id] ?? 0) != 0).map((u) {
                final val = balances[u.id] ?? 0;
                final isPositive = val >= 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPositive ? state.creditBg : state.debitBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.hideBalances ? '••••' : '${u.formatValue(val.abs())} ${u.symbol}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? state.creditColor : state.debitColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerLedgerScreen(state: state, party: party),
            ),
          );
        },
      ),
    );
  }
}
