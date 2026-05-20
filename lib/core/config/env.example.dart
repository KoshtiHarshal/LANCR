// lib/core/config/env.example.dart
//
// ⚠️  DO NOT rename this file to env.dart and commit it with real keys.
//
// HOW TO USE:
// 1. Copy this file and rename the copy to env.dart
// 2. Replace the placeholder values with your actual Supabase credentials
// 3. env.dart is in .gitignore — it will never be pushed to GitHub
//
// WHERE TO FIND YOUR KEYS:
// Supabase Dashboard → Your Project → Project Settings → API

class Env {
  static const supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
  // Example: 'https://xyzabcdefg.supabase.co'

  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
// Example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
}