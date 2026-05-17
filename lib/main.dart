import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dqnugzerboejkemdowhn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRxbnVnemVyYm9lamtlbWRvd2huIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyODAyNjUsImV4cCI6MjA5MTg1NjI2NX0.Nu5tzj_CPq6cIuPODulwfnNQDv1SZRnz3Wlmz6Nxeuw',
  );

  runApp(const MyApp());
}