// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildWebBarcodeScanner({
  required ValueChanged<String> onBarcodeDetected,
  required bool torchEnabled,
}) {
  return _WebBarcodeScannerWidget(
    onBarcodeDetected: onBarcodeDetected,
    torchEnabled: torchEnabled,
  );
}

class _WebBarcodeScannerWidget extends StatefulWidget {
  final ValueChanged<String> onBarcodeDetected;
  final bool torchEnabled;

  const _WebBarcodeScannerWidget({
    required this.onBarcodeDetected,
    required this.torchEnabled,
  });

  @override
  State<_WebBarcodeScannerWidget> createState() => _WebBarcodeScannerWidgetState();
}

class _WebBarcodeScannerWidgetState extends State<_WebBarcodeScannerWidget> {
  static int _viewCounter = 0;
  late final String _viewType;
  late final html.VideoElement _videoElement;

  String _status = 'IDLE'; // IDLE, STARTING, ACTIVE, INSECURE_CONTEXT, ERROR
  String _statusMessage = 'Toque abaixo para ligar a câmera traseira e ler códigos de barras.';

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'mercadinho-web-scanner-$_viewCounter';

    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.backgroundColor = '#0F172A';
    _videoElement.setAttribute('playsinline', 'true');
    _videoElement.setAttribute('webkit-playsinline', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement,
    );

    // Tenta iniciar automaticamente após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLiveCamera();
    });
  }

  @override
  void didUpdateWidget(covariant _WebBarcodeScannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.torchEnabled != widget.torchEnabled) {
      _setTorch(widget.torchEnabled);
    }
  }

  @override
  void dispose() {
    _stopLiveCamera();
    super.dispose();
  }

  void _setTorch(bool enabled) {
    try {
      final scanner = js.context['MercadinhoWebScanner'];
      if (scanner != null) {
        scanner.callMethod('setTorch', [enabled]);
      }
    } catch (_) {}
  }

  void _startLiveCamera() {
    try {
      final scanner = js.context['MercadinhoWebScanner'];
      if (scanner == null) {
        setState(() {
          _status = 'ERROR';
          _statusMessage = 'Motor de leitura Web não carregado. Recarregue a página (F5).';
        });
        return;
      }

      scanner.callMethod('start', [
        _videoElement,
        js.allowInterop((dynamic code) {
          if (!mounted) return;
          final str = (code ?? '').toString().trim();
          if (str.isNotEmpty) {
            widget.onBarcodeDetected(str);
          }
        }),
        js.allowInterop((dynamic status, dynamic message) {
          if (!mounted) return;
          setState(() {
            _status = (status ?? 'ERROR').toString();
            _statusMessage = (message ?? '').toString();
          });
        }),
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'ERROR';
        _statusMessage = 'Falha ao acessar câmera: $e';
      });
    }
  }

  void _stopLiveCamera() {
    try {
      final scanner = js.context['MercadinhoWebScanner'];
      if (scanner != null) {
        scanner.callMethod('stop', []);
      }
    } catch (_) {}
  }

  /// Abre a câmera nativa do sistema operacional (`<input type="file" capture="environment">`)
  /// que funciona 100% mesmo em conexões HTTP sem HTTPS!
  void _openNativeSnapshotCamera() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment');

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final file = files.first;

      setState(() {
        _statusMessage = 'Lendo código de barras da foto...';
      });

      final scanner = js.context['MercadinhoWebScanner'];
      if (scanner != null) {
        scanner.callMethod('decodeImageFile', [
          file,
          js.allowInterop((dynamic code) {
            if (!mounted) return;
            final str = (code ?? '').toString().trim();
            if (str.isNotEmpty) {
              setState(() {
                _statusMessage = 'Código lido com sucesso: $str';
              });
              widget.onBarcodeDetected(str);
            }
          }),
          js.allowInterop((dynamic errMsg) {
            if (!mounted) return;
            setState(() {
              _statusMessage = (errMsg ?? 'Não foi possível ler o código na foto.').toString();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.orange.shade800,
                content: Text(_statusMessage),
              ),
            );
          }),
        ]);
      }
    });

    input.click();
  }

  void _redirectToHttps() {
    final host = html.window.location.hostname ?? '192.168.101.51';
    html.window.location.href = 'https://$host:8443';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCameraActive = _status == 'ACTIVE';
    final bool isInsecure = _status == 'INSECURE_CONTEXT';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Vídeo ao vivo da câmera HTML5
        HtmlElementView(viewType: _viewType),

        // Se a câmera ao vivo ainda não abriu ou se o navegador bloqueou por ser HTTP
        if (!isCameraActive)
          Container(
            color: const Color(0xFF0F172A).withOpacity(0.94),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isInsecure ? Icons.lock_open_rounded : Icons.qr_code_scanner_rounded,
                      color: const Color(0xFF10B981),
                      size: 44,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isInsecure
                          ? 'Câmera Ao Vivo Requer HTTPS ou Câmera Instantânea'
                          : 'Leitor de Código de Barras do Celular',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        if (!isInsecure)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _startLiveCamera,
                            icon: const Icon(Icons.videocam_rounded, size: 18),
                            label: const Text(
                              'Ativar Câmera Ao Vivo',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        if (isInsecure)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _redirectToHttps,
                            icon: const Icon(Icons.https_rounded, size: 18),
                            label: const Text(
                              'Abrir em HTTPS (Câmera Ao Vivo)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onPressed: _openNativeSnapshotCamera,
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text(
                            'Ler pela Câmera do Celular (Foto)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Botão flutuante no canto quando a câmera ao vivo está ligada para alternar para foto se quiser
        if (isCameraActive)
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.65),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
              onPressed: _openNativeSnapshotCamera,
              icon: const Icon(Icons.camera_alt_outlined, size: 15),
              label: const Text('Capturar Foto', style: TextStyle(fontSize: 11)),
            ),
          ),
      ],
    );
  }
}

