import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/app_export.dart';
import '../../../services/sms_service.dart';

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
  final TextEditingController _searchController = TextEditingController();

  String _selectedRelationship = "Aile";
  String _searchQuery = '';
  final List<String> _relationships = [
    "Aile",
    "Arkadaş",
    "Akraba",
    "İş Arkadaşı"
  ];

  List<Contact> _phoneContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoadingContacts = false;
  bool _hasContactsPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _messageController.text =
        "Merhaba! Seni Goricu Matchmaker uygulamasında görücüm olarak davet etmek istiyorum. Bu uygulama sayesinde benim için uygun eş adaylarını bulup önerebilirsin. Kabul edersen çok memnun olurum.";
    _checkContactsPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Aday adı, e-posta veya telefon",
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Contacts List
        Expanded(
          child: _buildContactsList(),
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

  /// Kontaklar izni kontrolü
  Future<void> _checkContactsPermission() async {
    final permission = await Permission.contacts.status;
    setState(() {
      _hasContactsPermission = permission.isGranted;
    });
    
    if (_hasContactsPermission) {
      _loadContacts();
    }
  }

  /// Kontaklar iznini iste
  Future<void> _requestContactsPermission() async {
    final permission = await Permission.contacts.request();
    setState(() {
      _hasContactsPermission = permission.isGranted;
    });
    
    if (_hasContactsPermission) {
      _loadContacts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kişilere erişim izni gerekli'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// Telefon kontaklarını yükle
  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
    });

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      // Sadece telefon numarası olan kontakları filtrele
      final filteredContacts = contacts.where((contact) {
        return contact.phones.isNotEmpty && 
               contact.displayName.isNotEmpty;
      }).toList();

      setState(() {
        _phoneContacts = filteredContacts;
        _filteredContacts = filteredContacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContacts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kişiler yüklenirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  /// Kontak arama
  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _phoneContacts;
      });
    } else {
      final filtered = _phoneContacts.where((contact) {
        return contact.displayName.toLowerCase().contains(query.toLowerCase()) ||
               contact.phones.any((phone) => phone.number.contains(query));
      }).toList();
      
      setState(() {
        _filteredContacts = filtered;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _filterContacts(_searchController.text);
  }

  /// Kontaklar listesi widget'ı
  Widget _buildContactsList() {
    if (!_hasContactsPermission) {
      return _buildPermissionRequest();
    }
    
    if (_isLoadingContacts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.lightTheme.primaryColor,
            ),
            SizedBox(height: 2.h),
            Text(
              'Kişiler yükleniyor...',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'contacts',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              _phoneContacts.isEmpty ? 'Hiç kişi bulunamadı' : 'Arama sonucu bulunamadı',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final primaryPhone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
        
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              child: Text(
                contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              contact.displayName,
              style: AppTheme.lightTheme.textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (primaryPhone.isNotEmpty)
                  Text(
                    primaryPhone,
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                if (contact.emails.isNotEmpty)
                  Text(
                    contact.emails.first.address,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _sendInviteToPhoneContact(contact),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                minimumSize: Size(0, 0),
              ),
              child: const Text("Davet Et"),
            ),
          ),
        );
      },
    );
  }
  
  /// İzin isteme widget'ı
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'contacts',
              color: AppTheme.lightTheme.primaryColor,
              size: 64,
            ),
            SizedBox(height: 3.h),
            Text(
              'Kişilerinize Erişim',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.primaryColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Kişilerinizi görücü olarak davet etmek için telefon rehberinize erişim iznine ihtiyacımız var.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _requestContactsPermission,
              icon: CustomIconWidget(
                iconName: 'person_add',
                color: Colors.white,
                size: 20,
              ),
              label: Text('İzin Ver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Telefon kontağından davet gönder
  void _sendInviteToPhoneContact(Contact contact) {
    final primaryPhone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    
    if (primaryPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu kişinin telefon numarası bulunamadı'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Yakınlık derecesi seçim dialog'u
    _showRelationshipSelectionDialog(contact.displayName, primaryPhone);
  }

  /// Yakınlık derecesi seçim dialog'u
  void _showRelationshipSelectionDialog(String name, String phone) {
    String selectedRelationship = _selectedRelationship;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Yakınlık Derecesi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$name ile yakınlık derecenizi seçin:'),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                value: selectedRelationship,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Yakınlık Derecesi',
                ),
                items: _relationships.map((relationship) {
                  return DropdownMenuItem(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedRelationship = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendSMSInvitation(name, phone, selectedRelationship);
              },
              child: Text('Davet Gönder'),
            ),
          ],
        ),
      ),
    );
  }

  /// SMS davet gönder
  Future<void> _sendSMSInvitation(String name, String phone, String relationship) async {
    final smsService = SMSService();
    final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUserProfile;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 4.w),
            Text('SMS gönderiliyor...'),
          ],
        ),
      ),
    );

    try {
      final success = await smsService.sendInvitationSMS(
        phoneNumber: phone,
        senderName: currentUser.fullName ?? 'Görücü Matchmaker',
        relationship: relationship,
      );

      // Loading dialog'u kapat
      Navigator.of(context).pop();

      if (success) {
        widget.onInviteSent(name, relationship);
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name kişisine SMS davet başarıyla gönderildi'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SMS gönderilirken hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      // Loading dialog'u kapat
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SMS gönderilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
