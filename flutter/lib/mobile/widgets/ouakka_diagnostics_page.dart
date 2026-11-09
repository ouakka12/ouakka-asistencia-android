import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diagnóstico guiado: no ejecuta comandos, instala software ni concede acceso.
/// La asistencia remota utiliza el consentimiento de «Recibir ayuda».
class OuakkaDiagnosticsPage extends StatefulWidget {
  const OuakkaDiagnosticsPage({
    Key? key,
    required this.onRequestAssistance,
  }) : super(key: key);

  final VoidCallback onRequestAssistance;

  @override
  State<OuakkaDiagnosticsPage> createState() => _OuakkaDiagnosticsPageState();
}

class _OuakkaDiagnosticsPageState extends State<OuakkaDiagnosticsPage> {
  static const _teal = Color(0xFF176B73);
  static const _navy = Color(0xFF163C46);
  int _area = 0;
  String _issue = 'Lentitud o bloqueos';

  static const _issues = [
    'Lentitud o bloqueos',
    'Sin Internet o Wi-Fi',
    'Errores de Windows',
    'Actualizaciones fallidas',
    'Pantalla o arranque',
    'Problemas en Android',
    'Reinstalar sistema',
    'Otro problema',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Diagnóstico y reparación')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _notice(Icons.shield_outlined, 'Soporte técnico con permiso',
                  'Consulta pruebas y soluciones. La app no ejecuta comandos '
                  'en otros equipos ni accede a tus archivos. El técnico '
                  'solo interviene tras una autorización independiente.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _issue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: '¿Qué problema quieres solucionar?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build_circle_outlined),
                ),
                items: _issues
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _issue = v);
                },
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _choice('Windows / CMD', 0, Icons.desktop_windows_outlined),
                _choice('Android', 1, Icons.smartphone_outlined),
                _choice('Instalar sistema', 2, Icons.install_desktop_outlined),
              ]),
              const SizedBox(height: 14),
              if (_area == 0) _windows(),
              if (_area == 1) _android(),
              if (_area == 2) _installation(),
              const Divider(height: 28),
              OutlinedButton.icon(
                onPressed: _copyTicket,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('COPIAR SOLICITUD PARA EL TÉCNICO'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: widget.onRequestAssistance,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('SOLICITAR ASISTENCIA REMOTA'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _teal, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Empresas: diagnóstico, presupuesto previo y autorización '
                'de intervención. Si el equipo deja de arrancar o pierde '
                'la conexión, puede necesitar asistencia presencial.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _navy, height: 1.35),
              ),
            ],
          ),
        ),
      );

  Widget _choice(String label, int value, IconData icon) => ChoiceChip(
        avatar: Icon(icon, size: 18, color: _navy),
        label: Text(label),
        selected: _area == value,
        onSelected: (_) => setState(() => _area = value),
      );

  Widget _notice(IconData icon, String title, String message) => Card(
        color: const Color(0xFFEAF5F7),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: _teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _navy, fontSize: 16)),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(color: _navy, height: 1.4)),
              ]),
            ),
          ]),
        ),
      );

  Widget _heading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, height: 1.4)),
        ]),
      );

  Widget _command(String title, String description, String command,
      {bool repairs = false, bool requiresAdmin = false}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(description, style: const TextStyle(fontSize: 14)),
            if (requiresAdmin)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text('CMD como administrador',
                    style: TextStyle(color: Color(0xFF9C5500), fontSize: 13)),
              ),
            const SizedBox(height: 8),
            SelectableText(command, style: const TextStyle(
                fontFamily: 'monospace', fontSize: 13)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copyCommand(command, repairs: repairs),
                icon: const Icon(Icons.copy, size: 18),
                label: Text(repairs ? 'REVISAR Y COPIAR' : 'COPIAR CMD'),
              ),
            ),
          ]),
        ),
      );

  Widget _windows() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Diagnóstico Windows',
              'Ejecuta CMD en el propio PC o con acceso remoto autorizado. '
              'Empieza por pruebas sin cambios.'),
          _command('Sistema y versión', 'Identifica Windows y hardware.',
              'systeminfo'),
          _command('Red e IP', 'Revisa red y DNS. La salida puede contener '
              'datos privados.', 'ipconfig /all'),
          _command('Integridad de Windows',
              'Comprueba archivos protegidos sin repararlos.',
              'sfc /verifyonly', requiresAdmin: true),
          _command('Estado de componentes',
              'Detecta problemas sin modificar la imagen.',
              'DISM /Online /Cleanup-Image /ScanHealth',
              requiresAdmin: true),
          _command('Comprobar disco', 'Sin opciones /f ni /r.',
              'chkdsk C:'),
          const SizedBox(height: 8),
          _heading('Reparación con autorización',
              'Haz copia de seguridad primero. Estos comandos sí pueden '
              'modificar archivos y requieren consentimiento del titular.'),
          _command('Reparar componentes',
              'Puede obtener componentes desde Windows Update.',
              'DISM /Online /Cleanup-Image /RestoreHealth',
              repairs: true, requiresAdmin: true),
          _command('Reparar archivos de Windows',
              'Reemplaza archivos protegidos dañados.',
              'sfc /scannow', repairs: true, requiresAdmin: true),
        ],
      );

  Widget _android() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Diagnóstico Android',
              'Comprueba primero Ajustes > Batería, Almacenamiento, '
              'Wi-Fi y Actualización del sistema.'),
          _notice(Icons.phonelink_setup_outlined, 'ADB opcional',
              'Requiere el teléfono conectado a un PC y depuración USB '
              'autorizada. No se ejecuta desde esta app.'),
          const SizedBox(height: 8),
          _command('Detectar móvil autorizado', 'Conexión USB al PC.',
              'adb devices -l'),
          _command('Versión Android', 'Consulta la versión del sistema.',
              'adb shell getprop ro.build.version.release'),
          _command('Batería', 'Muestra estado y mediciones disponibles.',
              'adb shell dumpsys battery'),
          _command('Almacenamiento', 'Consulta espacio sin borrar datos.',
              'adb shell df -h /data'),
          _notice(Icons.warning_amber_outlined, 'Sin cambios automáticos',
              'Nunca formatear, rootear, desbloquear o instalar ROM '
              'sin procedimiento específico y autorización verificable.'),
        ],
      );

  Widget _installation() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _heading('Instalación y recuperación de sistemas',
              'Proceso guiado. No se garantiza instalar un sistema '
              'enteramente a distancia.'),
          _notice(Icons.backup_outlined, '1. Proteger datos',
              'Verificar copia de seguridad, licencia y clave BitLocker. '
              'Acordar qué se conserva y qué se puede borrar.'),
          _notice(Icons.fact_check_outlined, '2. Reparar antes de reinstalar',
              'Si Windows inicia, valorar la reinstalación con Windows '
              'Update conservando datos y aplicaciones cuando sea compatible.'),
          _notice(Icons.usb_outlined, '3. Instalación con USB/ISO',
              'Un reinicio puede cortar el control remoto. Una instalación '
              'limpia puede borrar archivos y requerir un técnico local.'),
          OutlinedButton.icon(
            onPressed: () => _copyCommand(
                'https://www.microsoft.com/es-es/software-download/windows11'),
            icon: const Icon(Icons.copy),
            label: const Text('COPIAR ENLACE OFICIAL DE WINDOWS 11'),
          ),
          const SizedBox(height: 8),
          _notice(Icons.android_outlined, 'Reinstalación Android',
              'Usar herramientas oficiales del fabricante, confirmar '
              'compatibilidad, copia de seguridad y autorización.'),
        ],
      );

  Future<void> _copyTicket() async {
    const areas = ['Windows / CMD', 'Android', 'Instalación del sistema'];
    final body = <String>[
      'CORE OUAKKA - Solicitud de soporte',
      'Sistema: ' + areas[_area],
      'Incidencia: ' + _issue,
      'Diagnóstico y presupuesto previo.',
      'Sesión remota únicamente con permiso del cliente.',
      'No adjuntar contraseñas ni datos sensibles.',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: body));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Solicitud copiada para enviar al técnico.')));
    }
  }

  Future<void> _copyCommand(String command, {bool repairs = false}) async {
    if (repairs) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar reparación'),
          content: const Text(
              'Este comando puede modificar Windows. Requiere '
              'copia de seguridad, permiso del propietario y, a menudo, '
              'administrador o reinicio. ¿Deseas copiarlo para una '
              'intervención supervisada?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('COPIAR')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await Clipboard.setData(ClipboardData(text: command));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copiado. No se ejecutó nada.')));
    }
  }
}
