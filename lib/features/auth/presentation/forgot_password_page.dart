import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _cpfController = TextEditingController();
  int _step = 1; // 1: CPF / Channel, 2: Token OTP, 3: Nova Senha
  String _selectedMethod = 'whatsapp';
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _onCpfChanged(String value) {
    final formatted = Validators.formatCpf(value);
    if (formatted != value) {
      _cpfController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _sendRecoveryCode() async {
    if (!Validators.isValidCpf(_cpfController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe um CPF válido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 2;
    });
  }

  Future<void> _verifyCodeAndAdvance() async {
    if (_codeController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código de 4 dígitos')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 3;
    });
  }

  Future<void> _saveNewPassword() async {
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A nova senha deve ter no mínimo 6 dígitos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha redefinida com sucesso! Faça login com a nova senha.'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recuperar Senha', style: AppTypography.heading2),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.neutralDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_step == 1) ...[
                Text(
                  'Identificação',
                  style: AppTypography.heading1.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Digite seu CPF para localizarmos seu cadastro e enviar um código de recuperação.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutralMedium),
                ),
                const SizedBox(height: 24),
                Text(
                  'CPF Cadastrado',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  onChanged: _onCpfChanged,
                  decoration: InputDecoration(
                    hintText: '000.000.000-00',
                    filled: true,
                    fillColor: AppColors.neutralLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Onde deseja receber o código?',
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'whatsapp',
                  groupValue: _selectedMethod,
                  title: const Text('WhatsApp cadastrado'),
                  subtitle: const Text('(88) 9••••-••12'),
                  secondary: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)),
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                ),
                RadioListTile<String>(
                  value: 'sms',
                  groupValue: _selectedMethod,
                  title: const Text('SMS no celular'),
                  subtitle: const Text('(88) 9••••-••12'),
                  secondary: const Icon(Icons.sms_outlined, color: AppColors.primary),
                  onChanged: (val) => setState(() => _selectedMethod = val!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendRecoveryCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Enviar Código', style: AppTypography.button.copyWith(color: Colors.white)),
                  ),
                ),
              ] else if (_step == 2) ...[
                Text(
                  'Digite o código',
                  style: AppTypography.heading1.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enviamos um código de 4 dígitos via ${_selectedMethod == 'whatsapp' ? 'WhatsApp' : 'SMS'}.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutralMedium),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0000',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.neutralLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCodeAndAdvance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Validar Código', style: AppTypography.button.copyWith(color: Colors.white)),
                  ),
                ),
              ] else ...[
                Text(
                  'Criar Nova Senha',
                  style: AppTypography.heading1.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha uma senha forte com pelo menos 6 caracteres.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.neutralMedium),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Nova senha',
                    filled: true,
                    fillColor: AppColors.neutralLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveNewPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Salvar Nova Senha', style: AppTypography.button.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
