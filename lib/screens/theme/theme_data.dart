import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color.fromRGBO(255, 248, 245, 1),
  primaryColorDark: const Color.fromRGBO(130, 115, 151, 1),
  primaryColorLight: Colors.white,
  textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Color.fromRGBO(130, 115, 151, 1),
  ),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all(Color.fromRGBO(249, 238, 236, 1)),
  ),  
  shadowColor: Colors.white,
  canvasColor: Color.fromRGBO(186, 175, 193, 1),     //border side
  cardColor: Color.fromRGBO(218, 208, 217, 1)         // profile Tile
  
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color.fromRGBO(24, 16, 15, 1),
  primaryColorDark: Color.fromRGBO(122, 68, 76, 1),
  primaryColorLight: Color.fromRGBO(122, 68, 76, 1),
  textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    selectedItemColor: Colors.black,
  ),
  searchBarTheme: SearchBarThemeData(
    backgroundColor: WidgetStateProperty.all(const Color.fromRGBO(62, 56, 55, 1)),
  ),
  shadowColor: Colors.black,
  canvasColor: Color.fromRGBO(74, 42, 45, 1),      //border side
  cardColor: Color.fromRGBO(122, 68, 76, 1),         // profile Tile
);
