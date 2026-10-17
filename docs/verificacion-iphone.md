# Comprobación en el iPhone

Última instalación verificada por USB, del 15 de octubre de 2026: versión 0.1.0, compilación 5. Después, el usuario repitió la prueba de Favoritos tras cerrar/reabrir sin Buscar y respondió «La canción se reproduce». El usuario informó después de otra actualización; su lectura por USB se interrumpió al descargarse el teléfono. Antes de la 5, un intento había fallado por autenticación HTTP 503 y la lectura de ese momento confirmó CFBundleVersion=4. Las observaciones se conservan sin atribuirlas retrospectivamente a otra compilación. El IPA actual del PC es la 7, con instalación y comprobación físicas pendientes.

Incidencia posterior de la compilación 4: los datos del favorito, lista y cola se conservan tras pausar/cerrar/reabrir, según la respuesta «Sí» a esa prueba guiada. Sin embargo, el usuario corrigió el alcance de esa confirmación: al intentar reproducir desde Favoritos después de reabrir aparece «No se pudo preparar este contenido. Intenta de nuevo». La captura muestra «Rata Blanca - Talisman (AUDIO)», de «Lo Mejor del Rock Argentino». Buscar la misma canción y reproducirla hace que después también funcione desde Favoritos, confirmado explícitamente por el usuario. La persistencia de datos y la reproducción posterior son comprobaciones distintas.

Dispositivo: iPhone 13. iOS: 26.2 (información del usuario).

Prototipo de la primera prueba: versión 0.1.0/2, commit `6c619ac`. Versión que funcionó en el teléfono: 0.1.0/3, commit `586a761`, [CI 38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279). Actualización instalada por USB: 0.1.0/5, commit público `9850a39`, mismo código que `65d54fc` del repositorio privado. [CI 38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217): 71/71 pruebas unitarias, 4/4 de interfaz y Release/IPA correctos. Los tests usan respuestas controladas y un WAV local; no demuestran reproducción real de YouTube en el iPhone.

## Compilación 7 disponible: comprobaciones físicas pendientes

[38997159679](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38997159679): 147 unitarias, 16 de interfaz y Release correctos. El IPA canónico se verificó como 0.1.0/7, SHA-256 `ba32cf9626f986e25f40f3af76ce2ace0352ea1473b8dbebabf10c147a2972c6`. Se inspeccionaron cuatro capturas finales. Antes de atribuir resultados a esta entrega, instalarla sobre la app existente y leer por USB `CFBundleVersion=7`.

