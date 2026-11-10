import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/mobile/pages/home_page.dart';
import 'package:flutter_hbb/mobile/widgets/ouakka_diagnostics_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';

/// CORE OUAKKA · Asistencia — flujo de UN SOLO BOTÓN.
///
/// «RECIBIR AYUDA» encadena todo lo que Android permite hacer desde la app:
///   1. Consentimiento claro en nuestra pantalla.
///   2. Permiso de notificaciones (ventana de Android dentro de la app).
///   3. Compartir pantalla (ventana de Android «Empezar ahora», dentro de la app).
///   4. Opcional: control remoto, con el cliente presente.
///      Android puede exigir entrar en «Aplicaciones descargadas» para activar
///      manualmente el servicio. La app ofrece una guía clara, no elude Ajustes.
/// Ningún permiso se concede sin que la persona lo pulse. No se ocultan avisos.
const String kOuakkaActionAccessibility = 'ouakka.accessibility.details';
const _teal = Color(0xFF176B73);
const _navy = Color(0xFF163C46);
const _red = Color(0xFFAA2632);

class OuakkaAssistanceGuide extends StatefulWidget {
  const OuakkaAssistanceGuide({Key? key, required this.model})
      : super(key: key);

  final ServerModel model;

  @override
  State<OuakkaAssistanceGuide> createState() => _OuakkaAssistanceGuideState();
}

class _OuakkaAssistanceGuideState extends State<OuakkaAssistanceGuide> {
  bool _busy = false;
  String? _progress;
  bool _askedControl = false;
  bool _askedBattery = false;

  ServerModel get m => widget.model;

  @override
  void initState() {
    super.initState();
    if (ouakkaClientSimpleMode) {
      // Sin contraseña: el cliente solo pulsa «Aceptar» cuando el operador entra.
      Future.microtask(() => m.setApproveMode('click'));
    }
  }

