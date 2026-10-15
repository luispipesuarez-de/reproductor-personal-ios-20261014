# Comprobación en el iPhone

Estado: compilación 3 instalada y probada en el iPhone el 14 de octubre de 2026. El usuario confirmó reproducción, continuidad al salir de la app y con pantalla bloqueada. No observó anuncios en esta prueba. El hito técnico inicial queda superado; las pruebas extensas del uso cotidiano siguen pendientes.

Dispositivo: iPhone 13. iOS: 26.2 (información del usuario).

Prototipo instalado en la primera prueba: versión 0.1.0, compilación 2, commit `6c619ac`. Actualización disponible: versión 0.1.0, compilación 3, commit `586a761`. [CI 38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279): 28/28 tests correctos y Release/IPA comprobados. Los tests proceden de fixtures y un WAV local; no demuestran reproducción real de YouTube en el iPhone.

## Hito 1 — antes de ampliar la biblioteca

| Prueba | Contenido / duración | Resultado observado |
| --- | --- | --- |
| Buscar por texto sin pegar enlace | Resultado «Frankie Ruíz - Tú Con Él (Visualizer)» | Resultado seleccionado y vista de reproducción abierta en la captura del usuario |
| Video público: imagen y sonido, compilación 3 | Misma canción solicitada después de la actualización | Usuario confirmó que ahora reproduce, tras pedirle comprobar imagen y sonido |
| Canción pública, compilación 2 | «Frankie Ruíz - Tú Con Él (Visualizer)» y otro resultado de una búsqueda distinta | Fallan: «No se pudo reproducir» / «Este contenido no está disponible en esta versión» |
| Repetir con la compilación 3 | La misma canción | Usuario: «Sí, ahora sí deja» |
| Audio al bloquear la pantalla | Prueba guiada solicitando esperar 30 segundos | Usuario confirmó que continúa; duración no medida por el agente |
| Audio al cambiar de aplicación | Prueba guiada solicitando volver a Inicio y esperar 10 segundos | Usuario confirmó que continúa |
| Anuncios insertados durante estas pruebas | Muestra de reproducción de la compilación 3 | Usuario: «No apareció ningún anuncio»; no se extrapola al catálogo |

Indicar también la ejecución de GitHub y versión del IPA instalado. Si la reproducción falla, registrar el mensaje exacto y la búsqueda usada; no incluir credenciales ni URLs temporales.

La instalación de esta compilación se completó mediante AltServer → Shift + clic en su icono → Sideload .ipa, con el iPhone conectado por USB. La copia del IPA en iCloud Drive de Windows no aparecía en el teléfono; no se confirmó la causa de esa sincronización.

Diagnóstico del 14 de octubre: al repetir en Windows la petición IOS de la dependencia, el video público `QEYGxzEGwaM` (coincidencia de título de la captura) y `aqz-KE-bpKQ` responden `playabilityStatus: OK`, con SABR y sin HLS ni formatos combinados. El prototipo rechaza ese formato. Una petición VISIONOS con identificador anónimo de visitante devuelve HLS: se comprobaron HTTP 200 en el manifiesto, una variante H.264 y fragmentos de audio y video de ambos contenidos. No se usaron credenciales ni cookies de cuenta. Esta prueba de red en Windows no demuestra todavía reproducción en el iPhone.

Hito 1 superado con la confirmación del usuario. Se inicia la implementación de cola, controles del sistema y biblioteca del plan aprobado. Las pruebas de tres canciones, dos videos (uno largo), escucha bloqueada de quince minutos, cola, controles, auriculares, persistencia y actualización siguen pendientes.

## Hitos 2 y 3 — pruebas de la entrega integrada

Estos criterios requieren el iPhone real y la versión que integre la biblioteca. No se deducen de la compilación 3 ni de los tests del simulador.

Actualización del 15 de octubre: el código integrado llega a `b6eb12f`, pero todavía no se generó un IPA comprobado. La última ejecución no inició los tests por un bloqueo de facturación/cuota de GitHub. La compilación 3 sigue siendo la instalada; los criterios de la tabla conservan su estado «No probado».

| Criterio | Estado físico | Evidencia que falta |
| --- | --- | --- |
| Buscar y escuchar tres canciones públicas | No probado | Títulos, resultado y versión instalada |
| Ver dos videos públicos, uno de al menos quince minutos | No probado | Títulos, imagen/sonido y duración |
| Escuchar quince minutos con el teléfono bloqueado | No probado | Duración observada, cortes o errores |
| Cambiar entre apps con la nueva versión | No probado | Continuidad del audio |
| Pasar automáticamente por una cola de tres elementos con pantalla bloqueada | No probado | Orden y transición entre los tres |
| Pausar, reanudar, siguiente y anterior desde el sistema | No probado | Resultado de cada comando disponible |
| Desconectar auriculares e interrumpir el audio | No probado | Pausa y reanudación según la intención del usuario |
| Anuncios insertados en la prueba ampliada | No probado | Presencia o ausencia observada en esa muestra |
| Crear, renombrar y borrar una lista; añadir y quitar elementos | No probado | Resultado en la nueva interfaz |
| Guardar y quitar favoritos sin duplicados | No probado | Resultado y conservación de otras entradas |
| Cerrar/abrir y recuperar listas, favoritos, recientes y cola en pausa | No probado | Datos conservados y ausencia de inicio automático |
| Actualizar con el mismo identificador conservando la biblioteca | No probado | Instalación de una actualización posterior con datos previos |
| Búsqueda vacía, contenido no disponible y pérdida de conexión | No probado | Mensajes y posibilidad de continuar usando la biblioteca |
| Texto grande, VoiceOver, teclado y uso con una mano en el teléfono | No probado | La navegación con texto grande y modo oscuro pasó en simulador; falta la comprobación física |

Verificación automática de cola y controles: [38680277405](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38680277405), commit `73fb437`, 51/51 pruebas correctas. Incluye tres transiciones con un WAV local, recuperación de progreso, restauración en pausa, eventos de ruta/interrupción y metadatos. Es evidencia del comportamiento programado en el simulador; no verifica accesorios ni controles físicos del iPhone.
