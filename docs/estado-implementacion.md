# Estado del prototipo

Código: rama `feat/reproductor-ios` del [repositorio privado](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014). Implementación del prototipo: `6c619ac`.

Incluye búsqueda por texto, resultados seleccionables, vista de video, pausa/reanudación, manejo de respuestas tardías y errores, y configuración de audio en segundo plano. La extracción consulta YouTube desde el dispositivo. No requiere pegar enlaces.

La cola, los controles explícitos del sistema, la biblioteca y la cuenta de YouTube quedan pendientes del hito físico aprobado. La primera etapa completa todavía no está validada.

## Evidencias

| Comprobación | Evidencia | Estado |
| --- | --- | --- |
| Configuración, mapeo y primer IPA | [38630421307](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38630421307) | 6/6 tests y paquete comprobados |
| Búsqueda y reproductor nativo | [38635023595](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38635023595) | 19 casos pasaron; los 3 de cliente fallaron por IDs de fixture inválidos |
| RED válido del adaptador y regresiones | [38637144094](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38637144094) | Fallos reproducidos con IDs válidos; pruebas corregidas |
| Suite completa y IPA del prototipo | [38638945973](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38638945973) | 25/25 tests, Release e IPA correctos |
| Reproducción real, anuncios y bloqueo | iPhone 13, iOS 26.2 | No probado |

La revisión independiente del código encontró el bloqueo de flujos directos por otros cifrados y las preparaciones duplicadas. Ambas correcciones tienen pruebas de regresión RED→GREEN y la suite completa pasó. No quedan sugerencias menores diferidas después de reclasificar la preparación duplicada como un problema de comportamiento.

El IPA local está en `build/ReproductorPersonal.ipa`. Se comprobó su ejecutable Mach-O, identificador `personal.reproductor.ios`, versión 0.1.0/2, iOS mínimo 16.0 y `UIBackgroundModes: [audio]`. SHA-256: `132c94acce91fd190c45ba8d3830ea92105419de6ccda3e7c078b3144a3cfc50`. La captura del simulador muestra la búsqueda visible al abrir, sin solapamientos en esa pantalla; no sustituye pruebas de video real, modo oscuro o accesibilidad en el dispositivo.

## Decisiones registradas

- Código en la carpeta aprobada, sobre una rama de desarrollo. Si hubiera que aislarlo físicamente, se trasladaría el checkout antes de continuar.
- Registro y extracción de tareas con PowerShell en Windows: el auxiliar Bash fallaba con las rutas del entorno. Si fuese necesario, los briefs y el registro se regenerarían desde el plan y Git.
- Interfaces vacías para permitir fallos de XCTest en afirmaciones, antes de implementar comportamiento. Son reemplazadas por el código comprobado.
- Petición de reproducción iOS del paquete; HTML/JavaScript únicamente cuando se necesita descifrado. Una incompatibilidad real exige revisar esa ruta y repetir la prueba del teléfono.
- IDs sintéticos del plan en los proveedores de prueba; IDs válidos en las pruebas del adaptador. Se corrigieron las fixtures en lugar de relajar el validador real.
- Funciones posteriores pendientes del hito físico, conforme a la especificación. El prototipo carece todavía de ellas.
- Compatibilidad con YouTube, anuncios, audio bloqueado y firma pendientes de observación física. Si fallan, hace falta el resultado del teléfono para corregir el resolver local.
- El resultado de CI se registra después de leer la salida; una ejecución iniciada o un código revisado no equivalen a una compilación verificada.

Para instalar, sigue [instalacion-iphone.md](instalacion-iphone.md) y registra las observaciones en [verificacion-iphone.md](verificacion-iphone.md).
