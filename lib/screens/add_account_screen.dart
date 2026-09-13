import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class AddAccountScreen extends StatefulWidget {
  final AppState state;
  const AddAccountScreen({super.key, required this.state});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.state.categories.isNotEmpty ? widget.state.categories.first.name : 'عام';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // فتح جهات الاتصال
  Future<void> _pickContact() async {
    if (await FlutterContacts.requestPermission(readonly: true)) {
      Contact? contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        setState(() {
          _nameCtrl.text = contact.displayName;
          if (contact.phones.isNotEmpty) {
            _phoneCtrl.text = contact.phones.first.number.replaceAll(' ', '');
          }
        });
      }
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final newParty = AccountParty(
      id: UuidUtil.generate(),
      name: name,
      phone: _phoneCtrl.text.trim(),
      category: _selectedCategory,
      type: _selectedCategory == 'موردين' ? PartyType.supplier : PartyType.customer,
    );

    widget.state.addParty(newParty);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إضافة الحساب: $name بنجاح')));
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D4E42);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(
          backgroundColor: primaryTeal,
          title: const Text('اضافة حساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFE2EFEA), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    CircleAvatar(radius: 26, backgroundColor: Colors.white, child: const Icon(Icons.account_balance_wallet, color: primaryTeal, size: 28)),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('اضافة حساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTeal)),
                        SizedBox(height: 4),
                        Text('املأ تفاصيل الحساب الجديد', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Align(alignment: Alignment.centerRight, child: Text('التصنيف', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down, color: primaryTeal),
                    items: widget.state.categories.where((c) => !c.isDeleted).map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(value: c.name, child: Row(children: [const Icon(Icons.label_outline, color: primaryTeal, size: 18), const SizedBox(width: 8), Text(c.name)]));
                    }).toList(),
                    onChanged: (val) { if (val != null) setState(() => _selectedCategory = val); },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'اسم الحساب',
                  // زر جلب جهات الاتصال
                  prefixIcon: IconButton(icon: const Icon(Icons.person_add_alt, color: primaryTeal), onPressed: _pickContact),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'رقم الهاتف',
                  // زر جلب جهات الاتصال
                  prefixIcon: IconButton(icon: const Icon(Icons.phone_outlined, color: primaryTeal), onPressed: _pickContact),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _save,
                  child: const Text('اضافة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
