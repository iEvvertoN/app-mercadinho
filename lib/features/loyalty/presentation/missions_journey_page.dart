import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MissionsJourneyPage extends StatefulWidget {
  const MissionsJourneyPage({super.key});

  @override
  State<MissionsJourneyPage> createState() => _MissionsJourneyPageState();
}

class _MissionsJourneyPageState extends State<MissionsJourneyPage> {
  final Set<String> _claimedMissions = {};

  final List<Map<String, dynamic>> _journeys = [
    {
      'id': 'jrn_01',
      'name': 'Mestre do Churrasco de Novembro',
      'description': 'Compre 3 vezes no departamento de Açougue neste mês para ganhar R\$ 15,00 em Cashback + 200 Pontos.',
      'progressPercent': 1.0,
      'remainingText': 'Meta atingida! (3/3 compras no Açougue)',
      'deadline': 'Válido até 30/11/2026',
      'rewardCashback': 15.0,
      'rewardPoints': 200,
      'rules': 'Válido em compras mínimas de R\$ 40,00 no setor de Açougue com CPF identificado.',
    },
    {
      'id': 'jrn_02',
      'name': 'Cliente Fiel Quarta & Quinta Verde',
      'description': 'Realize 4 compras na Feirinha Hortifrúti para liberar um Vale-Compra de R\$ 20,00.',
      'progressPercent': 0.75,
      'remainingText': 'Falta apenas 1 compra (3/4 concluídas)',
      'deadline': 'Faltam 9 dias',
      'rewardCashback': 20.0,
      'rewardPoints': 150,
      'rules': 'Válido às quartas e quintas-feiras nas lojas Matriz e Filial.',
    },
    {
      'id': 'jrn_03',
      'name': 'Explorador do App Mercadinho',
      'description': 'Ative 5 ofertas do Jornal da Semana e faça 1 pedido com entrega ou retirada.',
      'progressPercent': 0.60,
      'remainingText': '3 de 5 etapas concluídas',
      'deadline': 'Faltam 15 dias',
      'rewardCashback': 10.0,
      'rewardPoints': 100,
      'rules': 'Recompensa creditada automaticamente ao concluir a última etapa.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jornada de Missões'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.flag_circle_rounded, color: Color(0xFFFACC15), size: 42),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MISSÕES DO MÊS (user_active_journeys)',
                        style: TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Complete desafios nas suas compras e ganhe Cashback, Vales e Pontos extras!',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._journeys.map((j) {
            final String id = j['id'] as String;
            final double progress = j['progressPercent'] as double;
            final bool isCompleted = progress >= 1.0;
            final bool isClaimed = _claimedMissions.contains(id);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCompleted ? AppColors.success : AppColors.border,
                  width: isCompleted ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.primaryLight : AppColors.secondaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCompleted ? 'META CONCLUÍDA' : (j['deadline'] as String),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted ? AppColors.primaryDark : AppColors.secondary,
                          ),
                        ),
                      ),
                      Text(
                        '+R\$ ${(j['rewardCashback'] as double).toStringAsFixed(0)} + ${j['rewardPoints']} pts',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(j['name'] as String, style: AppTypography.heading2.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(j['description'] as String, style: AppTypography.bodySmall),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(j['remainingText'] as String, style: AppTypography.caption),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isClaimed
                            ? null
                            : () {
                                setState(() => _claimedMissions.add(id));
                                appState.redeemPointsForReward(
                                  pointsCost: 0,
                                  cashbackAdded: j['rewardCashback'] as double,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recompensa da missão resgatada para sua carteira!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                        icon: Icon(isClaimed ? Icons.check : Icons.card_giftcard),
                        label: Text(isClaimed ? 'Recompensa Já Resgatada ✓' : 'Resgatar Recompensa da Missão'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

