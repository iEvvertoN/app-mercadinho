import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/location_service.dart';
import '../domain/models/delivery_models.dart';
import 'widgets/signature_pad.dart';

/// Folha de prova de entrega.
///
/// Duas provas, ambas offline: a **senha** que o cliente informa e a
/// **assinatura** de quem recebeu. A posição é anexada no momento da
/// confirmação, não digitada.
class DeliveryProofSheet extends StatefulWidget {
  const DeliveryProofSheet({
    super.key,
    required this.stop,
    required this.captureLocation,
    this.appVersion = '1.0.0',
  });

  final DeliveryStop stop;
  final Future<GeoPoint?> Function() captureLocation;
  final String appVersion;

  static Future<DeliveryProof?> show({
    required BuildContext context,
    required DeliveryStop stop,
    required Future<GeoPoint?> Function() captureLocation,
  }) {
    return showModalBottomSheet<DeliveryProof>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryProofSheet(
        stop: stop,
        captureLocation: captureLocation,
      ),
    );
  }

  @override
  State<DeliveryProofSheet> createState() => _DeliveryProofSheetState();
}

class _DeliveryProofSheetState extends State<DeliveryProofSheet> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey<SignaturePadState>();

  List<List<double>>? _signature;
  bool _submitting = false;

  bool get _hasPassword => _passwordController.text.trim().length >= 4;
  bool get _hasSignature => _signature != null && _signature!.isNotEmpty;
  bool get _canConfirm => (_hasPassword || _hasSignature) && !_submitting;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Confirmar entrega', style: AppTypography.heading2),
                const SizedBox(height: 4),
                Text(
                  'Pedido #${widget.stop.code} · ${widget.stop.customerName}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 18),
                const Text('Senha do cliente (4 dígitos)', style: AppTypography.heading3),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '0000',
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Assinatura de quem recebeu', style: AppTypography.heading3),
                const SizedBox(height: 8),
                SignaturePad(
                  key: _signatureKey,
                  onChanged: (signature) => setState(() => _signature = signature),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Basta uma das duas provas. A hora e a localização são gravadas automaticamente.',
                          style: AppTypography.caption.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canConfirm ? _confirm : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_submitting ? 'Registrando...' : 'Confirmar entrega'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);

    final point = await widget.captureLocation();
    final method = _hasPassword && _hasSignature
        ? ProofMethod.passwordAndSignature
        : (_hasSignature ? ProofMethod.signature : ProofMethod.password);

    final proof = DeliveryProof(
      orderId: widget.stop.orderId,
      method: method,
      capturedAt: DateTime.now(),
      password: _hasPassword ? _passwordController.text.trim() : null,
      signature: _signature,
      latitude: point?.latitude,
      longitude: point?.longitude,
      appVersion: widget.appVersion,
    );

    if (!mounted) return;
    Navigator.of(context).pop(proof);
  }
}
