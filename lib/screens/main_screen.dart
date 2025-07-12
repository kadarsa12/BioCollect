// screens/main_screen.dart (VERSÃO COM ANIMATED NOTCH)
import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  /// Controller to handle PageView and also handles initial page
  final _pageController = PageController(initialPage: 0);

  /// Controller to handle bottom nav bar and also handles initial page
  final NotchBottomBarController _controller = NotchBottomBarController(index: 0);

  int maxCount = 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// widget list
    final List<Widget> bottomBarPages = [
      HomeScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(bottomBarPages.length, (index) => bottomBarPages[index]),
      ),
      extendBody: false, // <- MUDOU PARA false
      bottomNavigationBar: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom, // <- ADICIONA MARGEM PARA OS BOTÕES DO SISTEMA
        ),
        child: AnimatedNotchBottomBar(
          /// Provide NotchBottomBarController
          notchBottomBarController: _controller,
          color: Colors.white,
          showLabel: true,
          textOverflow: TextOverflow.visible,
          maxLine: 1,
          shadowElevation: 5,
          kBottomRadius: 28.0,

          notchColor: Color(0xFF8D6E63),

          /// restart app if you change removeMargins
          removeMargins: false,
          bottomBarWidth: 500,
          showShadow: false,
          durationInMilliSeconds: 300,

          itemLabelStyle: const TextStyle(fontSize: 10),

          elevation: 1,
          bottomBarItems: const [
            BottomBarItem(
              inActiveItem: Icon(
                Icons.assignment_outlined,
                color: Colors.blueGrey,
              ),
              activeItem: Icon(
                Icons.assignment,
                color: Colors.white,
              ),
              itemLabel: 'Projetos',
            ),
            BottomBarItem(
              inActiveItem: Icon(
                Icons.settings_outlined,
                color: Colors.blueGrey,
              ),
              activeItem: Icon(
                Icons.settings,
                color: Colors.white,
              ),
              itemLabel: 'Configurações',
            ),
          ],
          onTap: (index) {
            log('current selected index $index');
            _pageController.jumpToPage(index);
          },
          kIconSize: 24.0,
        ),
      ),
    );
  }
}

// Função de log simples (adicione no topo do arquivo)
void log(String message) {
  print(message);
}