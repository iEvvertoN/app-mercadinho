import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Dados Pessoais, Validação de E-mail, Troca de Senha e CRM Socioeconômico
/// (`PersonalInfoPage`, `ChangePasswordPage`, `mutation_updateUser.graphql`,
/// `mutation_validationEmail.graphql`, `query_professions.graphql`, `query_incomeRanges.graphql`)
class PersonalInfoCrmPage extends StatefulWidget {
  const PersonalInfoCrmPage({super.key});

  @override
  State<PersonalInfoCrmPage> createState() => _PersonalInfoCrmPageState();
}

class _PersonalInfoCrmPageState extends State<PersonalInfoCrmPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthCtrl;
  late String _profession;
  late String _maritalStatus;
  late String _education;
  late String _incomeRange;
  late int _residents;
  late int _children;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateController>();
    _nameCtrl = TextEditingController(text: appState.userName);
    _emailCtrl = TextEditingController(text: appState.userEmail);
    _phoneCtrl = TextEditingController(text: appState.userPhone);
    _birthCtrl = TextEditingController(text: appState.userBirthDate);
    _profession = appState.profession;
    _maritalStatus = appState.maritalStatus;
    _education = appState.educationLevel;
    _incomeRange = appState.incomeRange;
    _residents = appState.residentsNumber;
    _children = appState.childrenNumber;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _birthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dados Pessoais e CRM'),
        actions: [
          TextButton.icon(
            onPressed: () => _openChangePasswordModal(context),
            icon: const Icon(Icons.lock_reset_rounded, size: 18),
            label: const Text('Senha'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Validação de E-mail (`validation_email` / `confirm_validation_email`)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appState.emailValidated ? AppColors.primaryLight : AppColors.warningLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    appState.emailValidated ? Icons.verified_user_rounded : Icons.mark_email_unread_outlined,
                    color: appState.emailValidated ? AppColors.primaryDark : AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.emailValidated
                          ? 'E-mail verificado com sucesso (${appState.userEmail})'
                          : 'Confirme seu e-mail para receber notas fiscais e alertas de sorteios.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: appState.emailValidated ? AppColors.primaryDark : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  if (!appState.emailValidated)
                    ElevatedButton(
                      onPressed: () {
                        appState.confirmEmailValidation();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('E-mail validado com sucesso!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Validar Agora', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dados Cadastrais Básicos
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
                  const Text('Identificação Cadastral', style: AppTypography.heading3),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'Conta Pessoa Jurídica / Atacado (is_cnpj)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      appState.isCnpj ? 'CNPJ: ${appState.userDocument}' : 'CPF: ${appState.userDocument}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: appState.isCnpj,
                    onChanged: (v) {
                      appState.updateProfile(
                        isCnpj: v,
                        document: v ? '12.345.678/0001-90' : '123.456.789-00',
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo / Razão Social',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'E-mail Principal',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Celular / WhatsApp',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _birthCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nascimento',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Perfil Socioeconômico CRM (query_professions, query_maritalStatuses, query_incomeRanges)
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
                      Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Perfil Socioeconômico Clube (CRM)', style: AppTypography.heading3),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Usado para personalizar ofertas do jornal e pacotes familiares:',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 14),
                  _buildDropdownField(
                    label: 'Profissão (professions)',
                    value: _profession,
                    items: const [
                      'Comerciante / Autônomo',
                      'Servidor Público',
                      'Profissional Liberal',
                      'Empresário / Atacadista',
                      'Estudante / Aposentado',
                    ],
                    onChanged: (v) => setState(() => _profession = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Estado Civil (marital_statuses)',
                    value: _maritalStatus,
                    items: const ['Solteiro(a)', 'Casado(a)', 'União Estável', 'Divorciado(a)'],
                    onChanged: (v) => setState(() => _maritalStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Escolaridade (education_levels)',
                    value: _education,
                    items: const [
                      'Ensino Fundamental',
                      'Ensino Médio Completo',
                      'Ensino Superior',
                      'Pós-Graduação',
                    ],
                    onChanged: (v) => setState(() => _education = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Faixa de Renda Familiar (income_ranges)',
                    value: _incomeRange,
                    items: const [
                      'Até R\$ 2.000',
                      'R\$ 2.000 a R\$ 4.500',
                      'R\$ 4.500 a R\$ 8.000',
                      'Acima de R\$ 8.000',
                    ],
                    onChanged: (v) => setState(() => _incomeRange = v!),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCounterBox(
                          label: 'Pessoas na Casa',
                          value: _residents,
                          onMinus: () => setState(() => _residents = (_residents - 1).clamp(1, 15)),
                          onPlus: () => setState(() => _residents = (_residents + 1).clamp(1, 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCounterBox(
                          label: 'Filhos / Dependentes',
                          value: _children,
                          onMinus: () => setState(() => _children = (_children - 1).clamp(0, 12)),
                          onPlus: () => setState(() => _children = (_children + 1).clamp(0, 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  appState.updateProfile(
                    name: _nameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    birthDate: _birthCtrl.text.trim(),
                    profession: _profession,
                    maritalStatus: _maritalStatus,
                    educationLevel: _education,
                    incomeRange: _incomeRange,
                    residentsCount: _residents,
                    childrenCount: _children,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dados pessoais e perfil CRM atualizados com sucesso!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar Alterações (updateUser)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(labelText: label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCounterBox({
    required String label,
    required int value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('$value', style: AppTypography.heading2),
              ),
              IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openChangePasswordModal(BuildContext context) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Senha (ChangePasswordPage)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha Atual'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova Senha (mín. 6 dígitos)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Senha alterada com sucesso!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Atualizar Senha'),
          ),
        ],
      ),
    );
  }
}

