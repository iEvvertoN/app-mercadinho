import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/picking/presentation/picking_controller.dart';
import 'features/picking/presentation/picking_queue_page.dart';

/// Entrada do app no papel **separador/conferente**.
///
///     flutter run -t lib/main_picking.dart
///
/// Mesmo projeto e mesmo contrato de ERP do app do cliente e do entregador.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MercadinhoPickingApp());
}

class MercadinhoPickingApp extends StatelessWidget {
  const MercadinhoPickingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PickingController()..init()),
      ],
      child: MaterialApp(
        title: 'Separação • Mercadinho',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const PickingQueuePage(),
      ),
    );
  }
}
