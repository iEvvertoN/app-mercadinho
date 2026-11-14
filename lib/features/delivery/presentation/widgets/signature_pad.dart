import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Captura de assinatura no dedo.
///
/// A assinatura é a prova escolhida para o MVP: não exige câmera, funciona
/// offline e é verificável por qualquer pessoa depois. Os pontos são devolvidos
/// normalizados (0..1), então o traço não depende do tamanho da tela.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.height = 180,
    this.onChanged,
  });

  final double height;
  final ValueChanged<List<List<double>>?>? onChanged;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  Size _canvasSize = Size.zero;

  bool get isEmpty => _strokes.isEmpty;

  void clear() {
    setState(_strokes.clear);
    widget.onChanged?.call(null);
  }

  void _emit() {
    if (_canvasSize.width <= 0 || _canvasSize.height <= 0) {
      widget.onChanged?.call(null);
      return;
    }
    final points = <List<double>>[];
    for (final stroke in _strokes) {
      for (final point in stroke) {
        points.add([
          (point.dx / _canvasSize.width).clamp(0.0, 1.0),
          (point.dy / _canvasSize.height).clamp(0.0, 1.0),
        ]);
      }
    }
    widget.onChanged?.call(points.isEmpty ? null : points);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _strokes.isEmpty ? AppColors.border : AppColors.primary,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) {
                  setState(() => _strokes.add([details.localPosition]));
                  _emit();
                },
                onPanUpdate: (details) {
                  if (_strokes.isEmpty) return;
                  setState(() => _strokes.last.add(details.localPosition));
                  _emit();
                },
                onPanEnd: (_) => _emit(),
                child: CustomPaint(
                  painter: _SignaturePainter(_strokes),
                  size: Size.infinite,
                  child: _strokes.isEmpty
                      ? Center(
                          child: Text(
                            'Assine aqui com o dedo',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Expanded(
              child: Text(
                'A assinatura fica registrada com hora e localização.',
                style: AppTypography.caption,
              ),
            ),
            TextButton.icon(
              onPressed: _strokes.isEmpty ? null : clear,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Limpar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
