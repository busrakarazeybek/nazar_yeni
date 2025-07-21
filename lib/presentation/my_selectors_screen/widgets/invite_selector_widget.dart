import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class InviteSelectorWidget extends StatefulWidget {
  final Function(String name, String relationship) onInviteSent;

  const InviteSelectorWidget({
    super.key,
    required this.onInviteSent,
  });

  @override
  State<InviteSelectorWidget> createState() => _InviteSelectorWidgetState();
}

class _InviteSelectorWidgetState extends State<InviteSelectorWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String _selectedRelationship = "Aile";
  final List<String> _relationships = [
    "Aile",
    "Arkadaş",
    "Akraba",
    "İş Arkadaşı"
  ];

  final List<Map<String, dynamic>> _contacts = [
    {
      "name": "Ayşe Demir",
      "phone": "+90 532 123 4567",
      "relationship": "Aile",
      "avatar":
          "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "name": "Mehmet Özkan",
      "phone": "+90 533 987 6543",
      "relationship": "Arkadaş",
      "avatar":
          "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "name": "Fatma Yılmaz",
      "phone": "+90 534 555 1234",
      "relationship": "Aile",
      "avatar":
          "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
    {
      "name": "Ali Kaya",
      "phone": "+90 535 777 8888",
      "relationship": "İş Arkadaşı",
      "avatar":
          "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _messageController.text =
        "Merhaba! Seni Goricu Matchmaker uygulamasında görücüm olarak davet etmek istiyorum. Bu uygulama sayesinde benim için uygun eş adaylarını bulup önerebilirsin. Kabul edersen çok memnun olurum.";
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Görücü Davet Et",
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.lightTheme.colorScheme.primary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Kişilerden Seç"),
                Tab(text: "Manuel Ekle"),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContactsTab(),
                _buildManualTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: EdgeInsets.all(4.w),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Kişi ara...",
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // Contacts List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return Card(
                margin: EdgeInsets.only(bottom: 1.h),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6.w),
                    child: CustomImageWidget(
                      imageUrl: contact['avatar'] as String,
                      width: 12.w,
                      height: 12.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    contact['name'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['phone'] as String,
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 0.5.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: AppTheme
                              .lightTheme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          contact['relationship'] as String,
                          style: AppTheme.lightTheme.textTheme.labelSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _sendInviteToContact(contact),
                    style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      minimumSize: Size(0, 0),
                    ),
                    child: const Text("Davet Et"),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kişi Bilgileri",
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Name Field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Ad Soyad *",
              hintText: "Örn: Ayşe Demir",
            ),
          ),
          SizedBox(height: 2.h),

          // Phone Field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Telefon Numarası",
              hintText: "+90 5XX XXX XX XX",
            ),
          ),
          SizedBox(height: 2.h),

          // Email Field
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "E-posta Adresi",
              hintText: "ornek@email.com",
            ),
          ),
          SizedBox(height: 2.h),

          // Relationship Dropdown
          Text(
            "İlişki Türü",
            style: AppTheme.lightTheme.textTheme.titleSmall,
          ),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            decoration: BoxDecoration(
              border:
                  Border.all(color: AppTheme.lightTheme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRelationship,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRelationship = newValue;
                    });
                  }
                },
                items: _relationships
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Message Section
          Text(
            "Davet Mesajı",
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Davet mesajınızı yazın...",
            ),
          ),
          SizedBox(height: 4.h),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSendInvite() ? _sendManualInvite : null,
              icon: CustomIconWidget(
                iconName: 'send',
                color: _canSendInvite()
                    ? AppTheme.lightTheme.elevatedButtonTheme.style
                            ?.foregroundColor
                            ?.resolve({}) ??
                        Colors.white
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              label: const Text("Davet Gönder"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Info Card
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    "Davet gönderdiğiniz kişi, uygulamayı indirip hesap oluşturduktan sonra görücünüz olarak eklenecektir.",
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canSendInvite() {
    return _nameController.text.trim().isNotEmpty &&
        (_phoneController.text.trim().isNotEmpty ||
            _emailController.text.trim().isNotEmpty);
  }

  void _sendInviteToContact(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Davet Gönder"),
        content: Text(
            "${contact['name']} kişisine görücü daveti göndermek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              widget.onInviteSent(
                  contact['name'] as String, contact['relationship'] as String);
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }

  void _sendManualInvite() {
    if (!_canSendInvite()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Davet Gönder"),
        content: Text(
            "${_nameController.text} kişisine görücü daveti göndermek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              widget.onInviteSent(_nameController.text, _selectedRelationship);
            },
            child: const Text("Gönder"),
          ),
        ],
      ),
    );
  }
}
