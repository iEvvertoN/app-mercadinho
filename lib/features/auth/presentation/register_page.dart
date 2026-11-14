import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../home/presentation/tabs_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;
  bool _isCnpj = false;
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _friendCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _friendCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCpfChanged(String value) {
    if (_isCnpj) return;
    final formatted = Validators.formatCpf(value);
    if (formatted != value) {
      _cpfController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onPhoneChanged(String value) {
    final formatted = Validators.formatPhone(value);
    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Por favor, informe seu nome completo ou razão social');
        return;
      }
      if (!_isCnpj && !Validators.isValidCpf(_cpfController.text)) {
        _showError('CPF inválido. Verifique os dígitos digitados.');
        return;
      }
    } else if (_currentStep == 1) {
      if (_phoneController.text.length < 14) {
        _showError('Informe um celular válido com DDD');
        return;
      }
      if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
        _showError('Informe um e-mail válido');
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _submitRegistration();
    }
  }

  Future<void> _submitRegistration() async {
    if (_passwordController.text.length < 6) {
      _showError('A senha deve ter no mínimo 6 dígitos');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('As senhas não coincidem');
      return;
    }
    if (!_acceptTerms) {
      _showError('Você precisa aceitar os Termos e Condições para continuar');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Cadastro concluído com sucesso! Bem-vindo(a)!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const TabsPage()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Criar Conta no Clube', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppColors.neutralLight,
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Dados'),
                  _buildStepLine(0),
                  _buildStepIndicator(1, 'Contato'),
                  _buildStepLine(1),
                  _buildStepIndicator(2, 'Segurança'),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildCurrentStepContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep == 2 ? 'Finalizar Cadastro' : 'Continuar',
                          style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isDone = _currentStep > stepIndex;
    final isCurrent = _currentStep == stepIndex;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? AppColors.success
              : (isCurrent ? AppColors.primary : Colors.grey.shade400),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? AppColors.neutralDark : AppColors.neutralMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        color: isDone ? AppColors.success : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Identificação Cadastral', style: AppTypography.heading1.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Cadastro Pessoa Jurídica / Atacado (is_cnpj)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              value: _isCnpj,
              onChanged: (v) => setState(() => _isCnpj = v),
            ),
            const SizedBox(height: 12),
            _buildFieldTitle(_isCnpj ? 'Razão Social / Nome Fantasia' : 'Nome Completo'),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Ex: Everton da Silva', Icons.person_outline),
            ),
            const SizedBox(height: 16),
            _buildFieldTitle(_isCnpj ? 'CNPJ' : 'CPF'),
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              onChanged: _onCpfChanged,
              decoration: _inputDecoration(
                _isCnpj ? '00.000.000/0001-00' : '000.000.000-00',
                Icons.badge_outlined,
              ),
            ),
            const SizedBox(height: 16),
            _buildFieldTitle('Data de Nascimento / Fundação'),
            TextField(
              controller: _birthDateController,
              keyboardType: TextInputType.datetime,
              decoration: _inputDecoration('DD/MM/AAAA', Icons.calendar_today_outlined),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contato e Indicação', style: AppTypography.heading1.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'Para receber avisos de separação, cupom fiscal e bônus de amigo.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutralMedium),
            ),
            const SizedBox(height: 20),
            _buildFieldTitle('Celular / WhatsApp'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              onChanged: _onPhoneChanged,
              decoration: _inputDecoration('(88) 99999-9999', Icons.phone_android_outlined),
            ),
            const SizedBox(height: 16),
            _buildFieldTitle('E-mail'),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration('seu.email@exemplo.com', Icons.email_outlined),
            ),
            const SizedBox(height: 16),
            _buildFieldTitle('Código de Indicação de Amigo (friend_code - opcional)'),
            TextField(
              controller: _friendCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: _inputDecoration('Ex: QUEIROZ2026', Icons.card_giftcard_outlined),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crie sua Senha', style: AppTypography.heading1.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'Crie uma senha de acesso para usar no app e consultar seu crediário.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.neutralMedium),
            ),
            const SizedBox(height: 24),
            _buildFieldTitle('Senha de Acesso'),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: _inputDecoration('Mínimo 6 dígitos', Icons.lock_outline),
            ),
            const SizedBox(height: 16),
            _buildFieldTitle('Confirmar Senha'),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: _inputDecoration('Repita a mesma senha', Icons.lock_outline),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _acceptTerms,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _acceptTerms = val ?? true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Li e concordo com os Termos de Uso e Política de Privacidade LGPD do Clube Queira Mais.',
                    style: AppTypography.caption.copyWith(color: AppColors.neutralDark),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.neutralDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.neutralMedium),
      filled: true,
      fillColor: AppColors.neutralLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
