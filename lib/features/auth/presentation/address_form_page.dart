import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';

class AddressFormPage extends StatefulWidget {
  final Map<String, dynamic>? initialAddress;

  const AddressFormPage({super.key, this.initialAddress});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _complementController = TextEditingController();
  final _referenceController = TextEditingController();

  bool _isSearchingCep = false;
  String _tag = 'Casa'; // Casa, Trabalho, Outro

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _cepController.text = widget.initialAddress!['cep'] ?? '';
      _streetController.text = widget.initialAddress!['street'] ?? '';
      _numberController.text = widget.initialAddress!['number'] ?? '';
      _neighborhoodController.text = widget.initialAddress!['neighborhood'] ?? '';
      _cityController.text = widget.initialAddress!['city'] ?? '';
      _complementController.text = widget.initialAddress!['complement'] ?? '';
      _referenceController.text = widget.initialAddress!['reference'] ?? '';
      _tag = widget.initialAddress!['tag'] ?? 'Casa';
    }
  }

  @override
  void dispose() {
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _complementController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _onCepChanged(String value) {
    final formatted = Validators.formatCep(value);
    if (formatted != value) {
      _cepController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    if (value.replaceAll(RegExp(r'\D'), '').length == 8) {
      _lookupCep(value);
    }
  }

  Future<void> _lookupCep(String cep) async {
    setState(() => _isSearchingCep = true);

    // Simulate query_find_cep.graphql lookup
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() {
      _isSearchingCep = false;
      _streetController.text = 'Av. Coronel José Inácio';
      _neighborhoodController.text = 'Centro';
      _cityController.text = 'Iguatu - CE';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço localizado com sucesso! Preencha o número.'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveAddress() {
    if (_streetController.text.trim().isEmpty || _numberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe a rua e o número do imóvel.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final newAddress = {
      'tag': _tag,
      'cep': _cepController.text,
      'street': _streetController.text,
      'number': _numberController.text,
      'neighborhood': _neighborhoodController.text,
      'city': _cityController.text,
      'complement': _complementController.text,
      'reference': _referenceController.text,
      'isDefault': true,
    };

    Navigator.of(context).pop(newAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.initialAddress != null ? 'Editar Endereço' : 'Novo Endereço',
          style: AppTypography.heading2,
        ),
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
              // Tag Selector (Casa / Trabalho / Outro)
              Text(
                'Identificar este endereço como:',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Casa', 'Trabalho', 'Outro'].map((tag) {
                  final isSelected = _tag == tag;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tag),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.neutralDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _tag = tag);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // CEP Field with Loader
              Text('CEP', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                onChanged: _onCepChanged,
                decoration: InputDecoration(
                  hintText: '00000-000',
                  suffixIcon: _isSearchingCep
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: AppColors.primary),
                          onPressed: () => _lookupCep(_cepController.text),
                        ),
                  filled: true,
                  fillColor: AppColors.neutralLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Street
              Text('Logradouro / Rua', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _streetController,
                decoration: _fieldDecoration('Ex: Rua das Flores'),
              ),
              const SizedBox(height: 16),

              // Number and Complement Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Número', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _numberController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('123'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Complemento', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _complementController,
                          decoration: _fieldDecoration('Apt, Bloco...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Neighborhood and City
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bairro', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _neighborhoodController,
                          decoration: _fieldDecoration('Bairro'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cidade', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cityController,
                          decoration: _fieldDecoration('Cidade - UF'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reference / Instructions
              Text(
                'Ponto de Referência / Instruções de Entrega',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _referenceController,
                maxLines: 2,
                decoration: _fieldDecoration('Ex: Portão branco, ao lado da padaria. Tocar interfone.'),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Salvar Endereço',
                    style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
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

