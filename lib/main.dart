import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_page.dart';
import 'features/cart/presentation/cart_controller.dart';
import 'features/picking/presentation/picking_controller.dart';
import 'features/picking/presentation/picking_queue_page.dart';
import 'features/delivery/presentation/delivery_controller.dart';
import 'features/delivery/presentation/delivery_home_page.dart';
import 'features/delivery/presentation/dispatch_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppMercadinhoUnified());
}

/// Launcher Unificado do Ecossistema Casa de Vó.
///
/// Permite que o mesmo bundle web sirva os 4 papéis da operação
/// selecionados via parâmetro `?app=...` ou rota/hash:
/// - `?app=cliente`   -> Loja do Cliente (Home, Catálogo, Vó IA, Encarte, Carrinho)
/// - `?app=picking`   -> Separação e Conferência (Fila de Tarefas, Bipar Itens, Lacre)
/// - `?app=delivery`  -> Entregador (Rota do Dia, Status, Comprovante/Senha de Entrega)
/// - `?app=dispatch`  -> Central de Despacho (Gestão de Rotas, Pedidos Faturados)
/// - `?app=hub`       -> Central de Controle com atalhos para os 4 módulos
class AppMercadinhoUnified extends StatelessWidget {
  const AppMercadinhoUnified({super.key});

  @override
  Widget build(BuildContext context) {
    String mode = 'cliente';

    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final appParam = (uri.queryParameters['app'] ?? uri.queryParameters['role'] ?? '').toLowerCase();
        final fragment = uri.fragment.toLowerCase();
        final path = uri.path.toLowerCase();

        if (appParam == 'picking' ||
            appParam == 'separacao' ||
            appParam == 'separador' ||
            fragment.contains('picking') ||
            path.contains('separador')) {
          mode = 'picking';
        } else if (appParam == 'delivery' ||
            appParam == 'entrega' ||
            appParam == 'entregador' ||
            fragment.contains('delivery') ||
            path.contains('entregador')) {
          mode = 'delivery';
        } else if (appParam == 'dispatch' ||
            appParam == 'despacho' ||
            appParam == 'gestor' ||
            fragment.contains('dispatch') ||
            path.contains('gestor')) {
          mode = 'dispatch';
        } else if (appParam == 'hub' || appParam == 'menu') {
          mode = 'hub';
        }
      } catch (_) {}
    }

    switch (mode) {
      case 'picking':
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PickingController()..init()),
          ],
          child: MaterialApp(
            title: 'Separação • Mercadinho Casa de Vó',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const PickingQueuePage(),
          ),
        );

      case 'delivery':
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DeliveryController()..init()),
          ],
          child: MaterialApp(
            title: 'Entregas • Mercadinho Casa de Vó',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const DeliveryHomePage(),
          ),
        );

      case 'dispatch':
        return MaterialApp(
          title: 'Despacho & Rotas • Mercadinho Casa de Vó',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const DispatchPage(),
        );

      case 'hub':
        return MaterialApp(
          title: 'Central Operacional • Mercadinho Casa de Vó',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const MercadinhoCentralHubPage(),
        );

      default:
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartController()),
            ChangeNotifierProvider(create: (_) => AppStateController()),
          ],
          child: MaterialApp(
            title: 'App do Mercadinho • Casa de Vó',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashPage(),
          ),
        );
    }
  }
}

/// Hub Central que permite abrir os 4 sistemas em novas abas/janelas
class MercadinhoCentralHubPage extends StatelessWidget {
  const MercadinhoCentralHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857),
        title: const Text(
          'Central Operacional • Casa de Vó',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sistemas Unificados do Mercadinho',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha qual aplicação deseja acessar ou abra em janelas separadas:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              _buildCard(
                context,
                title: '1. App do Cliente',
                subtitle: 'Catálogo CLIPP, Vó do Mercadinho IA, Encarte e Pedidos',
                icon: Icons.storefront,
                color: const Color(0xFF047857),
                appKey: 'cliente',
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                title: '2. App de Separação (Picking)',
                subtitle: 'Fila de pedidos para separar, pesagem e lacre de sacolas',
                icon: Icons.shopping_basket,
                color: const Color(0xFFD97706),
                appKey: 'picking',
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                title: '3. App do Entregador (Delivery)',
                subtitle: 'Roteiro de entregas, navegação e comprovante/senha',
                icon: Icons.two_wheeler,
                color: const Color(0xFF2563EB),
                appKey: 'delivery',
              ),
              const SizedBox(height: 16),
              _buildCard(
                context,
                title: '4. Central de Despacho (Gestor)',
                subtitle: 'Atribuição de rotas, monitoramento e status dos pedidos',
                icon: Icons.local_shipping,
                color: const Color(0xFF7C3AED),
                appKey: 'dispatch',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String appKey,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final uri = Uri.base.replace(queryParameters: {'app': appKey});
          // Redireciona na mesma janela
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const AppMercadinhoUnified(),
              settings: RouteSettings(name: '/?app=$appKey'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
