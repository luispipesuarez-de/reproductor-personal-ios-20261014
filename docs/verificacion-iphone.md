# Comprobación en el iPhone

Estado: compilación 3 instalada y probada en el iPhone el 14 de octubre de 2026, con reproducción, continuidad al salir/bloquear y sin anuncios observados en esa muestra. En la compilación 4, el usuario confirmó la prueba guiada de una cola de tres canciones que avanza automáticamente con la pantalla bloqueada. En la compilación 5, el usuario confirmó que la prueba guiada de reproducción desde Favoritos después de reabrir ya funciona. También confirmó los cuatro controles de iOS con pantalla bloqueada: pausa, reanudación, siguiente y anterior. También confirmó la escucha guiada de quince minutos con pantalla bloqueada, cambios automáticos de canción y ausencia de cortes y anuncios en esa muestra. La validación física es parcial y las demás comprobaciones siguen abiertas.

Incidencia posterior de la compilación 4: los datos del favorito, lista y cola se conservan tras pausar/cerrar/reabrir, según la respuesta «Sí» a esa prueba guiada. Sin embargo, el usuario corrigió el alcance de esa confirmación: al intentar reproducir desde Favoritos después de reabrir aparece «No se pudo preparar este contenido. Intenta de nuevo». La captura muestra «Rata Blanca - Talisman (AUDIO)», de «Lo Mejor del Rock Argentino». Buscar la misma canción y reproducirla hace que después también funcione desde Favoritos, confirmado explícitamente por el usuario. La persistencia de datos y la reproducción posterior son comprobaciones distintas.

Dispositivo: iPhone 13. iOS: 26.2 (información del usuario).

Prototipo de la primera prueba: versión 0.1.0/2, commit `6c619ac`. Versión que funcionó en el teléfono: 0.1.0/3, commit `586a761`, [CI 38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279). Actualización disponible: 0.1.0/5, commit público `9850a39`, mismo código que `65d54fc` del repositorio privado. [CI 38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217): 71/71 pruebas unitarias, 4/4 de interfaz y Release/IPA correctos. Los tests usan respuestas controladas y un WAV local; no demuestran reproducción real de YouTube en el iPhone.

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

Hito 1 superado con la confirmación del usuario. Cola, controles del sistema y biblioteca están implementados en la compilación 4. La prueba guiada de tres canciones en cola con pantalla bloqueada está confirmada. El estado actual de los demás criterios y de las comprobaciones de la compilación 5 figura en la tabla siguiente.

## Hitos 2 y 3 — pruebas de la entrega integrada

Estos criterios requieren el iPhone real y la versión que integre la biblioteca. No se deducen de la compilación 3 ni de los tests del simulador.

Entrega anterior del 15 de octubre: el IPA 0.1.0/4 se instaló desde `build/ReproductorPersonal.ipa`. Se generó mediante una copia pública del código autorizada por el usuario después del bloqueo de cuota/facturación del repositorio privado. Tras la guía de actualización y la aclaración de compatibilidad, el usuario respondió: «Perfecto. Ya lo comprobé y se dejó sin inconveniente». Después se le pidió reproducir una canción, añadir otras dos a la cola, bloquear el teléfono y comprobar el paso automático a la segunda y tercera. Respondió: «Perfecto. Si sirvió». Se registran las observaciones de esa prueba; los títulos y la duración total no se indicaron. No se deducen de ella quince minutos medidos, comandos del sistema, persistencia ni ausencia de anuncios.

| Criterio | Estado físico | Evidencia / pendiente |
| --- | --- | --- |
| Buscar y escuchar tres canciones públicas | Pasó según el usuario | Confirmó la guía de tres canciones; títulos no indicados |
| Ver dos videos públicos, uno de al menos quince minutos | No probado | Títulos, imagen/sonido y duración |
| Escuchar quince minutos con el teléfono bloqueado | Pasó en 5 según el usuario | Después de pedir una cola suficiente, anotar la hora y escuchar quince minutos bloqueado, respondió «Sí, sin problemas y sin anuncios». Duración de la prueba guiada confirmada por el usuario, no cronometrada por el agente |
| Cambiar entre apps con la nueva versión | Pasó en 5 según el usuario | Respondió «Sí» a si la música continúa sin interrupciones tras abrir Notas durante un minuto y volver a Reproductor |
| Pasar automáticamente por una cola de tres elementos con pantalla bloqueada | Pasó según el usuario | Confirmó continuidad y paso automático a la segunda y tercera tras la guía; duración no medida |
| Pausar, reanudar, siguiente y anterior desde el sistema | Pasó en 5 según el usuario | Tras pedirle una cola de tres elementos y probar los cuatro controles con el iPhone bloqueado, respondió «Sí, guarda» |
| Desconectar auriculares e interrumpir el audio | No probado | Pausa y reanudación según la intención del usuario |
| Anuncios insertados en la prueba ampliada | Ninguno observado en la muestra de 5 | Usuario: «Sí, sin problemas y sin anuncios» tras la escucha guiada de quince minutos; no se extrapola a todo el catálogo |
| Crear, renombrar y borrar una lista; añadir y quitar elementos | Parcial | Crear «Mi música», añadir una canción y conservarla al reabrir confirmados; faltan renombrar, quitar y borrar |
| Guardar y quitar favoritos sin duplicados | Parcial | Guardar y conservar el favorito confirmados; faltan quitar y comprobar duplicados |
| Cerrar/abrir y recuperar listas, favoritos, recientes y cola en pausa | Parcial | Favorito, lista y cola conservados y reproducción en pausa confirmados; Recientes no comprobado |
| Reproducir un favorito inmediatamente después de reabrir | Pasó en 5 según el usuario; falló en 4 | Tras la guía de actualizar, cerrar/reabrir y reproducir desde Favoritos sin pasar por Buscar: «Ahora si se deja». No se indicó número de repeticiones |
| Actualizar con el mismo identificador conservando la biblioteca | No probado | Instalación de una actualización posterior con datos previos |
| Búsqueda vacía, contenido no disponible y pérdida de conexión | No probado | Mensajes y posibilidad de continuar usando la biblioteca |
| Texto grande, VoiceOver, teclado y uso con una mano en el teléfono | No probado | La navegación con texto grande y modo oscuro pasó en simulador; falta la comprobación física |

