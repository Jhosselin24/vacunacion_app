import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'vacunacion_service.dart';

class ConnectivityService {
  final _connectivity      = Connectivity();
  final _vacunacionService = VacunacionService();

  StreamSubscription? _subscription;
  bool _estaConectado = true;

  bool get estaConectado => _estaConectado;

  // ── Inicializar listener ───────────────────────────────────
  void inicializar({
    void Function(bool conectado)? onCambio,
    void Function(int sincronizados)? onSincronizado,
  }) {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final conectado = results.any((r) => r != ConnectivityResult.none);
        final cambio    = conectado != _estaConectado;
        _estaConectado  = conectado;

        if (cambio) {
          onCambio?.call(conectado);

          if (conectado && _vacunacionService.pendientesOffline > 0) {
            final count = await _vacunacionService.sincronizarOffline();
            if (count > 0) onSincronizado?.call(count);
          }
        }
      },
    );
  }

  // ── Verificar conexión actual ──────────────────────────────
  Future<bool> verificarConexion() async {
    final results  = await _connectivity.checkConnectivity();
    _estaConectado = results.any((r) => r != ConnectivityResult.none);
    return _estaConectado;
  }

  // ── Sincronizar manualmente ────────────────────────────────
  Future<int> sincronizarManual() async {
    final conectado = await verificarConexion();
    if (!conectado) return 0;
    return _vacunacionService.sincronizarOffline();
  }

  // ── Limpiar ────────────────────────────────────────────────
  void dispose() {
    _subscription?.cancel();
  }
}