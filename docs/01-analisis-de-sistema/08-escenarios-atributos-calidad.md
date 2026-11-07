# 08. Escenarios de calidad y criterios de aceptación

## Criterios de aceptación

Formato: Dado, Cuando y Entonces, para convertirlos directamente en pruebas. CA-01 a CA-10 vienen de la v2.0 (ajustados al juego) y CA-11 a CA-20 son nuevos.

| Código | Escenario |
| --- | --- |
| CA-01 | Dado un módulo instalado, cuando la tablet está en modo avión, entonces el estudiante ve la explicación, abre las fichas, juega los niveles y rinde el desafío final. |
| CA-02 | Dada una descarga interrumpida, cuando vuelve la conexión en la Dirección, entonces la descarga continúa y el paquete se instala solo si está completo. |
| CA-03 | Dado un paquete alterado, cuando la aplicación verifica su SHA-256, entonces rechaza la instalación e informa el error. |
| CA-04 | Dado un estudiante en pleno desafío final, cuando la tablet se apaga, entonces al volver recupera todas sus respuestas confirmadas. |
| CA-05 | Dado un desafío final terminado, cuando el docente abre el reporte, entonces ve la calificación, el porcentaje, el número de intento y la fecha. |
| CA-06 | Dado un PIN incorrecto, cuando un estudiante o el docente intenta ingresar, entonces el acceso se rechaza; tras cinco intentos fallidos, el perfil se bloquea por un tiempo. |
| CA-07 | Dado un módulo no habilitado, cuando el estudiante entra al mapa, entonces lo ve con candado y no puede abrirlo. |
| CA-08 | Dada una tablet con poco espacio, cuando el docente intenta descargar un paquete, entonces la aplicación informa cuánto espacio falta. |
| CA-09 | Dada una instalación nueva, cuando el docente configura otra institución, entonces no aparece ningún dato de la institución piloto. |
| CA-10 | Dada la tablet de referencia, cuando se recorren las pantallas principales, entonces no hay desbordes y los menús cargan en 2 s o menos. |
| CA-11 | Dado un nivel de persecución, cuando el estudiante acierta, entonces el avatar avanza; cuando falla, Atoq se acerca según RN-13. |
| CA-12 | Dado un estudiante con una vida y el medidor de peligro en 1, cuando falla, entonces Atoq lo alcanza y aparece game over con el botón Reintentar. |
| CA-13 | Dado un nivel terminado con 95 % de aciertos válidos y sin vidas perdidas, entonces se otorgan 3 estrellas. |
| CA-14 | Dado un desafío final con 72 % de aciertos y la escala por defecto, entonces la calificación es A. |
| CA-15 | Dado un desafío final en curso, cuando el estudiante falla una pregunta, entonces no pierde vidas ni sale del desafío. |
| CA-16 | Dado un reto publicado con el código K7M3QX, cuando una tablet configurada con ese código consulta el catálogo, entonces el reto aparece; con otro código, no aparece. |
| CA-17 | Dado un paquete que contiene un archivo de código o una ruta fuera del paquete, cuando se intenta instalar, entonces la instalación se rechaza. |
| CA-18 | Dada una unidad de lectura, cuando el estudiante está en cualquiera de sus preguntas, entonces puede volver al texto. |
| CA-19 | Dada la tablet de referencia, cuando se juega un nivel regular, entonces carga en 3 s o menos, se mantiene en 30 fps o más y usa 400 MB de memoria o menos. |
| CA-20 | Dado el código del juego, cuando corre la verificación de dependencias en CI, entonces no hay referencias a Godot, a archivos, a la red ni a la infraestructura dentro de `domain/` y `application/`. |

## Escenarios de atributos de calidad

| Atributo | Estímulo y contexto | Respuesta esperada | Medida |
| --- | --- | --- | --- |
| Disponibilidad offline | Tablet en modo avión durante la clase | Explicación, fichas, niveles, desafíos y reportes funcionan | Recorrido completo sin red |
| Persistencia | Apagado inesperado durante un desafío final | Se recuperan las respuestas confirmadas | Ninguna respuesta confirmada perdida |
| Rendimiento | El estudiante juega un nivel con animaciones | La animación es fluida y responde al toque | 30 fps o más; reacción en menos de 100 ms |
| Seguridad | Alguien ingresa PIN incorrectos seguidos | Acceso denegado y bloqueo temporal | Ningún acceso no autorizado |
| Integridad | Un paquete fue modificado o contiene código | Instalación rechazada | SHA-256 y validación de contenido |
| Portabilidad | Se instala el APK en otra escuela | Configuración independiente | Ningún dato fijo de la escuela piloto |
| Modificabilidad | Se cambia SQLite por otro almacenamiento | Solo cambia el adaptador de infraestructura | Dominio y casos de uso sin cambios |
| Testabilidad | Se corre la suite de pruebas en CI | Pruebas de dominio y casos de uso sin interfaz gráfica | Cobertura de 80 % o más |
