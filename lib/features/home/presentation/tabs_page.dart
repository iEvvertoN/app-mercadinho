import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../account/presentation/profile_page.dart';
import '../../ai_shopper/presentation/ai_personal_shopper_page.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../cart/presentation/cart_page.dart';
import '../../flyer/presentation/folheto_page.dart';
import 'home_page.dart';

/// Container Principal de Abas Persistentes (`TabsPage` com `IndexedStack`)
/// Organização oficial:
/// 0: Home (Início)
/// 1: Jornal (Folheto de Ofertas)
/// 2: Carrinho (Aba Central)
/// 3: Personal de IA (Personal Shopper)
/// 4: Perfil
class TabsPage extends StatefulWidget {
  final int initialIndex;

  const TabsPage({super.key, this.initialIndex = 0});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(
            isEmbeddedTab: true,
            onNavigateTab: _switchTab,
          ),
          const FolhetoPage(isEmbeddedTab: true),
          CartPage(
            isEmbeddedTab: true,
            onNavigateTab: _switchTab,
          ),
          AiPersonalShopperPage(
            isEmbeddedTab: true,
            onNavigateTab: _switchTab,
          ),
          const ProfilePage(isEmbeddedTab: true),
        ],
      ),
      floatingActionButton: _currentIndex == 2 ? null : _buildCartFab(context, cart),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_outlined),
            activeIcon: Icon(Icons.newspaper_rounded),
            label: 'Jornal',
          ),
          BottomNavigationBarItem(
            icon: _buildCartNavIcon(cart.itemCount, isSelected: false),
            activeIcon: _buildCartNavIcon(cart.itemCount, isSelected: true),
            label: 'Carrinho',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Personal IA',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildCartNavIcon(int itemCount, {required bool isSelected}) {
    final iconWidget = Icon(
      isSelected ? Icons.shopping_cart_rounded : Icons.shopping_cart_outlined,
    );

    if (itemCount <= 0) return iconWidget;

    return Badge(
      backgroundColor: AppColors.danger,
      label: Text(
        itemCount > 99 ? '99+' : '$itemCount',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
      child: iconWidget,
    );
  }

  Widget? _buildCartFab(BuildContext context, CartController cart) {
    if (cart.items.isEmpty) return null;

    return FloatingActionButton.extended(
      heroTag: 'tabs_cart_fab',
      onPressed: () => _switchTab(2),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      label: Row(
        children: [
          Text(
            '${cart.itemCount} itens  |  ',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'R\$ ${cart.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
