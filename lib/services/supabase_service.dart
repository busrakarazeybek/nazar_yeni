import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  final Future<void> _initFuture;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() : _initFuture = _initializeSupabase();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: "https://haqfiojlxsfwgpznvtbk.supabase.co");
  static const String supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhhcWZpb2pseHNmd2dwem52dGJrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMjY3NDYsImV4cCI6MjA2NjYwMjc0Nn0.xBPW9Lmkt7_B801ok4D6K6vqK9avboW6L50qchjFa6o");

  // Internal initialization logic
  static Future<void> _initializeSupabase() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _instance._client = Supabase.instance.client;
    _instance._isInitialized = true;
  }

  // Client getter (async)
  Future<SupabaseClient> get client async {
    if (!_isInitialized) {
      await _initFuture;
    }
    return _client;
  }

  // Synchronous client getter (use only after initialization)
  SupabaseClient get syncClient {
    if (!_isInitialized) {
      throw Exception(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return _client;
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Initialize method for explicit initialization
  Future<void> initialize() async {
    if (!_isInitialized) {
      await _initFuture;
    }
  }
}
