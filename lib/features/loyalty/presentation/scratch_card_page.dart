import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ScratchCardPage extends StatefulWidget {
  const ScratchCardPage({super.key});

  @override
  State<ScratchCardPage> createState() => _ScratchCardPageState();
}

class _ScratchCardPageState extends State<ScratchCardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Offset?> _scratchPoints = [];
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addScratchPoint(Offset localPosition) {
    setState(() {
      _scratchPoints.add(localPosition);
      if (_scratchPoints.length > 18 && !_isRevealed) {
        _isRevealed = true;
      }
    });
  }

  void _resetScratchpad() {
    setState(() {
      _scratchPoints.clear();
      _isRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Raspadinhas do Clube'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Pendentes (${appState.pendingScratches.length})'),
            Tab(text: 'Já Usadas (${appState.usedScratches.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(appState),
          _buildUsedTab(appState),
        ],
      ),
    );
  }

  Widget _buildPendingTab(AppStateController appState) {
    if (appState.pendingScratches.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Você já raspou todos os seus cartões! A cada R\$ 50,00 em compras identificadas com CPF você ganha uma nova raspadinha.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }

    final currentScratch = appState.pendingScratches.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Banner da Campanha (`query_scratch_campaign.graphql`)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.secondary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentScratch['campaign'] as String,
                        style: AppTypography.heading3.copyWith(color: AppColors.secondary),
                      ),
                      Text(
                        'Gerada por: ${currentScratch['shopDate']}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Passe o dedo na camada prateada para raspar!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Área de Raspagem Real com Dedo (`GestureDetector` + `CustomPaint`)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: double.infinity,
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fundo Premiado Revelado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: AppColors.secondary, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 64,
                          child: Lottie.asset(
                            'assets/animation/loading_winner.json',
                            repeat: true,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.emoji_events_rounded,
                              size: 54,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '🎉 PARABÉNS! VOCÊ GANHOU:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentScratch['prizeTitle'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentScratch['store'] as String,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),

                  // Camada Prateada Raspável
                  if (!_isRevealed)
                    GestureDetector(
                      onPanUpdate: (details) => _addScratchPoint(details.localPosition),
                      onTapDown: (details) {
                        for (double dx = -30; dx <= 30; dx += 15) {
                          for (double dy = -20; dy <= 20; dy += 15) {
                            _addScratchPoint(details.localPosition + Offset(dx, dy));
                          }
                        }
                      },
                      child: CustomPaint(
                        painter: _SilverFoilScratchPainter(_scratchPoints),
                        child: Center(
                          child: _scratchPoints.isEmpty
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swipe_rounded, color: Colors.white, size: 42),
                                    SizedBox(height: 8),
                                    Text(
                                      'RASPE AQUI COM O DEDO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Ou toque várias vezes para revelar seu prêmio',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_isRevealed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  appState.claimScratchPrize(currentScratch['id'] as String);
                  _resetScratchpad();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prêmio creditado imediatamente no seu saldo de Cashback!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Resgatar Prêmio para Minha Carteira'),
              ),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() => _isRevealed = true),
              icon: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('Revelar Tudo Instantaneamente'),
            ),
        ],
      ),
    );
  }

  Widget _buildUsedTab(AppStateController appState) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appState.usedScratches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = appState.usedScratches[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.emoji_events_outlined, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['prizeTitle'] as String, style: AppTypography.heading3),
                    const SizedBox(height: 2),
                    Text('Campanha: ${item['campaign']}', style: AppTypography.caption),
                    Text('Origem: ${item['shopDate']}', style: AppTypography.caption),
                    Text('Raspada em: ${item['scratchedAt']}', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SilverFoilScratchPainter extends CustomPainter {
  final List<Offset?> points;

  _SilverFoilScratchPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    // Camada metálica prateada da raspadinha
    final rect = Offset.zero & size;
    final foilPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF64748B), Color(0xFF94A3B8), Color(0xFF475569)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, foilPaint);

    // Borracha transparente onde o usuário passou o dedo
    final erasePaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 46.0
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      if (pt != null) {
        canvas.drawCircle(pt, 26, Paint()..blendMode = BlendMode.clear);
      }
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, erasePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SilverFoilScratchPainter oldDelegate) => true;
}
