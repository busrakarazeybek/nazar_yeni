import 'package:flutter/foundation.dart';
import '../core/app_export.dart';

class SMSService {
  static final SMSService _instance = SMSService._internal();
  factory SMSService() => _instance;
  SMSService._internal();
  
  /// SMS davet gönder - Supabase Edge Function kullanarak
  Future<bool> sendInvitationSMS({
    required String phoneNumber,
    required String senderName,
    required String relationship,
  }) async {
    try {
      // Telefon numarasını formatla (Türkiye için +90 ekle)
      String formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // SMS mesajını oluştur
      String message = _createInvitationMessage(senderName, relationship);
      
      final supabaseClient = await SupabaseService().client;
      
      // Supabase Edge Function çağrısı
      final response = await supabaseClient.functions.invoke(
        'send-sms',
        body: {
          'to': formattedPhone,
          'message': message,
          'sender_name': senderName,
          'relationship': relationship,
        },
      );
      
      if (response.status == 200) {
        debugPrint('SMS başarıyla gönderildi: $formattedPhone');
        return true;
      } else {
        debugPrint('SMS gönderme hatası: ${response.status}');
        return false;
      }
    } catch (e) {
      debugPrint('SMS Service Error: $e');
      return false;
    }
  }
  
  /// Telefon numarasını formatla
  String _formatPhoneNumber(String phoneNumber) {
    // Boşlukları ve özel karakterleri temizle
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Eğer +90 ile başlamıyorsa ekle
    if (!cleaned.startsWith('+90')) {
      // 0 ile başlıyorsa kaldır
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
      cleaned = '+90$cleaned';
    }
    
    return cleaned;
  }
  
  /// SMS davet mesajı oluştur
  String _createInvitationMessage(String senderName, String relationship) {
    return '''🎯 Merhaba!

$senderName seni Görücü Matchmaker uygulamasında görücüsü olarak davet ediyor! 

👥 Bu uygulamada $senderName için uygun eş adaylarını bulup önerebilirsin.

📱 Uygulamayı indirmek için:
• Play Store: "Görücü Matchmaker" ara
• App Store: "Görücü Matchmaker" ara

Yakınlık Derecesi: $relationship

Haydi, geleneksel görücülüğü modern teknoloji ile buluşturalım! ❤️''';
  }
  
  /// Test SMS gönder (development için)
  Future<bool> sendTestSMS(String phoneNumber) async {
    if (!kDebugMode) return false;
    
    return await sendInvitationSMS(
      phoneNumber: phoneNumber,
      senderName: 'Test Kullanıcı',
      relationship: 'Test',
    );
  }
}