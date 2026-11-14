import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SportsBetPage extends StatefulWidget {
  const SportsBetPage({super.key});

  @override
  State<SportsBetPage> createState() => _SportsBetPageState();
}

class _SportsBetPageState extends State<SportsBetPage> {
  final Map<String, String> _picks = {
    'match_01': 'home',
  };

  final List<Map<String, dynamic>> _matches = [
    {
      'id': 'match_01',
      'championship': 'Liga Heineken Super Zeus • Rodada 4',
      'stadium': 'Arena Castelão • Hoje 21:30',
      'homeTeam': 'Fortaleza',
      'awayTeam': 'Palmeiras',
    },
    {
      'id': 'match_02',
      'championship': 'Liga Heineken Super Zeus • Rodada 4',
      'stadium': 'Maracanã • Amanhã 16:00',
      'homeTeam': 'Flamengo',
      'awayTeam': 'São Paulo',
    },
    {
      'id': 'match_03',
      'championship': 'Liga Heineken Super Zeus • Rodada 4',
      'stadium': ' Beira-Rio • Amanhã 18:30',
      'homeTeam': 'Internacional',
      'awayTeam': 'Grêmio',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Palpite Premiado (Bolão do Clube)'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Jogos da Rodada'),
              Tab(text: 'Ranking da Liga'),
              Tab(text: 'Carteira de Palpites'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMatchesTab(appState),
            _buildRankingTab(),
            _buildWalletTab(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesTab(AppStateController appState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF065F46),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIGA HEINEKEN SUPER ZEUS',
                      style: TextStyle(color: Color(0xFFFACC15), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Dê seus palpites grátis e concorra a kits churrasco + cerveja!',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${appState.sportsBetsAvailable} palpites',
                  style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ..._matches.map((m) {
          final id = m['id'] as String;
          final currentPick = _picks[id];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(m['championship'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text(m['stadium'] as String, style: AppTypography.caption),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPickButton(id, 'home', m['homeTeam'] as String, currentPick == 'home'),
                    const SizedBox(width: 8),
                    _buildPickButton(id, 'draw', 'Empate', currentPick == 'draw'),
                    const SizedBox(width: 8),
                    _buildPickButton(id, 'away', m['awayTeam'] as String, currentPick == 'away'),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPickButton(String matchId, String pickKey, String label, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _picks[matchId] = pickKey);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Palpite registrado: $label!'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankingTab() {
    final ranking = [
      {'pos': 1, 'name': 'Raimundo Nonato M.', 'pts': 48, 'me': false},
      {'pos': 2, 'name': 'Everton da Silva (Você)', 'pts': 44, 'me': true},
      {'pos': 3, 'name': 'Carlos Alberto F.', 'pts': 41, 'me': false},
      {'pos': 4, 'name': 'Ana Paula Souza', 'pts': 38, 'me': false},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final r = ranking[idx];
        final isMe = r['me'] == true;
        return ListTile(
          tileColor: isMe ? AppColors.primaryLight : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isMe ? AppColors.primary : AppColors.border),
          ),
          leading: CircleAvatar(
            backgroundColor: isMe ? AppColors.primary : AppColors.secondaryLight,
            child: Text(
              '${r['pos']}º',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white : AppColors.secondary,
              ),
            ),
          ),
          title: Text(r['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('${r['pts']} pts', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        );
      },
    );
  }

  Widget _buildWalletTab(AppStateController appState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trocar Pontos por Palpites (mutation_exchangeBets)', style: AppTypography.heading2),
            const SizedBox(height: 6),
            Text('Seus Pontos do Clube: ${appState.pointsBalance} pts • Seus Palpites: ${appState.sportsBetsAvailable}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: appState.pointsBalance >= 300
                    ? () {
                        appState.exchangePointsForSportsBets(3);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('+3 Palpites adicionados à sua Carteira Esportiva!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Trocar 300 Pontos por +3 Palpites'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

