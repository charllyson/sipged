import 'package:flutter/material.dart';

class DarkAdminTheme {
  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF1F1F2E),
      primaryColor: const Color(0xFF1F1F2E),
      cardColor: const Color(0xFF1F1F2E),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF1A1A2E),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F2E),
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.lightBlueAccent,
        unselectedLabelColor: Colors.white70,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey[900],
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1F1F2E),
      ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF2A2A3D)),
    );
  }
}
