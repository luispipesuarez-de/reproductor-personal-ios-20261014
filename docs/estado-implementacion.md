# Estado del prototipo

Código: rama `feat/reproductor-ios` del [repositorio privado](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014). Implementación inicial: `6c619ac`. Actualización de reproducción, compilación 3: `586a761`.

Incluye búsqueda por texto, resultados seleccionables, vista de video, pausa/reanudación, manejo de respuestas tardías y errores, y configuración de audio en segundo plano. La extracción consulta YouTube desde el dispositivo. No requiere pegar enlaces.

El hito físico inicial de la compilación 3 está confirmado por el usuario: reproducción, audio al salir y bloquear, sin anuncios observados en esa prueba. Continúa el plan con cola, controles y biblioteca; la cuenta de YouTube pertenece a una etapa posterior. La primera etapa completa todavía no está validada.

## Evidencias

| Comprobación | Evidencia | Estado |
| --- | --- | --- |
| Configuración, mapeo y primer IPA | [38630421307](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38630421307) | 6/6 tests y paquete comprobados |
| Búsqueda y reproductor nativo | [38635023595](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38635023595) | 19 casos pasaron; los 3 de cliente fallaron por IDs de fixture inválidos |
| RED válido del adaptador y regresiones | [38637144094](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38637144094) | Fallos reproducidos con IDs válidos; pruebas corregidas |
| Suite completa y IPA del prototipo | [38638945973](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38638945973) | 25/25 tests, Release e IPA correctos |
| Instalación y búsqueda | iPhone 13, iOS 26.2, compilación 2 | Instalación confirmada y resultado seleccionado en la captura del usuario |
| Primera reproducción real | «Frankie Ruíz - Tú Con Él (Visualizer)» y otro resultado | Fallan con contenido no disponible en la compilación 2 |
| Regresión del fallo SABR | [38675597787](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38675597787) | 28 tests: los 2 caminos positivos nuevos fallan con `unavailable`; los 26 restantes pasan |
| Ruta HLS alternativa, suite y compilación 3 | [38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279) | 28/28 tests, Release e IPA correctos |
| Reproducción real con la actualización, anuncios y bloqueo | iPhone 13, iOS 26.2, compilación 3 | Usuario confirma reproducción, continuidad en Inicio y bloqueo; sin anuncios observados en la muestra |

La revisión independiente del código encontró el bloqueo de flujos directos por otros cifrados y las preparaciones duplicadas. Ambas correcciones tienen pruebas de regresión RED→GREEN y la suite completa pasó. No quedan sugerencias menores diferidas después de reclasificar la preparación duplicada como un problema de comportamiento.

El IPA local está en `build/ReproductorPersonal.ipa`. Se comprobaron CRC del ZIP, ejecutable Mach-O arm64, identificador `personal.reproductor.ios`, versión 0.1.0/3, iOS mínimo 16.0 y `UIBackgroundModes: [audio]`. Tamaño: 1.579.073 bytes. SHA-256: `15951c7f3b1995244e7bd6afe63391816870e0b274475d3cb26a5c8f44c89a64`. La compilación 2 se conserva en `build/anteriores/`. La captura del simulador no sustituye pruebas de video real, modo oscuro o accesibilidad en el dispositivo.

El diagnóstico de red en Windows confirmó SABR sin HLS ni MP4 combinado en la petición IOS para dos videos públicos. El perfil VISIONOS 1.02 con visitante anónimo, documentado en [yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/yt_dlp/extractor/youtube/_base.py), devolvió HLS y fragmentos de video H.264 y audio HTTP 200. Se comprobó también reutilizar el visitante de búsqueda y leer los fragmentos sin cabeceras especiales. Esta evidencia no confirma por sí sola reproducción en el teléfono. La revisión independiente `d12c330..586a761` no encontró defectos que requieran cambios; mantuvo expresamente pendientes la reproducción física, el segundo plano y anuncios. La compatibilidad con otros contenidos requiere pruebas; cola y biblioteca conservan su hito previo.

El log de Xcode incluye advertencias de metadatos AppIntents sin esa dependencia, de orientaciones para iPad y de destinos equivalentes del simulador. No hubo errores de compilación ni fallos de tests. La entrega es un IPA sin firmar para firma personal con AltServer.

## Decisiones registradas

- Código en la carpeta aprobada, sobre una rama de desarrollo. Si hubiera que aislarlo físicamente, se trasladaría el checkout antes de continuar.
- Registro y extracción de tareas con PowerShell en Windows: el auxiliar Bash fallaba con las rutas del entorno. Si fuese necesario, los briefs y el registro se regenerarían desde el plan y Git.
- Interfaces vacías para permitir fallos de XCTest en afirmaciones, antes de implementar comportamiento. Son reemplazadas por el código comprobado.
- Petición de reproducción iOS del paquete y fallback HLS nativo al detectar SABR. Se conserva el visitante anónimo de la búsqueda; si falta, se lee del HTML sin ejecutar el reproductor web. HTML/JavaScript del paquete solo se usa para descifrar los formatos que lo necesitan. Una incompatibilidad real exige repetir la prueba del teléfono.
- IDs sintéticos del plan en los proveedores de prueba; IDs válidos en las pruebas del adaptador. Se corrigieron las fixtures en lugar de relajar el validador real.
- Funciones posteriores pendientes del hito físico, conforme a la especificación. El prototipo carece todavía de ellas.
- Firma, instalación y reproducción de la compilación 3 están confirmadas por el usuario. La muestra probada continúa al salir y bloquear y no presentó anuncios. La escucha prolongada y el resto del catálogo siguen sin validar.
- El resultado de CI se registra después de leer la salida; una ejecución iniciada o un código revisado no equivalen a una compilación verificada.

Para instalar, sigue [instalacion-iphone.md](instalacion-iphone.md) y registra las observaciones en [verificacion-iphone.md](verificacion-iphone.md).
