import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Ponto geográfico simples, para não vazar o tipo do plugin para o domínio.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Captura de posição do entregador.
///
/// Estratégia: app aberto durante o turno (primeiro plano). Não tentamos
/// rastreamento em background aqui — em aparelho de entrada isso quebra com
/// frequência e exigiria serviço em primeiro plano, permissões extras e teste
/// em campo. A posição é coletada no momento de cada evento, que é exatamente
/// o que o protocolo precisa.
class LocationService {
  const LocationService();

  /// Última posição conhecida, sem esperar GPS novo. Barato e suficiente para
  /// carimbar um evento.
  Future<GeoPoint?> lastKnown() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return GeoPoint(position.latitude, position.longitude);
    } catch (error) {
      debugPrint('[Location] lastKnown indisponível: $error');
      return null;
    }
  }

  /// Pede permissão (uma vez) e tenta uma leitura atual com timeout curto.
  ///
  /// Nunca lança: entregar sem GPS é melhor do que não entregar.
  Future<GeoPoint?> current({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return await lastKnown();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await lastKnown();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (error) {
      debugPrint('[Location] current indisponível: $error');
      return lastKnown();
    }
  }
}
