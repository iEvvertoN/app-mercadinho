import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Central de Notificações Push + Preferências de Opt-in
/// (`NotificationsPage`, `NotificationsSettingsPage`, `query_userPushNotifications.graphql`,
/// `mutation_setUserOptin.graphql`, `mutation_financialOptin.graphql`)
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações e Alertas'),
        actions: [
          if (appState.unreadNotificationsCount > 0)
            TextButton(
              onPressed: appState.markAllNotificationsRead,
              child: const Text('Ler todas', style: TextStyle(fontSize: 12)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Caixa de Entrada (${appState.pushNotificationItems.length})'),
            const Tab(text: 'Preferências (Opt-in)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(appState),
          _buildOptinTab(appState),
        ],
      ),
    );
  }

  Widget _buildInboxTab(AppStateController appState) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appState.pushNotificationItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = appState.pushNotificationItems[index];
        final bool read = n['read'] as bool;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: read ? Colors.white : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: read ? AppColors.border : AppColors.primary.withAlpha(90),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: read ? AppColors.surfaceElevated : AppColors.primary,
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 18,
                  color: read ? AppColors.textSecondary : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            n['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: read ? FontWeight.w700 : FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          n['date'] as String,
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['body'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptinTab(AppStateController appState) {
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
              const Text('Canais de Comunicação (set_user_optin)', style: AppTypography.heading3),
              const SizedBox(height: 6),
              const Text(
                'Escolha como deseja receber alertas de ofertas do jornal, status do pedido e sorteios:',
                style: AppTypography.caption,
              ),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Notificações Push no Aplicativo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Status de entrega, raspadinhas e encartes', style: TextStyle(fontSize: 11)),
                value: appState.optinPush,
                onChanged: (v) => appState.updateOptins(push: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ofertas e Separação via WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Receba o jornal da semana e avisos do separador', style: TextStyle(fontSize: 11)),
                value: appState.optinWhatsapp,
                onChanged: (v) => appState.updateOptins(whatsapp: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alertas via SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Códigos de segurança e confirmação de compras', style: TextStyle(fontSize: 11)),
                value: appState.optinSms,
                onChanged: (v) => appState.updateOptins(sms: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Boletim de Ofertas por E-mail', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Notas fiscais eletrônicas e resumo mensal do Economiômetro', style: TextStyle(fontSize: 11)),
                value: appState.optinEmail,
                onChanged: (v) => appState.updateOptins(email: v),
              ),
              const Divider(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Opt-in Financeiro e Crediário (financial_optin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: const Text('Autorizo análise de limite para o Caderninho Digital e Cartão Queiroz', style: TextStyle(fontSize: 11)),
                value: appState.financialOptin,
                onChanged: (v) => appState.updateOptins(financial: v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

