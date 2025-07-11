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
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
        home: WelcomeScreen(), // Primeira tela
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}