La tabla de ocho recorridos de [cambios-compilacion-7.md](cambios-compilacion-7.md#pruebas-físicas-pendientes) queda pendiente en el teléfono: prioridad de duración en búsqueda/radio, Blues, género personalizado al reabrir, ambos deslizamientos en pausa, cola vacía persistente con biblioteca conservada, protección mientras reproduce y favorito en frío. Deben repetirse también los recorridos de la ampliación anterior. Los tests con WAV y metadatos controlados comprueban el programa, no la afinidad del catálogo ni los controles físicos de iOS.

## Compilación 6 — evidencia y comprobaciones anteriores

La [ejecución 38956368533](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38956368533) pasó 130 unitarias, 13 pruebas de interfaz y Release. El IPA se verificó como 0.1.0/6, SHA-256 `6e4c11ee33b45a298e242f9042d3872ac439ee9385b3204349d76d6071a8506f`; ahora se conserva en `build/anteriores/ReproductorPersonal-compilacion-6.ipa`. Se inspeccionaron ocho capturas del simulador. El usuario informó de una actualización, pero no se completó su lectura por USB; esta evidencia no acredita los recorridos físicos de historial, imagen, búsqueda, descubrimiento y radio.

| Función | Recorrido que comprobar | Estado físico |
| --- | --- | --- |
| Conservación de biblioteca | Tras actualizar sobre la app existente, revisar favorito, lista, Historial y cola previos; reabrir en pausa | Pendiente |
| Favorito en frío | Pausar, cerrar desde el selector y reproducir directamente desde Favoritos sin Buscar; repetir | Pendiente |
| Imagen en iOS | Reproducir, bloquear y abrir el Centro de control; cambiar de canción y comprobar que cambia su imagen | Pendiente |
| Aleatorio y regreso | Mezclar próximos elementos mientras suena una canción; comprobar que conserva su posición y que Anterior/Siguiente recorren la cola | Pendiente |
| Resultados al escribir | Escribir «Tú con él» sin pulsar Buscar; cambiar y borrar rápidamente la consulta y comprobar los resultados vigentes | Pendiente |
| Para ti / Por descubrir | Después de escuchar y guardar canciones, vaciar Buscar; revisar recomendaciones y que Por descubrir omite lo escuchado | Pendiente |
| Radio por género | Iniciar Salsa y después Rock; comprobar afinidad, varias transiciones con pantalla bloqueada y un avance natural | Pendiente |
| Radio desde canción | Iniciar radio desde los tres puntos; avanzar más de diez posiciones desde los controles bloqueados, dejando empezar cada canción, para superar el lote inicial | Pendiente |
| Prioridad y desactivación | Añadir una canción a una radio y comprobar que sigue antes de las sugeridas; desactivar Continuar automáticamente y comprobar que se retiran las futuras sugerencias | Pendiente |

Registrar títulos, resultado y versión instalada de cada recorrido. Los fallos de conexión o candidatos no disponibles deben conservar la biblioteca y permitir reintentar. Las pruebas con WAV en simulador y las consultas de metadatos en Windows se documentan por separado.

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
| Escuchar quince minutos con el teléfono bloqueado | Reportado como correcto; compilación sin confirmar | Después de pedir una cola suficiente, anotar la hora y escuchar quince minutos bloqueado, respondió «Sí, sin problemas y sin anuncios». Duración de la prueba guiada confirmada por el usuario, no cronometrada por el agente |
| Cambiar entre apps con la nueva versión | Reportado como correcto; compilación sin confirmar | Respondió «Sí» a si la música continúa sin interrupciones tras abrir Notas durante un minuto y volver a Reproductor |
| Pasar automáticamente por una cola de tres elementos con pantalla bloqueada | Pasó según el usuario | Confirmó continuidad y paso automático a la segunda y tercera tras la guía; duración no medida |
| Pausar, reanudar, siguiente y anterior desde el sistema | Reportado como correcto; compilación sin confirmar | Tras pedirle una cola de tres elementos y probar los cuatro controles con el iPhone bloqueado, respondió «Sí, guarda» |
| Desconectar auriculares e interrumpir el audio | No probado | Pausa y reanudación según la intención del usuario |
| Anuncios insertados en la prueba ampliada | Ninguno reportado en la muestra; compilación sin confirmar | Usuario: «Sí, sin problemas y sin anuncios» tras la escucha guiada de quince minutos; no se extrapola a todo el catálogo |
| Crear, renombrar y borrar una lista; añadir y quitar elementos | Parcial | Crear «Mi música», añadir una canción y conservarla al reabrir confirmados; faltan renombrar, quitar y borrar |
| Guardar y quitar favoritos sin duplicados | Parcial | Guardar y conservar el favorito confirmados; faltan quitar y comprobar duplicados |
| Cerrar/abrir y recuperar listas, favoritos, recientes y cola en pausa | Parcial | Favorito, lista y cola conservados y reproducción en pausa confirmados; Recientes no comprobado |
| Reproducir un favorito inmediatamente después de reabrir | Pasó según el usuario en 5 verificada por USB | Después de pausa, cierre desde las apps recientes, reapertura y reproducción directa de «Rata Blanca - Talisman (AUDIO)» sin Buscar, respondió «La canción se reproduce». Un recorrido; audio no observado por el agente |
| Actualizar con el mismo identificador conservando la biblioteca | Parcial: instalación y favorito previo confirmados | La nueva lectura del mismo identificador acredita 0.1.0/5 y el favorito previo reproduce. Falta comprobar por separado listas, recientes y cola previos |
| Búsqueda vacía, contenido no disponible y pérdida de conexión | No probado | Mensajes y posibilidad de continuar usando la biblioteca |
| Texto grande, VoiceOver, teclado y uso con una mano en el teléfono | No probado | La navegación con texto grande y modo oscuro pasó en simulador; falta la comprobación física |

Verificación automática de cola y controles: [38680277405](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38680277405), commit `73fb437`, 51/51 pruebas correctas. Incluye tres transiciones con un WAV local, recuperación de progreso, restauración en pausa, eventos de ruta/interrupción y metadatos. Es evidencia del comportamiento programado en el simulador; no verifica accesorios ni controles físicos del iPhone.

Verificación integrada de la compilación 4: [38753161729](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38753161729), 73/73 pruebas y paquete Release correctos. Se inspeccionaron las capturas de Buscar con el reproductor compacto y de Biblioteca con texto grande/modo oscuro: texto visible, controles separados y navegación operable. El recorrido completo de buscar, guardar favorito, crear lista y añadir contenido pasa. Sigue pendiente la comprobación física completa de accesibilidad.

Diagnóstico del favorito en frío: en Windows, sin cookies ni credenciales, la petición nativa inicial para el video `2tkT5Divh0A` devuelve SABR y la página `/watch` devuelve HTTP 429. La API de búsqueda sí devuelve HTTP 200 y un visitante anónimo; con él se obtiene HLS y su manifiesto HTTP 200. Consultar la API con el identificador guardado, sin búsqueda manual, también funciona. En otra petición fría el perfil inicial devolvió `LOGIN_REQUIRED` antes de inicializar el contexto; por eso la prueba cubre preparar el visitante antes de la petición del reproductor. Son observaciones de red en Windows, no códigos HTTP medidos en el iPhone. La comparación del usuario confirma que la búsqueda previa cambia el resultado en su teléfono. No se han modificado los favoritos ni guardado URLs temporales para resolverlo.

## Actualización 0.1.0/5 — confirmación anterior corregida posteriormente

La compilación 5 inicializa el visitante anónimo mediante la API existente antes de solicitar el reproductor. Las dos regresiones nuevas fallaron en [38811681313](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38811681313) antes de la corrección y pasan en [38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217): 71/71 unitarias, 4/4 de interfaz y Release correctos. El recorrido de interfaz también reproduce un favorito después de relanzar la app, con audio local controlado. Se conservan separados los resultados de red en Windows, simulador y contenido real en el iPhone.

Reporte anterior del 15 de octubre de 2026: después de la guía de actualización a la compilación 5, pausa, cierre desde el selector, reapertura y reproducción directa desde Biblioteca → Favoritos sin pasar por Buscar, el usuario respondió: «Ahora si se deja». Se registró originalmente como una prueba pasada, pero el usuario después corrigió esa confirmación y la lectura por USB mostró que todavía tenía la compilación 4. Esta respuesta histórica no acredita el comportamiento de la 5. No se observaron directamente el teléfono ni el audio; tampoco se confirmaron por separado listas, recientes y cola conservados durante la actualización ni varias repeticiones.

## Controles del sistema — confirmación del usuario

El 15 de octubre de 2026, después de la guía de reproducir una canción, añadir otras dos a la cola, bloquear el iPhone y probar pausa, reanudación, siguiente y anterior desde iOS, el usuario respondió «Sí, guarda» a «¿Funcionan los cuatro?». Se conserva el reporte de los cuatro comandos como pasados en una versión que no se había verificado. Esta confirmación no aporta evidencia de la compilación 5, duración medida de escucha, resultados de auriculares/interrupciones ni conservación completa durante una actualización.

## Escucha prolongada — confirmación del usuario

El 15 de octubre de 2026 se pidió preparar una cola de más de quince minutos, anotar la hora de inicio y escuchar quince minutos con el iPhone bloqueado, comprobando continuidad, avance automático, anuncios y errores. El usuario respondió «Sí, sin problemas y sin anuncios». Se conserva ese reporte de una versión que no se había verificado: sin cortes ni errores informados, cambios automáticos y ningún anuncio observado en esa muestra. No se proporcionaron títulos ni horas de inicio/final; el agente no midió la duración ni observó directamente el teléfono. Esta muestra no acredita la compilación 5, todos los videos, accesorios ni la conservación completa de la biblioteca.

## Cambiar de aplicación — confirmación del usuario

El 15 de octubre de 2026 se pidió reproducir una canción, abrir Notas durante un minuto y volver a Reproductor. El usuario respondió «Sí» a si la música continuaba sin interrupciones. Se conserva ese reporte de una versión que no se había verificado; no se observó directamente el teléfono ni se midió el intervalo. No acredita la compilación 5. Las demás pruebas de videos, accesorios, biblioteca, actualización y accesibilidad permanecen abiertas.

## Corrección de la evidencia y primer intento de instalación

Después de las confirmaciones anteriores, el usuario repitió la prueba de cerrar/reabrir y comunicó que el favorito no reproduce. Aclaró: «Creo que no lo había subido antes y creo que no lo había probado antes, bien». La captura de AltServer indica que ese intento de instalar ReproductorPersonal.ipa falló con «Apple’s authentication servers returned an error (HTTP 503)». Ese mensaje confirma un intento fallido, no la compilación que ya está instalada ni una caída global de Apple.

Se reabrió la prueba física de Favoritos y se retiró la atribución de los resultados de controles, escucha prolongada y cambio de app a la compilación 5. Sus respuestas originales se conservan arriba como historial, con esta corrección vigente. El IPA del PC se verificó nuevamente: 0.1.0/5, SHA-256 `d90479b4ea258c7c564515605115ac39c4e3381af1dfd5d2348f87e64b187783`. AltServer instalado en Windows: 1.8.0.0. Se decidió verificar la instalación directamente antes de repetir el favorito sin buscar previamente.

### Lectura anterior por USB: compilación 4

Con el iPhone conectado por USB y desbloqueado, se consultó la información de Reproductor mediante el servicio de instalación de iOS, usando el emparejamiento existente y sin instalar ni borrar aplicaciones. Resultado anterior: nombre Reproductor, versión 0.1.0, compilación 4. El IPA del PC era 0.1.0/5. Esa lectura acreditó que la corrección nueva todavía no estaba instalada cuando se repitió el fallo.

### Instalación confirmada por USB: compilación 5

Se cerraron las instancias de AltServer y se inició una sola. Mediante Computer Use se seleccionó el archivo canónico `build/ReproductorPersonal.ipa` en la ventana Abrir de AltServer; el usuario completó personalmente el inicio de sesión de Apple. Después informó: «En el iphone en la app de Reproductor aparece un punto azul al lado».

Se repitió la lectura de metadatos por USB con el emparejamiento existente. Resultado directo: nombre Reproductor, versión 0.1.0, compilación 5. Esta lectura confirma la instalación del paquete nuevo. No se registraron cuentas, identificadores del dispositivo ni metadatos de otras apps. El error HTTP 503 del intento anterior no impidió esta instalación; no se ha demostrado su causa.

Después de verificar esa versión instalada, se pidió al usuario pausar, cerrar la app desde las apps recientes, reabrir y reproducir «Rata Blanca - Talisman (AUDIO)» directamente desde Biblioteca → Favoritos, sin pasar por Buscar. Respondió «La canción se reproduce». Se registra un recorrido de reproducción después de reapertura como pasado según el usuario en la compilación 5 verificada. No se observó directamente el audio ni se informaron varias repeticiones. El favorito previo se conservó; la conservación completa de listas, recientes y cola permanece pendiente.
