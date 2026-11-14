import 'package:flutter/material.dart';

import 'web_barcode_scanner_stub.dart'
    if (dart.library.html) 'web_barcode_scanner_html.dart';

class WebBarcodeScannerView extends StatelessWidget {
  final ValueChanged<String> onBarcodeDetected;
  final bool torchEnabled;

  const WebBarcodeScannerView({
    super.key,
    required this.onBarcodeDetected,
    this.torchEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return buildWebBarcodeScanner(
      onBarcodeDetected: onBarcodeDetected,
      torchEnabled: torchEnabled,
    );
  }
}

