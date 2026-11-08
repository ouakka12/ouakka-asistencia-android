# CORE OUAKKA Asistencia — preparación Google Play (borrador)
Fecha: 2026-11-08. Esta ficha NO autoriza publicación en producción.
Paquete: com.ouakka.core.remoteassist. APK de QA: 1.5.2 / versionCode 2070 (GitHub Release v1.5.2-rc.1).

## Modelo comercial
Descarga gratuita. Servicios de apoyo digital por persona: orientación 15 €, asistencia sencilla 29 € y ampliada 49 € desde, siempre con alcance, impuestos y precio final aceptados previamente. Revisar si la excepción de servicios en directo 1:1 permite cobro externo, según política de Google.

## Ficha propuesta en español
Nombre: CORE OUAKKA Asistencia
Descripción breve: Asistencia remota autorizada para ayudarte con gestiones digitales.
Descripción completa:
«CORE OUAKKA Asistencia permite recibir ayuda a distancia para gestiones digitales desde tu teléfono. Tú decides cuándo aceptar y detener la sesión. Puedes compartir pantalla o, de manera opcional, conceder control táctil para que una persona operadora pulse botones, escriba y se desplace por tu dispositivo durante una sesión autorizada. El contenido visible puede incluir información personal. No facilites contraseñas, PIN, Cl@ve, SMS ni certificados; detén la asistencia antes de identificarte o firmar. Los permisos se confirman personalmente desde Android y pueden rechazarse. CORE OUAKKA no es una administración pública. Servicios contratados bajo presupuesto previo.»

## Condiciones de salida
- Completar consentimiento destacado en la app y declaración AccessibilityService en Play Console. No marcar isAccessibilityTool si no se acredita su finalidad para personas con discapacidad.
- QA de botón inicial, rechazo, control durante sesión aceptada, interrupción, e instalación desde cero en dispositivo sin permisos previos.
- Documentar flujo exacto de datos: identificador remoto, IP, pantallas, chat, audio, ficheros, servidores RustDesk rendezvous/relay, transferencias internacionales, retención, acceso de operadores, derecho de borrado y soporte. No inventar «no recogemos datos» sin auditar.
- Publicar política de privacidad específica y verificable con nombre/contacto del responsable legal y URL HTTPS pública. Completar Data Safety con evidencias.
- Declarar operador en la cuenta Play antes del 1 de febrero de 2027.
- Generar AAB de release, NO APK debug de Actions; firmar con clave de subida guardada fuera de GitHub. Planificar compatibilidad con la firma existente de la APK distribuida directamente: Google Play Signing podría usar certificado distinto y requerir desinstalación al pasar de instalación directa a Play.
- Preparar capturas y vídeo demostrativo real de Accesibilidad; completar clasificación, audiencia, anuncios, políticas y pruebas antes de producción.
- Mantener licencias y código fuente correspondiente de RustDesk AGPL-3.0. La copia del motor abierto está permitida conforme a su licencia; no se puede prometer un «código imposible de copiar».
- Proteger por separado backend empresarial independiente: API de presupuestos, expedientes, cuentas, contratos, credenciales y sistemas. Aplicar autenticación, privilegios mínimos, firmas y auditoría. Ningún secreto dentro de APK/AAB o repositorio público.

## Fuentes oficiales
https://support.google.com/googleplay/android-developer/answer/10964491
https://support.google.com/googleplay/android-developer/answer/16558241
https://support.google.com/googleplay/android-developer/answer/9842756
https://support.google.com/googleplay/android-developer/answer/10281818

Estado actual: ficha de creación rellenada en PC CORE pero NO enviada, porque Google exige afirmar cumplimiento con sus políticas y todavía faltan las comprobaciones descritas. Ninguna aplicación existente ha sido modificada.
