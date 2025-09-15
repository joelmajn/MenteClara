import 'package:flutter/material.dart';
import 'package:mente_clara/screens/dashboard_screen.dart';
import 'package:mente_clara/screens/notes_screen.dart';
import 'package:mente_clara/screens/reminders_screen.dart';
import 'package:mente_clara/screens/shopping_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const NotesScreen(),
    const RemindersScreen(),
    const ShoppingScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      activeColor: Colors.purple,
    ),
    NavigationItem(
      icon: Icons.note_alt_rounded,
      label: 'Notas',
      activeColor: Colors.blue,
    ),
    NavigationItem(
      icon: Icons.notifications_rounded,
      label: 'Lembretes',
      activeColor: Colors.orange,
    ),
    NavigationItem(
      icon: Icons.shopping_cart_rounded,
      label: 'Compras',
      activeColor: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Mente Clara',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implementar configurações
            },
            icon: Icon(
              Icons.settings_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedItemColor: _navigationItems[_currentIndex].activeColor,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: _navigationItems.map((item) {
              final index = _navigationItems.indexOf(item);
              final isSelected = index == _currentIndex;
              
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? item.activeColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    size: 24,
                  ),
                ),
                label: item.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}