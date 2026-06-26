import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {

  static Future<void> init() async {

    await Supabase.initialize(

      url: 'https://fafpvmnoxzhwqwbfqeso.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZhZnB2bW5veHpod3F3YmZxZXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI0MjcyMzEsImV4cCI6MjA5ODAwMzIzMX0.gLV1v6TkOslsSo8oxudoX5Rau2FyYAPo2wjt8R-AQu0',
 );

  }

}

final supabase = Supabase.instance.client;