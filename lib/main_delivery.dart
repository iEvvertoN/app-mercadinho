import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/delivery/presentation/delivery_controller.dart';
import 'features/delivery/presentation/delivery_home_page.dart';

/// Entrada do app no papel **entregador**.
///
/// Mesmo projeto, mesma base de código e mesmo contrato de ERP do app do
/// cliente — muda o papel. Rodar com:
///
///     flutter run -t lib/main_delivery.dart
///
/// Quando houver login por papel, esta entrada passa a ser escolhida pelo
/// perfil do usuário em vez de por um alvo separado.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MercadinhoDeliveryApp());
}

class MercadinhoDeliveryApp extends StatelessWidget {
  const MercadinhoDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryController()..init()),
      ],
      child: MaterialApp(
        title: 'Entregas • Mercadinho',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DeliveryHomePage(),
      ),
    );
  }
}
