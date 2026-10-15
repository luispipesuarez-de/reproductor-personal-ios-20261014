# Comprobación en el iPhone

Estado: instalado y abierto en el iPhone el 14 de octubre de 2026, según confirmación del usuario. La búsqueda permite seleccionar resultados, pero la reproducción falla. No se ha demostrado aún ausencia de anuncios ni audio con pantalla bloqueada.

Dispositivo: iPhone 13. iOS: 26.2 (información del usuario).

Prototipo instalado en la primera prueba: versión 0.1.0, compilación 2, commit `6c619ac`. Actualización disponible: versión 0.1.0, compilación 3, commit `586a761`. [CI 38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279): 28/28 tests correctos y Release/IPA comprobados. Los tests proceden de fixtures y un WAV local; no demuestran reproducción real de YouTube en el iPhone.

## Hito 1 — antes de ampliar la biblioteca

| Prueba | Contenido / duración | Resultado observado |
| --- | --- | --- |
| Buscar por texto sin pegar enlace | Resultado «Frankie Ruíz - Tú Con Él (Visualizer)» | Resultado seleccionado y vista de reproducción abierta en la captura del usuario |
| Video público: imagen y sonido | Pendiente | No probado |
| Canción pública, compilación 2 | «Frankie Ruíz - Tú Con Él (Visualizer)» y otro resultado de una búsqueda distinta | Fallan: «No se pudo reproducir» / «Este contenido no está disponible en esta versión» |
| Repetir con la compilación 3 | La misma canción | Pendiente de instalar y probar |
| Audio al bloquear la pantalla | Pendiente | No probado |
| Audio al cambiar de aplicación | Pendiente | No probado |
| Anuncios insertados durante estas pruebas | Pendiente | No probado |

Indicar también la ejecución de GitHub y versión del IPA instalado. Si la reproducción falla, registrar el mensaje exacto y la búsqueda usada; no incluir credenciales ni URLs temporales.

La instalación de esta compilación se completó mediante AltServer → Shift + clic en su icono → Sideload .ipa, con el iPhone conectado por USB. La copia del IPA en iCloud Drive de Windows no aparecía en el teléfono; no se confirmó la causa de esa sincronización.

Diagnóstico del 14 de octubre: al repetir en Windows la petición IOS de la dependencia, el video público `QEYGxzEGwaM` (coincidencia de título de la captura) y `aqz-KE-bpKQ` responden `playabilityStatus: OK`, con SABR y sin HLS ni formatos combinados. El prototipo rechaza ese formato. Una petición VISIONOS con identificador anónimo de visitante devuelve HLS: se comprobaron HTTP 200 en el manifiesto, una variante H.264 y fragmentos de audio y video de ambos contenidos. No se usaron credenciales ni cookies de cuenta. Esta prueba de red en Windows no demuestra todavía reproducción en el iPhone.

Hitos 2 y 3 (cola, controles del sistema y biblioteca): todavía no iniciados. El diseño aprobado exige validar este hito técnico antes de ampliarlos.
