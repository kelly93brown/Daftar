import 'package:flutter/material.dart';

void main() {
  runApp(const DaftarApp());
}

class DaftarApp extends StatelessWidget {
  const DaftarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تعريف الألوان الأساسية المستوحاة من الصور
    const Color primaryColor = Color(0xFF044D3B); // أخضر داكن
    const Color backgroundColor = Color(0xFFF7F8FA); // رمادي فاتح جداً للخلفية

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق دفتر للصاغة',
      // فرض اتجاه النص من اليمين لليسار (RTL) لدعم العربية بدون الحاجة لمكتبات إضافية حالياً
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          background: backgroundColor,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        fontFamily: 'Tahoma', // يمكن تغييره لاحقاً لـ Cairo أو Tajawal
      ),
      home: const SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {}, // سيتم برمجته للعودة لاحقاً
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          _buildSectionTitle('المعلومات الشخصية'),
          const SizedBox(height: 8),
          _buildPersonalInfoGroup(context),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('إعدادات التطبيق'),
          const SizedBox(height: 8),
          _buildAppSettingsGroup(context),

          const SizedBox(height: 24),
          
          _buildSectionTitle('الأمان والخصوصية'),
          const SizedBox(height: 8),
          _buildSecurityGroup(context),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoGroup(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsTile(
          title: 'المعلومات الشخصية',
          icon: Icons.info_outline,
          onTap: () {
            // سيتم فتح شاشة المعلومات الشخصية
          },
        ),
        SettingsTile(
          title: 'التصنيف',
          icon: Icons.class_outlined,
          onTap: () {},
        ),
        SettingsTile(
          title: 'العملات',
          icon: Icons.currency_exchange,
          onTap: () {},
        ),
        SettingsTile(
          title: 'الترميز',
          icon: Icons.code,
          showDivider: false, // آخر عنصر لا يحتوي على فاصل
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAppSettingsGroup(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsTile(
          title: 'المظهر',
          icon: Icons.dark_mode_outlined,
          onTap: () => _showThemeBottomSheet(context),
        ),
        SettingsTile(
          title: 'الإشعارات',
          icon: Icons.notifications_none,
          onTap: () => _showNotificationsBottomSheet(context),
        ),
        SettingsTile(
          title: 'حجم الخط',
          icon: Icons.text_fields,
          onTap: () => _showFontSizeBottomSheet(context),
        ),
        SettingsTile(
          title: 'ألوان المدين والدائن',
          icon: Icons.color_lens_outlined,
          onTap: () => _showColorsBottomSheet(context),
        ),
        SettingsTile(
          title: 'إظهار الرصيد في الصفحة الرئيسية',
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => _showHomeBalanceBottomSheet(context),
        ),
        SettingsTile(
          title: 'وقت نسخ البيانات الى الجهاز',
          icon: Icons.access_time,
          onTap: () => _showBackupTimeBottomSheet(context),
        ),
        SettingsTile(
          title: 'قالب الرسالة',
          icon: Icons.message_outlined,
          onTap: () {}, // شاشة مستقلة
        ),
        SettingsTile(
          title: 'قالب الرسائل المتعددة',
          icon: Icons.forum_outlined,
          onTap: () {}, // شاشة مستقلة
        ),
        SettingsTile(
          title: 'إعدادات الطباعة',
          icon: Icons.print_outlined,
          onTap: () {}, 
        ),
        SettingsTile(
          title: '(PDF) إعدادات أعمدة التقارير',
          icon: Icons.picture_as_pdf_outlined,
          onTap: () {}, // شاشة مستقلة متقدمة
        ),
        SettingsTile(
          title: 'تمكين الإكمال التلقائي',
          icon: Icons.auto_awesome_outlined,
          onTap: () {},
        ),
        SettingsTile(
          title: 'إخفاء السند في نافذة المشاركة',
          icon: Icons.receipt_long_outlined,
          onTap: () {},
        ),
        SettingsTile(
          title: 'إرسال الملاحظات',
          icon: Icons.feedback_outlined,
          showDivider: false,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSecurityGroup(BuildContext context) {
    return SettingsGroup(
      children: [
        SettingsTile(
          title: 'كلمة المرور',
          icon: Icons.lock_outline,
          onTap: () => _showPasswordBottomSheet(context),
        ),
        SettingsTile(
          title: 'سياسة الخصوصية',
          icon: Icons.privacy_tip_outlined,
          onTap: () {},
        ),
        SettingsTile(
          title: 'تفضيلات إعلانات الخصوصية',
          icon: Icons.report_problem_outlined,
          showDivider: false,
          onTap: () {},
        ),
      ],
    );
  }

  // دالة مساعدة لإنشاء شكل النافذة السفلية الموحد
  void _showCustomBottomSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // خط السحب العلوي
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF044D3B)),
              ),
              const SizedBox(height: 24),
              content,
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    _showCustomBottomSheet(
      context,
      'المظهر',
      Column(
        children: [
          const Text('اختر مظهر التطبيق المفضل لديك', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          _buildSelectionItem('الوضع الفاتح', Icons.wb_sunny_outlined, true),
          const SizedBox(height: 8),
          _buildSelectionItem('الوضع الداكن', Icons.nightlight_round, false),
          const SizedBox(height: 8),
          _buildSelectionItem('تلقائي (حسب النظام)', Icons.phone_android, false),
          const SizedBox(height: 20),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    _showCustomBottomSheet(
      context,
      'الإشعارات',
      Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Color(0xFF044D3B)),
                    SizedBox(width: 12),
                    Text('تمكين الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Switch(
                  value: true,
                  activeColor: const Color(0xFF044D3B),
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ستتلقى تنبيهات عند اكتمال عمليات النسخ الاحتياطي اليدوي أو التلقائي بنجاح',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    _showCustomBottomSheet(
      context,
      'حجم الخط',
      Column(
        children: [
          // معاينة النص هنا
          const Text('معاينة النص: تطبيق حساباتي لإدارة الأموال والديون بسهولة ويسر.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // الـ Slider يوضع هنا (مبسط)
          Slider(
            value: 100,
            min: 80,
            max: 140,
            activeColor: const Color(0xFF044D3B),
            onChanged: (val) {},
          ),
          const SizedBox(height: 20),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  void _showColorsBottomSheet(BuildContext context) {
     _showCustomBottomSheet(context, 'ألوان المدين والدائن', Column(
       children: [
         const Text('سيتم إضافة معاينة الألوان هنا'),
         const SizedBox(height: 20),
         _buildSaveButton(context),
       ]
     ));
  }
  
  void _showHomeBalanceBottomSheet(BuildContext context) {
      _showCustomBottomSheet(context, 'إظهار الرصيد في الصفحة الرئيسية', Column(
       children: [
         const Text('إعدادات عرض الرصيد هنا'),
         const SizedBox(height: 20),
         _buildSaveButton(context),
       ]
     ));
  }
  
  void _showBackupTimeBottomSheet(BuildContext context) {
      _showCustomBottomSheet(context, 'وقت نسخ البيانات الى الجهاز', Column(
       children: [
         const Text('إعدادات النسخ التلقائي هنا'),
         const SizedBox(height: 20),
         _buildSaveButton(context),
       ]
     ));
  }

  void _showPasswordBottomSheet(BuildContext context) {
      _showCustomBottomSheet(context, 'تمكين كلمة المرور', Column(
       children: [
         const Text('إعدادات القفل والبصمة هنا'),
         const SizedBox(height: 20),
         _buildSaveButton(context),
       ]
     ));
  }

  Widget _buildSelectionItem(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F0EE) : Colors.white,
        border: Border.all(color: isSelected ? const Color(0xFF044D3B) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF044D3B) : Colors.grey),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: isSelected ? const Color(0xFF044D3B) : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF044D3B)),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF044D3B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ودجت (Widget) مخصصة لتجميع العناصر داخل بطاقة بيضاء بخلفية دائرية كما في التصميم
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ودجت مخصصة لكل عنصر في القائمة
class SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0EE), // خلفية خضراء باهتة للأيقونة
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF044D3B), // لون الأيقونة
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right, // سهم الاتجاه لليسار (بحكم أن التطبيق RTL)
            color: Colors.grey,
            size: 20,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
      ],
    );
  }
}