  Future<bool> _waitFor(bool Function() cond, Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (cond()) return true;
      await Future.delayed(const Duration(milliseconds: 400));
    }
    return cond();
  }

  Future<bool?> _ask({
    required String title,
    required String text,
    required String yes,
    String no = 'Ahora no',
    IconData icon = Icons.support_agent,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(icon, color: _teal, size: 40),
        title: Text(title, textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
                child: Text(yes,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(no, style: const TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// El botón único.
  Future<void> _recibirAyuda() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!m.isStart) {
        final ok = await _ask(
          title: '¿Quieres recibir ayuda ahora?',
          text:
              'El operador de OUAKKA podrá VER tu pantalla mientras dure la ayuda.\n\n'
              'Android te mostrará un aviso: pulsa «Empezar ahora».\n'
              'Puedes pararlo cuando quieras con el botón rojo.',
          yes: 'SÍ, QUIERO AYUDA',
          no: 'Cancelar',
        );
        if (ok != true) return;

        setState(() => _progress = 'Preparando…');
        await m.checkRequestNotificationPermission();

        setState(
            () => _progress = 'Pulsa «Empezar ahora» en el aviso de Android');
        await m.startService();
        final shared =
            await _waitFor(() => m.mediaOk, const Duration(seconds: 60));
        if (!shared) {
          setState(() => _progress =
              'No se activó compartir pantalla. Vuelve a pulsar «Recibir ayuda».');
          return;
        }
      }

      // Batería: un solo toque en el aviso de Android (sustituye ir a Ajustes > Batería).
      if (!_askedBattery &&
          androidVersion >= 23 &&
          !await AndroidPermissionManager.check(
              kRequestIgnoreBatteryOptimizations)) {
        _askedBattery = true;
        final ok = await _ask(
          icon: Icons.battery_charging_full,
          title: 'Que la ayuda no se corte',
          text:
              'Android te va a preguntar si esta app puede seguir funcionando '
              'en segundo plano.\n\nPulsa «Permitir». Solo se pide una vez.',
          yes: 'VALE',
          no: 'Ahora no',
        );
        if (ok == true) {
          await AndroidPermissionManager.request(
              kRequestIgnoreBatteryOptimizations);
        }
      }

      if (!m.inputOk && !_askedControl) {
        _askedControl = true;
        await _pedirControl();
      }
      setState(() => _progress = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pedirControl() async {
    // Google Play: divulgación destacada antes de abrir Accesibilidad.
    // El usuario acepta de forma afirmativa o continúa sin control táctil.
    const disclosure = 'USO DEL SERVICIO DE ACCESIBILIDAD (OPCIONAL)\n\n'
        'CORE OUAKKA Asistencia utiliza el servicio de Accesibilidad '
        'para que un operador humano, durante una sesión de ayuda aceptada '
        'por ti, pueda tocar botones, escribir y desplazarse en tu móvil. '
        'Android permite que este servicio consulte el contenido de las '
        'ventanas en pantalla, que puede incluir datos personales y textos '
        'que estés viendo.\n\n'
        'La información visible y las acciones de control pueden '
        'transmitirse al dispositivo del operador a través de la conexión '
        'remota y de los servidores de conexión configurados, que pueden '
        'incluir infraestructura de terceros.\n\n'
        'El control táctil es opcional y requiere tu autorización expresa '
        'en esta pantalla y en los ajustes de Android. Puedes rechazarlo '
        'y pedir ayuda solo mediante visualización. Tú aceptas o rechazas '
        'las sesiones entrantes y puedes detener la asistencia cuando quieras. '
        'También puedes revocar el servicio en Ajustes > Accesibilidad.\n\n'
        'Nunca muestres ni entregues contraseñas, PIN, Cl@ve, códigos '
        'SMS o certificados. Detén la sesión antes de identificarte o firmar.';

    final ok = await _ask(
      icon: Icons.touch_app_outlined,
      title: '¿Autorizas el control remoto?',
      text: '$disclosure\n\n'
          'Si aceptas, se abrirán los ajustes de Accesibilidad de Android. '
          'Busca «CORE OUAKKA: control autorizado» y confirma el permiso '
          'personalmente. No cambies otras protecciones de seguridad del móvil.',
      yes: 'SÍ, ACEPTO · ABRIR AJUSTES',
      no: 'NO · SOLO VER PANTALLA',
    );
    if (ok == true) _abrirAccesibilidad();
  }

  void _abrirAccesibilidad() {
    AndroidPermissionManager.startAction(kOuakkaActionAccessibility);
  }

  @override
  Widget build(BuildContext context) {
    final active =
        m.clients.any((client) => client.authorized && !client.disconnected);
    final started = m.isStart && m.mediaOk;
    final online = m.connectStatus > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Card(
        elevation: 0,
        color: const Color(0xFFF3F8FA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFC5DBE3)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.support_agent, color: _teal, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text('CORE OUAKKA · Asistencia',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _navy)),
                ),
              ]),
              const SizedBox(height: 16),

              // ---------- CONTROL AUTORIZADO, VISIBLE DESDE EL PRINCIPIO ----------
              if (!m.inputOk) ...[
                SizedBox(
                  height: 86,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _pedirControl,
                    icon: const Icon(Icons.touch_app_outlined, size: 32),
                    label: const Text(
                      'ACTIVAR CONTROL AUTORIZADO',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Pulsa aquí: te guiamos por los permisos de Android. '
                    'En Xiaomi tendrás que confirmar el control tú mismo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.3, color: _navy),
                  ),
                ),
              ],

              // ---------- RECIBIR AYUDA Y COMPARTIR PANTALLA ----------
              if (!started)
                SizedBox(
                  height: 96,
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _recibirAyuda,
                    icon: _busy
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3))
                        : const Icon(Icons.volunteer_activism, size: 36),
                    label: const Text('RECIBIR AYUDA',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _teal.withOpacity(0.6),
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),

              // Diagnóstico guiado: debajo de «Recibir ayuda», sin permisos nuevos.
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OuakkaDiagnosticsPage(
                              onRequestAssistance: () {
                                Navigator.of(context).pop();
                                if (mounted) _recibirAyuda();
                              },
                            ),
                          ),
                        ),
                icon: const Icon(Icons.handyman_outlined, size: 25),
                label: const Text(
                  'DIAGNÓSTICO Y REPARACIÓN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(68),
                  foregroundColor: _teal,
                  side: const BorderSide(color: _teal, width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),

              if (_progress != null) ...[
                const SizedBox(height: 12),
                Text(_progress!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _navy)),
              ],

              // ---------- ESTADO DESPUÉS DE PULSAR ----------
              if (started) ...[
                _status(
                  active
                      ? 'ASISTENCIA EN CURSO'
                      : online
                          ? 'LISTO: dile tu ID al operador'
                          : 'Conectando a Internet…',
                  active
                      ? 'El operador está conectado. Puedes pararlo cuando quieras.'
                      : online
                          ? 'Tu ID aparece abajo. Acepta solo si reconoces al operador.'
                          : 'Mantén la app abierta. Sirven Wi-Fi o datos móviles.',
                  active
                      ? Icons.shield_outlined
                      : online
                          ? Icons.check_circle_outline
                          : Icons.sync,
                  active || online
                      ? Colors.green.shade800
                      : Colors.orange.shade900,
                ),
                const SizedBox(height: 10),
                _permRow('Ver pantalla', true),
                _permRow('Tocar pantalla', m.inputOk),
                if (!m.inputOk) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Si todavía no autorizaste el control, usa el botón '
                    '«ACTIVAR CONTROL AUTORIZADO» que aparece arriba.',
                    style: TextStyle(fontSize: 15, height: 1.25),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _pedirControl,
                    child: const Text(
                        '¿No funciona el control? Revisar permisos',
                        style: TextStyle(fontSize: 15)),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Corta la conexión y deja de compartir pantalla.
                      // El permiso de tocar se QUEDA GUARDADO para la próxima vez
                      // (sin conexión activa nadie puede usarlo).
                      await m.stopService();
                      _askedControl = false;
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 30),
                    label: const Text('DETENER ASISTENCIA',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],

              if (started && m.inputOk)
                TextButton(
                  onPressed: () async {
                    await gFFI.invokeMethod('stop_input');
                    bind.mainSetOption(key: kOptionEnableKeyboard, value: 'N');
                  },
                  child: const Text('Quitar el permiso de tocar mi pantalla',
                      style: TextStyle(fontSize: 14)),
                ),
              const SizedBox(height: 14),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: _teal, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nunca compartas tu Cl@ve, PIN, códigos ni contraseñas. '
                      'Para la ayuda antes de identificarte o firmar.',
                      style:
                          TextStyle(fontSize: 14, height: 1.35, color: _navy),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(String title, String text, IconData icon, Color color) {
    return Semantics(
      liveRegion: true,
      label: '$title. $text',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 15, height: 1.3)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _permRow(String label, bool on) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
            color: on ? Colors.green.shade700 : Colors.grey, size: 22),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 15)),
        const Spacer(),
        Text(on ? 'Activado' : 'No',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: on ? Colors.green.shade700 : Colors.grey)),
      ]),
    );
  }
}
