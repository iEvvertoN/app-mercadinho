import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SatisfactionSurveyPage extends StatefulWidget {
  const SatisfactionSurveyPage({super.key});

  @override
  State<SatisfactionSurveyPage> createState() => _SatisfactionSurveyPageState();
}

class _SatisfactionSurveyPageState extends State<SatisfactionSurveyPage> {
  int _selectedStars = 5;
  String _selectedCleanliness = 'Excelente';
  String _selectedQueue = 'Rápido';
  final TextEditingController _commentController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesquisa de Satisfação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _submitted
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 56),
                    const SizedBox(height: 12),
                    const Text('Muito Obrigado pela Sua Avaliação!', style: AppTypography.heading2),
                    const SizedBox(height: 6),
                    const Text(
                      'Como agradecimento (has_discounts: true), creditamos +100 Pontos no seu saldo do Clube Queira Mais!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar ao Clube'),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avalie sua última experiência no Mercadinho',
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Responda em 30 segundos e ganhe +100 Pontos no Clube (satisfactionSurveyAnswer).',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 18),
                    const Text('1. De 1 a 5 estrelas, qual sua nota geral para a loja?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (idx) {
                        final star = idx + 1;
                        return IconButton(
                          onPressed: () => setState(() => _selectedStars = star),
                          icon: Icon(
                            star <= _selectedStars ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 36,
                            color: AppColors.secondary,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    const Text('2. Como você avalia o frescor do Açougue e Hortifrúti?', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Excelente', 'Bom', 'Regular', 'Ruim'].map((opt) {
                        return ChoiceChip(
                          label: Text(opt),
                          selected: _selectedCleanliness == opt,
                          onSelected: (_) => setState(() => _selectedCleanliness = opt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('3. Tempo de atendimento no caixa / entrega:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Rápido', 'Dentro do esperado', 'Demorado'].map((opt) {
                        return ChoiceChip(
                          label: Text(opt),
                          selected: _selectedQueue == opt,
                          onSelected: (_) => setState(() => _selectedQueue = opt),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('4. Deixe uma sugestão ou elogio para nossa equipe:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Gostaria de mais opções de pães integrais à noite...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          appState.redeemPointsForReward(pointsCost: -100);
                          setState(() => _submitted = true);
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('Enviar Avaliação e Ganhar +100 Pontos'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