Verificación automática de cola y controles: [38680277405](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38680277405), commit `73fb437`, 51/51 pruebas correctas. Incluye tres transiciones con un WAV local, recuperación de progreso, restauración en pausa, eventos de ruta/interrupción y metadatos. Es evidencia del comportamiento programado en el simulador; no verifica accesorios ni controles físicos del iPhone.

Verificación integrada de la compilación 4: [38753161729](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38753161729), 73/73 pruebas y paquete Release correctos. Se inspeccionaron las capturas de Buscar con el reproductor compacto y de Biblioteca con texto grande/modo oscuro: texto visible, controles separados y navegación operable. El recorrido completo de buscar, guardar favorito, crear lista y añadir contenido pasa. Sigue pendiente la comprobación física completa de accesibilidad.

Diagnóstico del favorito en frío: en Windows, sin cookies ni credenciales, la petición nativa inicial para el video `2tkT5Divh0A` devuelve SABR y la página `/watch` devuelve HTTP 429. La API de búsqueda sí devuelve HTTP 200 y un visitante anónimo; con él se obtiene HLS y su manifiesto HTTP 200. Consultar la API con el identificador guardado, sin búsqueda manual, también funciona. En otra petición fría el perfil inicial devolvió `LOGIN_REQUIRED` antes de inicializar el contexto; por eso la prueba cubre preparar el visitante antes de la petición del reproductor. Son observaciones de red en Windows, no códigos HTTP medidos en el iPhone. La comparación del usuario confirma que la búsqueda previa cambia el resultado en su teléfono. No se han modificado los favoritos ni guardado URLs temporales para resolverlo.

## Actualización 0.1.0/5 — Favoritos en frío confirmado por el usuario

La compilación 5 inicializa el visitante anónimo mediante la API existente antes de solicitar el reproductor. Las dos regresiones nuevas fallaron en [38811681313](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38811681313) antes de la corrección y pasan en [38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217): 71/71 unitarias, 4/4 de interfaz y Release correctos. El recorrido de interfaz también reproduce un favorito después de relanzar la app, con audio local controlado. Se conservan separados los resultados de red en Windows, simulador y contenido real en el iPhone.

Resultado físico del 15 de octubre de 2026: después de la guía de actualización a la compilación 5, pausa, cierre desde el selector, reapertura y reproducción directa desde Biblioteca → Favoritos sin pasar por Buscar, el usuario respondió: «Ahora si se deja». Se registra la reproducción del favorito tras reabrir como pasada según esa confirmación. No se observaron directamente el teléfono ni el audio; la respuesta no confirma por separado listas, recientes y cola conservados durante la actualización ni varias repeticiones. La captura anterior se conserva como fallo de la compilación 4. Las demás pruebas de uso cotidiano, biblioteca, actualización y accesibilidad permanecen abiertas.

## Controles del sistema — confirmación del usuario

El 15 de octubre de 2026, después de la guía de reproducir una canción, añadir otras dos a la cola, bloquear el iPhone y probar pausa, reanudación, siguiente y anterior desde iOS, el usuario respondió «Sí, guarda» a «¿Funcionan los cuatro?». Se registran los cuatro comandos como pasados según el usuario en la compilación 5. Esta confirmación no aporta duración medida de escucha, resultados de auriculares/interrupciones ni conservación completa durante una actualización.

## Escucha prolongada — confirmación del usuario

El 15 de octubre de 2026 se pidió preparar una cola de más de quince minutos, anotar la hora de inicio y escuchar quince minutos con el iPhone bloqueado, comprobando continuidad, avance automático, anuncios y errores. El usuario respondió «Sí, sin problemas y sin anuncios». Se registra la prueba guiada como pasada según el usuario en la compilación 5: sin cortes ni errores informados, cambios automáticos y ningún anuncio observado en esa muestra. No se proporcionaron títulos ni horas de inicio/final; el agente no midió la duración ni observó directamente el teléfono. Esta muestra no acredita todos los videos, accesorios ni la conservación completa de la biblioteca.

## Cambiar de aplicación — confirmación del usuario

El 15 de octubre de 2026 se pidió reproducir una canción, abrir Notas durante un minuto y volver a Reproductor. El usuario respondió «Sí» a si la música continuaba sin interrupciones. Se registra esa prueba guiada como pasada según el usuario en la compilación 5; no se observó directamente el teléfono ni se midió el intervalo. Las demás pruebas de videos, accesorios, biblioteca, actualización y accesibilidad permanecen abiertas.
