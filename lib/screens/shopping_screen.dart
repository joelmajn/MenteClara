import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mente_clara/models/shopping_item.dart';
import 'package:mente_clara/models/category.dart';
import 'package:mente_clara/services/storage_service.dart';
import 'package:mente_clara/screens/simple_shopping_screen.dart';
import 'package:mente_clara/screens/advanced_shopping_screen.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<SimpleShoppingItem> _simpleItems = [];
  List<AdvancedShoppingItem> _advancedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShoppingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingData() async {
    setState(() => _isLoading = true);
    
    final simpleItems = await StorageService.getSimpleShoppingItems();
    final advancedItems = await StorageService.getAdvancedShoppingItems();
    
    setState(() {
      _simpleItems = simpleItems;
      _advancedItems = advancedItems;
      _isLoading = false;
    });
  }

  void _onTabChanged() {
    setState(() {}); // Refresh to update any data changes
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SimpleShoppingScreen(
                  onDataChanged: _loadShoppingData,
                ),
                AdvancedShoppingScreen(
                  onDataChanged: _loadShoppingData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pendingSimpleItems = _simpleItems.where((item) => !item.isPurchased).length;
    final runningOutItems = _advancedItems.where((item) => item.isRunningOut).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Lista de Compras',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.list,
                  label: 'Itens Pendentes',
                  value: pendingSimpleItems.toString(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.warning_rounded,
                  label: 'Acabando',
                  value: runningOutItems.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => _onTabChanged(),
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.primary,
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(
            icon: Icon(Icons.list_alt),
            text: 'Lista Simples',
          ),
          Tab(
            icon: Icon(Icons.inventory),
            text: 'Lista Avançada',
          ),
        ],
      ),
    );
  }
}