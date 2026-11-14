import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Central de Ajuda, FAQ, Fale Conosco, Trocas/Devoluções, Sobre a Rede e Privacidade LGPD
/// (`HelpPage`, `QuestionsListPage`, `ContactUsPage`, `ExchangesAndReturnsPage`,
/// `AboutPage`, `PrivacySettingsPage`, `mutation_requestMyData.graphql`, `mutation_cancelAccount.graphql`)
class HelpSupportPrivacyPage extends StatefulWidget {
  final int initialTab;

  const HelpSupportPrivacyPage({super.key, this.initialTab = 0});

  @override
  State<HelpSupportPrivacyPage> createState() => _HelpSupportPrivacyPageState();
}

class _HelpSupportPrivacyPageState extends State<HelpSupportPrivacyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajuda, Políticas e LGPD'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'FAQ / Dúvidas'),
            Tab(text: 'Fale Conosco'),
            Tab(text: 'Trocas & Sobre'),
            Tab(text: 'Privacidade (LGPD)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildContactUsTab(),
          _buildExchangesAndAboutTab(),
          _buildLgpdPrivacyTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    final faqs = [
      {
        'category': 'Clube Queira Mais & Descontos',
        'q': 'Como ativar os preços de Clube nas lojas físicas?',
        'a': 'Basta informar seu CPF ou CNPJ no caixa ou apresentar o QR Code de Check-in na aba Cartão Clube.',
      },
      {
        'category': 'Compras Online & Pesagem',
        'q': 'Por que o valor de carnes e hortifruti pode variar alguns centavos?',
        'a': 'Itens pesáveis (weighable) são pesados na balança oficial durante a separação. Se houver diferença, você confere e aprova pelo aplicativo em Acompanhar Pedido.',
      },
      {
        'category': 'Cashback, Pontos e Raspadinhas',
        'q': 'Como funcionam as Raspadinhas e Números da Sorte?',
        'a': 'A cada R\$ 50,00 em compras identificadas com seu CPF, você ganha 1 Raspadinha Digital e 1 Número da Sorte para concorrer aos sorteios mensais.',
      },
      {
        'category': 'Pagamentos & Vale-Alimentação',
        'q': 'Posso pagar com Vale-Alimentação (Alelo, Sodexo/Pluxee, Ticket)?',
        'a': 'Sim! Aceitamos cartões de benefício e alimentação tanto no pagamento online quanto na maquininha levada pelo entregador.',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = faqs[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            title: Text(
              item['q']!,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              item['category']!,
              style: const TextStyle(fontSize: 11, color: AppColors.primary),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            children: [
              Text(
                item['a']!,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactUsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fale Conosco (mutation_contactMail)', style: AppTypography.heading3),
              const SizedBox(height: 6),
              const Text(
                'Envie elogios, dúvidas sobre pedidos ou sugestões diretamente para nossa Ouvidoria:',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assunto (Ex: Dúvida sobre entrega, Sugestão de produto)',
                  prefixIcon: Icon(Icons.topic_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Sua mensagem',
                  hintText: 'Descreva como podemos ajudar...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _subjectCtrl.clear();
                    _messageCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mensagem enviada com sucesso para o SAC Queiroz!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Enviar Mensagem'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExchangesAndAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.published_with_changes_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Política de Trocas e Devoluções', style: AppTypography.heading3),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '• Produtos perecíveis, congelados e hortifruti possuem garantia de frescor: caso algum item chegue fora do padrão ideal, fazemos a substituição imediata sem custo ou estorno em Cashback.\n'
                '• Produtos não-perecíveis podem ser trocados em até 7 dias corridos mediante apresentação do Cupom Fiscal Digital no aplicativo.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.store_mall_directory_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Sobre o Clube Queira Mais / Queiroz', style: AppTypography.heading3),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'O Clube Queira Mais une tradição de preço baixo de atacarejo com tecnologia de ponta: jornal de ofertas interativo, separação com dupla conferência de temperatura, Cupom Verde ecológico e recompensas reais a cada compra.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLgpdPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Portal de Privacidade LGPD (Lei 13.709/18)', style: AppTypography.heading3),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Você tem controle total sobre seus dados pessoais, histórico de cupons fiscais e preferências de comunicação.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.download_rounded, color: AppColors.primaryDark),
                ),
                title: const Text(
                  'Solicitar Relatório dos Meus Dados (request_my_data)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Receba por e-mail uma cópia completa dos seus dados cadastrais e histórico no Clube.',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Relatório LGPD solicitado! Enviaremos para seu e-mail cadastrado em até 48h.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Solicitar', style: TextStyle(fontSize: 11)),
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.dangerLight,
                  child: Icon(Icons.person_off_outlined, color: AppColors.danger),
                ),
                title: const Text(
                  'Excluir Conta e Anonimizar Dados (cancel_account)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger),
                ),
                subtitle: const Text(
                  'Encerra permanentemente sua participação no Clube, pontos e histórico.',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: TextButton(
                  onPressed: () => _confirmCancelAccount(context),
                  child: const Text('Excluir', style: TextStyle(color: AppColors.danger)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmCancelAccount(BuildContext context) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão de Conta (LGPD)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atenção: Ao excluir sua conta, seu saldo de pontos e raspadinhas pendentes serão encerrados. Digite sua senha para confirmar:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Sua senha atual'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Manter Minha Conta')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitação de exclusão registrada conforme diretrizes LGPD.'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      ),
    );
  }
}

