import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/delivery/presentation/dispatch_page.dart';

/// Entrada do painel de **despacho**.
///
///     flutter run -t lib/main_dispatch.dart
///
/// É a tela que fecha a ponte entre picking e entrega: escolhe os pedidos
/// faturados, atribui a um entregador e mostra a sequência calculada.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MercadinhoDispatchApp());
}

class MercadinhoDispatchApp extends StatelessWidget {
  const MercadinhoDispatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despacho • Mercadinho',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DispatchPage(),
    );
  }
}
