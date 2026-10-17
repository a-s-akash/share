import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color orange = Color.fromARGB(255, 221, 94, 40);
const Color darkYellow = Color.fromARGB(255, 185, 130, 41);
const Color warningColor = Color.fromARGB(255, 171, 171, 0); //WARNING
Color darkBlue = const Color(0xF8407CA1).withValues(alpha: 0.8);
const secondaryColor = Color.fromARGB(248, 64, 124, 161);
const bgColor = Color.fromARGB(248, 64, 124, 161);
const primaryColor = Color(0xFF2697FF);
ThemeData lightTheme(context) => ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: Theme.of(context).canvasColor,
      textTheme:
          GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.copyWith(
                headlineSmall: TextStyle(color: Colors.grey[800]),
                titleLarge:
                    const TextStyle(color: Color.fromARGB(248, 64, 124, 161)),
                bodyLarge: const TextStyle(color: Colors.grey),
                bodySmall: const TextStyle(color: Colors.black),
                titleMedium: TextStyle(color: Theme.of(context).primaryColor),
                titleSmall: TextStyle(color: Colors.grey[200]),
                bodyMedium: const TextStyle(color: Colors.black),
                labelSmall:
                    const TextStyle(color: Color.fromARGB(248, 64, 124, 161)),
                displaySmall:
                    const TextStyle(color: Color.fromARGB(248, 64, 124, 161)),
              )),
      canvasColor: Colors.white,
      primaryColor: const Color.fromARGB(248, 64, 124, 161),
      cardColor: const Color.fromARGB(248, 32, 61, 78),
      secondaryHeaderColor: Colors.black,
      hoverColor: Colors.blueGrey,
      unselectedWidgetColor: Colors.grey,
      tabBarTheme:
          const TabBarThemeData(indicatorColor: Colors.red //"error color"
              ),
      focusColor: Colors.blueAccent[400],
      hintColor: const Color.fromARGB(255, 78, 153, 96), //INDETERMINATE
      // splashColor: const Color.fromARGB(255, 171, 171, 0), //WARNING
      dividerColor: Colors.orange, //MAJOR
      disabledColor: const Color.fromARGB(255, 255, 202, 61),
      dialogTheme: const DialogThemeData(
          backgroundColor: Color.fromARGB(248, 217, 232, 243)), //MINOR
      // shadowColor: const Color.fromARGB(255, 221, 94, 40),
      // highlightColor: const Color.fromARGB(255, 185, 130, 41),
    );

ThemeData darkTheme(context) => ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: bgColor,
      textTheme:
          GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.copyWith(
                headlineSmall:
                    const TextStyle(color: Color.fromARGB(255, 238, 232, 232)),
                titleLarge: const TextStyle(color: Colors.grey),
                bodyLarge: const TextStyle(color: Colors.grey),
                bodySmall: TextStyle(color: Theme.of(context).canvasColor),
                titleMedium: TextStyle(color: Colors.grey[400]),
                titleSmall: TextStyle(color: Colors.grey[200]),
                bodyMedium: TextStyle(color: Theme.of(context).canvasColor),
                labelSmall: const TextStyle(
                    color: Color.fromARGB(248, 214, 219, 223),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
                displaySmall: const TextStyle(
                    color: Color.fromARGB(248, 214, 219, 223), fontSize: 14),
              )),
      canvasColor: secondaryColor,
      primaryColor: Colors.black,
      focusColor: Colors.amber[800],
      cardColor: Colors.red.shade800,
      highlightColor: Colors.blueGrey[400],
      secondaryHeaderColor: Colors.teal[800],
      hoverColor: Colors.blueGrey,
      tabBarTheme: TabBarThemeData(indicatorColor: Colors.pinkAccent[400]),
    );
