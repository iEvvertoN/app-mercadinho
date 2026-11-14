import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class FriendReferralPage extends StatelessWidget {
  const FriendReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Indique um Amigo e Ganhe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF047857), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFDE047), size: 54),
                  const SizedBox(height: 12),
                  const Text(
                    'Indique Amigos para o Mercadinho!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Você ganha R\$ 10,00 em Cashback e seu amigo também ganha R\$ 10,00 na primeira compra acima de R\$ 60,00!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SEU CÓDIGO DE CONVITE:', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                            Text(
                              appState.friendCode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDark,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: appState.friendCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Código copiado! Envie para seus amigos no WhatsApp.'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copiar', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Regras de `query_award_program_friends.graphql`
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Como Funciona (award_program_friends)', style: AppTypography.heading2),
                  SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text('1', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                    title: Text('Compartilhe seu código', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Seu amigo digita seu código ao se cadastrar no aplicativo.'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text('2', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                    title: Text('Benefício do Amigo Indicado (indicated)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Ganha R\$ 10,00 de desconto imediato em compras a partir de R\$ 60,00 (validade: 15 dias).'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text('3', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                    title: Text('Sua Recompensa (indicator)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Assim que seu amigo concluir a primeira compra, R\$ 10,00 caem direto no seu Cashback!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

