import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/delivery_api_service.dart';

/// Tela de despacho: escolhe pedidos faturados, atribui a um entregador e
/// mostra a **sequência calculada pelo servidor** antes de liberar.
class DispatchPage extends StatefulWidget {
  const DispatchPage({super.key});

  @override
  State<DispatchPage> createState() => _DispatchPageState();
}

class _DispatchPageState extends State<DispatchPage> {
  final DeliveryApiService _api = DeliveryApiService();
  final TextEditingController _courierController =
      TextEditingController(text: 'entregador-01');

  List<Map<String, dynamic>> _orders = const [];
  final Set<String> _selected = <String>{};
  Map<String, dynamic>? _route;
  bool _loading = false;
  bool _assigning = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_loading && !_assigning) {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _courierController.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final response = await _api.fetchDispatch();
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (response.ok && response.data != null) {
        final raw = (response.data!['orders'] as List?) ?? const [];
        final previousIds = _orders.map((o) => (o['orderId'] ?? '').toString()).toSet();
        _orders = raw.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        final currentIds = _orders.map((o) => (o['orderId'] ?? '').toString()).toSet();
        _selected.removeWhere((id) => !currentIds.contains(id));
        for (final id in currentIds) {
          if (!previousIds.contains(id)) {
            _selected.add(id);
          }
        }
        if (!silent) _route = null;
        _error = null;
      } else if (!silent) {
        _orders = const [];
        _error = response.unsupported
            ? 'O ERP ainda não tem /delivery/dispatch.'
            : 'Sem conexão com o ERP (${response.error ?? 'erro'}).';
      }
    });
  }

  Future<void> _assign() async {
    if (_selected.isEmpty) {
      _snack('Selecione pelo menos um pedido.');
      return;
    }
    setState(() => _assigning = true);

    final response = await _api.assignRoute(
      courierId: _courierController.text.trim(),
      orderIds: _selected.toList(),
    );
    if (!mounted) return;

    setState(() {
      _assigning = false;
      if (response.ok && response.data?['route'] is Map) {
        _route = Map<String, dynamic>.from(response.data!['route'] as Map);
        _error = null;
      } else {
        _error = response.error ?? 'Falha ao liberar rota';
      }
    });

    if (response.ok) {
      _snack('Rota liberada com ${_selected.length} pedido(s).');
      await _load();
    } else {
      _snack(_error ?? 'Falha ao liberar rota');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Despacho'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _courierCard(),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFF92400E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Pedidos faturados (${_orders.length})', style: AppTypography.heading3),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Nenhum pedido aguardando despacho. Feche a separação e a conferência '
                  'para o pedido aparecer aqui.',
                  style: AppTypography.bodySmall,
                ),
              )
            else
              ..._orders.map(_orderTile),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _assigning || _selected.isEmpty ? null : _assign,
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: Text(
                  _assigning
                      ? 'Calculando rota...'
                      : 'Calcular e liberar rota (${_selected.length})',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_route != null) ...[
              const SizedBox(height: 20),
              _routeCard(_route!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _courierCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Icon(Icons.person_pin_circle_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _courierController,
              decoration: const InputDecoration(labelText: 'Entregador', isDense: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderTile(Map<String, dynamic> order) {
    final orderId = (order['orderId'] ?? '').toString();
    final selected = _selected.contains(orderId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() {
          if (selected) {
            _selected.remove(orderId);
          } else {
            _selected.add(orderId);
          }
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => setState(() {
                  if (selected) {
                    _selected.remove(orderId);
                  } else {
                    _selected.add(orderId);
                  }
                }),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order['code']}',
                      style: AppTypography.heading3.copyWith(fontSize: 13),
                    ),
                    Text(
                      (order['customerName'] ?? '').toString(),
                      style: AppTypography.bodySmall,
                    ),
                    Text(
                      (order['addressText'] ?? '').toString(),
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${order['itemsCount'] ?? 0} itens',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> route) {
    final stops = ((route['stops'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    final totals = route['totals'] is Map
        ? Map<String, dynamic>.from(route['totals'] as Map)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Sequência calculada', style: AppTypography.heading3),
              const Spacer(),
              Text(
                '${totals['distanceKm'] ?? 0} km',
                style: AppTypography.priceHighlight.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${totals['stops'] ?? stops.length} paradas · '
            '${totals['driveMinutes'] ?? 0} min de direção · '
            '${totals['waitMinutes'] ?? 0} min de espera',
            style: AppTypography.caption,
          ),
          const Divider(height: 20),
          ...stops.map(
            (stop) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stop['sequence']}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pedido #${stop['code']} · ${stop['customerName']}',
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _etaLabel(stop['eta']),
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _etaLabel(Object? iso) {
    final parsed = DateTime.tryParse((iso ?? '').toString());
    if (parsed == null) return '--:--';
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
