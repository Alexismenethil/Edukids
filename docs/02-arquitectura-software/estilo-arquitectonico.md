# Estilo arquitectónico

## Estilo confirmado

**Aplicación local offline organizada con Clean Architecture, más servicios de contenido en la nube y un panel web, también con Clean Architecture.**

| Pieza | Estilo | Comunicación |
| --- | --- | --- |
| Juego en la tablet | Monolito modular en el dispositivo con Clean Architecture (dominio, aplicación, adaptadores y frameworks) y base de datos embebida | Ninguna en el aula; HTTPS hacia la API solo en la Dirección |
| API de contenidos | Servicio único con Clean Architecture; catálogo de solo lectura para las tablets | REST con JSON sobre HTTPS |
| Panel docente | Aplicación web de una sola página con capas de dominio, aplicación, infraestructura e interfaz | REST con JSON sobre HTTPS y token de sesión |
| Contrato entre partes | Formato de paquete versionado (manifiesto JSON) | Archivo ZIP descargado o copiado por USB |

No se usan microservicios ni un backend de resultados: no hacen falta para el problema y aumentarían el costo de operación.

## Motivación

1. El aula no tiene conexión.
2. Las notas y el progreso deben conservarse aunque la tablet se reinicie.
3. Los contenidos nuevos, incluidos los retos de los docentes, se publican como paquetes sin actualizar el APK.
4. La aplicación debe replicarse en otras escuelas sin datos fijos.
5. Las reglas del juego y de la calificación deben poder probarse sin el motor ni la base de datos.
