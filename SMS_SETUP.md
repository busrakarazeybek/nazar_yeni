# SMS Integration Setup for Görücü Matchmaker

This document explains how to set up SMS functionality for inviting new selectors through phone contacts.

## Overview

The app now includes SMS functionality that allows users to send invitations to their phone contacts. This feature uses:
- **Flutter Contacts Plugin**: Access phone contacts
- **Supabase Edge Functions**: Backend SMS processing  
- **Twilio API**: SMS delivery service

## Prerequisites

### 1. Twilio Account Setup
1. Create a Twilio account at https://twilio.com
2. Get your Account SID and Auth Token from the Twilio Console
3. Purchase a Twilio phone number for sending SMS

### 2. Supabase Project Configuration
1. Go to your Supabase Dashboard
2. Navigate to Settings → Edge Functions
3. Add the following environment variables:
   - `TWILIO_ACCOUNT_SID`: Your Twilio Account SID
   - `TWILIO_AUTH_TOKEN`: Your Twilio Auth Token  
   - `TWILIO_PHONE_NUMBER`: Your Twilio phone number (e.g., +1234567890)

## Deployment Steps

### 1. Deploy Edge Function
```bash
# Install Supabase CLI if not already installed
npm install -g @supabase/supabase-cli

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the SMS function
supabase functions deploy send-sms
```

### 2. Set Environment Variables
```bash
# Set Twilio credentials in Supabase
supabase secrets set TWILIO_ACCOUNT_SID=your_account_sid
supabase secrets set TWILIO_AUTH_TOKEN=your_auth_token  
supabase secrets set TWILIO_PHONE_NUMBER=+1234567890
```

### 3. Test the Function
```bash
# Test the function locally
supabase functions serve send-sms

# Or test deployed function
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-sms' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "to": "+905551234567",
    "message": "Test SMS from Görücü Matchmaker",
    "sender_name": "Test User",
    "relationship": "Test"
  }'
```

## App Configuration

### 1. Environment Variables (env.json)
Add Twilio test credentials to your `env.json` file for development:
```json
{
  "SUPABASE_URL": "your_supabase_url",
  "SUPABASE_ANON_KEY": "your_anon_key",
  "TWILIO_TEST_MODE": "true"
}
```

### 2. Permissions
The app automatically requests the following permissions:
- **Android**: `READ_CONTACTS`, `WRITE_CONTACTS`
- **iOS**: `NSContactsUsageDescription`

## Features

### 1. Phone Contacts Integration
- Access user's phone contacts
- Filter contacts with phone numbers
- Search and select contacts for invitations

### 2. SMS Invitation System
- Custom Turkish invitation message
- Automatic phone number formatting (+90 for Turkey)
- Loading states and error handling
- Success/failure feedback

### 3. Relationship Degree Tracking  
- Select relationship type (Aile, Arkadaş, Akraba, İş Arkadaşı)
- Track relationship context for better matching

## SMS Message Template

The app sends the following Turkish message template:

```
🎯 Merhaba!

[Sender Name] seni Görücü Matchmaker uygulamasında görücüsü olarak davet ediyor! 

👥 Bu uygulamada [Sender Name] için uygun eş adaylarını bulup önerebilirsin.

📱 Uygulamayı indirmek için:
• Play Store: "Görücü Matchmaker" ara
• App Store: "Görücü Matchmaker" ara

Yakınlık Derecesi: [Relationship]

Haydi, geleneksel görücülüğü modern teknoloji ile buluşturalım! ❤️
```

## Error Handling

The system handles various error scenarios:
- Missing Twilio configuration
- Invalid phone numbers  
- Network connectivity issues
- Twilio API errors
- Rate limiting

## Security Considerations

1. **Environment Variables**: Never commit Twilio credentials to version control
2. **Rate Limiting**: Implement rate limiting to prevent spam
3. **Phone Validation**: Validate phone numbers before sending
4. **User Consent**: Ensure users consent before sending SMS invitations

## Testing

### Development Mode
- Use `SMSService().sendTestSMS()` for testing
- Test with your own phone number first
- Monitor Twilio logs for delivery status

### Production Deployment
1. Verify all environment variables are set
2. Test with real phone numbers
3. Monitor delivery rates and costs
4. Set up error alerting

## Cost Considerations

- Twilio SMS pricing varies by destination country
- Turkey (TR): ~$0.05 per SMS
- Monitor usage in Twilio Console
- Set up billing alerts to prevent unexpected charges

## Support

For issues with:
- **Twilio Integration**: Check Twilio Console logs
- **Supabase Functions**: Check Supabase Dashboard logs
- **Flutter Contacts**: Verify device permissions

## Future Enhancements

Planned improvements:
- WhatsApp integration via Twilio
- SMS delivery tracking
- Bulk invitation features
- Multi-language message templates