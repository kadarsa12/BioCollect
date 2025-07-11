import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'providers/user_provider.dart';
import 'providers/project_provider.dart';
import 'utils/database_helper.dart';

void main() async {
  // Inicialização necessária para usar plugins nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar banco de dados
  await DatabaseHelper.instance.database;

  runApp(MyApp());
}
MaterialColor _createBrownSwatch() {
  return MaterialColor(
    0xFF8D6E63,
    <int, Color>{
      50: Color(0xFFEFEBE9),
      100: Color(0xFFD7CCC8),
      200: Color(0xFFBCAAA4),
      300: Color(0xFFA1887F),
      400: Color(0xFF8D6E63), // Primary
      500: Color(0xFF795548),
      600: Color(0xFF6D4C41),
      700: Color(0xFF5D4037), // Accent
      800: Color(0xFF4E342E),
      900: Color(0xFF3E2723),
    },
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Gerenciadores de estado
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'BioCollect',
        theme: ThemeData(
          // Paleta Marrom Terra
          primarySwatch: _createBrownSwatch(),
          primaryColor: Color(0xFF8D6E63), // Brown 400
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF8D6E63),
            brightness: Brightness.light,
          ),

          // AppBar personalizado
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF8D6E63), // Brown 400
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),

          // Cards modernos
          cardTheme: CardThemeData(
            color: Color(0xFFF5F5F5), // Grey 100 (fundo neutro)
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Botões
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8D6E63), // Brown 400
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),

          // FAB
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF5D4037), // Brown 700 (mais escuro)
            foregroundColor: Colors.white,
          ),

          // Input fields
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF8D6E63), width: 2),
            ),
          ),

          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: WelcomeScreen(), // Primeira tela
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}