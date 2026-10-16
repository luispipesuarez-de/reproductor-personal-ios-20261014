# Estado de Reproductor — entrega 0.1.0/6

El IPA de la compilación 6 está verificado y disponible en `build/ReproductorPersonal.ipa`. **Instalación y pruebas físicas pendientes**: la última versión confirmada por USB en el iPhone es la 5. La rama de esta ampliación es `codex/descubrimiento-radio`; se conserva la entrega anterior.

## Funciones integradas, de menor a mayor dificultad

| Función | Comportamiento implementado |
| --- | --- |
| Historial | Biblioteca → Historial permite volver a escuchar; se actualiza cuando empieza la reproducción |
| Imagen en los controles de iOS | Miniatura asíncrona con caché y protección frente a imágenes de una selección anterior |
| Aleatorio y volver atrás | Mezclar mi música, favoritos, listas y cola; la mezcla de la cola conserva canción/progreso y prioridad manual |
| Resultados al escribir | Búsqueda a partir de dos caracteres, espera de 400 ms y descarte de respuestas antiguas |
| Para ti | Recomendaciones dentro de Buscar basadas en historial/favoritos locales |
| Por descubrir | Candidatos que no figuran en el historial local; no implica lanzamientos recientes |
| Radio continua | Desde una canción o un género, incluidos géneros personalizados; nuevos lotes, prioridad manual y opción de desactivar sugerencias |

El controlador mantiene radio y persistencia fuera de las vistas. La biblioteca y la cola se restauran en pausa. Se reutilizan SwiftUI, AVFoundation, MediaPlayer y la dependencia fijada existente, sin añadir dependencias ni servidor propio. La afinidad musical procede de metadatos y debe comprobarse escuchando en el iPhone.

## Evidencia de la compilación 6

[38956368533](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38956368533) terminó correctamente sobre el commit público `343a545ff8789e1837af78fe3ee8d078df468bac`, con los mismos 62 archivos de compilación que el commit privado `8df75f7627e75ec028f53564cc38aab7d781ead2`.

| Comprobación | Resultado |
| --- | --- |
| Suite completa | 130/130 unitarias y 13/13 de interfaz; cero fallos; TEST SUCCEEDED |
| Release | BUILD SUCCEEDED; artefacto ReproductorPersonal-21 |
| ZIP del artefacto | SHA-256 coincide con el digest publicado por GitHub antes de extraer |
| IPA | CRC correcto, aplicación única, identificador `personal.reproductor.ios`, versión 0.1.0/6, Mach-O arm64, iOS mínimo 16.0, audio en segundo plano |
| Exclusión de pruebas | Proveedor, audio, recursos y argumentos de pruebas de interfaz ausentes de Release |
| Capturas | Ocho capturas inspeccionadas: Buscar/recomendaciones, biblioteca, radio, prioridad manual y texto grande/modo oscuro en Buscar, reproductor y cola |
| Copia anterior | Compilación 5 conservada y hash verificado en `build/anteriores/ReproductorPersonal-compilacion-5.ipa` |
| iPhone real | Pendiente instalar, leer versión por USB y repetir los recorridos físicos |

IPA sin firmar, **1.993.999 bytes**. SHA-256: `6e4c11ee33b45a298e242f9042d3872ac439ee9385b3204349d76d6071a8506f`. El archivo canónico se sustituyó después de verificar el artefacto; su copia volvió a pasar la comprobación. AltServer realizará la firma personal durante la instalación.

Xcode 26.6 (17F113), XcodeGen 2.46.0, simulador iPhone 17 Pro. Las pruebas usan metadatos controlados y WAV local. Las consultas anónimas de metadatos realizadas desde Windows y las capturas no demuestran reproducción del catálogo ni controles físicos en el iPhone.

Xcode conserva advertencias de AppIntents, orientaciones de iPad y conversión Sendable del setter usado por el Binding de RadioControls. No hubo errores de compilación. No se ha ejecutado esta entrega en iOS 16, iPad ni todas las orientaciones.

## Revisión y pruebas pendientes

Una revisión independiente del cambio completo encontró cuatro problemas importantes. Todos se reprodujeron con tests que fallaron en [38950354247](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38950354247) y pasaron en la suite final: conservar una elección manual durante el inicio de radio por género; cancelar un Siguiente pendiente al pulsar Anterior en la primera canción; permitir reintentar un elemento sugerido elegido explícitamente; y aplicar realmente el tamaño de texto de accesibilidad a ambas hojas en la prueba de interfaz. Esta última corrección mejora la cobertura de pruebas; la accesibilidad con ajustes reales del teléfono sigue pendiente.

Se conserva como detalle menor diferido el botón nativo **Edit** en inglés dentro de Cola. Las correcciones importantes se verificaron en una sola pasada, sin una segunda revisión.

Falta instalar sobre la app existente con la misma cuenta de Apple, confirmar por USB la compilación 6 y observar biblioteca/favorito en frío, imagen en pantalla bloqueada y Centro de control, radio por género y desde canción con varios cambios bloqueados, mezcla/anterior y prioridad manual. [Guía de uso e instalación](instalacion-iphone.md). [Tabla de pruebas físicas](verificacion-iphone.md). El registro de ejecución se conserva mientras esos criterios permanezcan abiertos.

## Entrega anterior 0.1.0/5 — evidencia histórica

Las secciones siguientes conservan el estado y las observaciones anteriores; no acreditan la instalación ni las pruebas físicas de la 6.

Entrega instalada: versión 0.1.0, compilación 5, código `65d54fc`, rama `feat/reproductor-ios` del [repositorio privado](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014). El IPA del PC está comprobado para firma personal. Después de seleccionar ese archivo en AltServer y de que el usuario completara la autenticación, una nueva lectura por USB confirmó CFBundleShortVersionString=0.1.0 y CFBundleVersion=5. La lectura anterior había confirmado la compilación 4, en la que seguía fallando Favoritos; un intento previo de actualizar había fallado por HTTP 503. Los resultados físicos anteriores se conservan como observaciones del usuario, pero no acreditan la compilación 5.

La compilación 5 prepara el contexto anónimo antes de solicitar la reproducción de un favorito al reiniciar. Las regresiones automáticas y el recorrido de reapertura pasaron. La confirmación anterior «Ahora si se deja» quedó corregida por el reporte posterior de fallo antes de verificar la instalación. Tras comprobar el cambio de CFBundleVersion de 4 a 5, se pidió una nueva prueba de pausa, cierre desde las apps recientes, reapertura y reproducción directa desde Favoritos sin Buscar. El usuario respondió «La canción se reproduce». Este recorrido pasa según el usuario en la compilación verificada. El favorito previo se conservó; aún falta comprobar por separado listas, recientes y cola durante esta actualización.

## Comportamiento implementado

- Búsqueda por texto, video y audio mediante un único AVQueuePlayer compartido al navegar.
- Cola con entradas independientes para videos repetidos, avance automático, selección, eliminación y preparación del siguiente elemento.
- Pausa/reanudación, anterior/siguiente, saltos de quince segundos y progreso cuando el flujo lo admite. Publicación de metadatos y comandos del sistema; manejo de interrupciones y desconexión de auriculares.
- Recuperación limitada de un flujo caducado, conservando el progreso. Un error de otro tipo se muestra; el usuario puede reintentar.
- Favoritos sin duplicados; listas con nombre y elementos repetibles; recientes al comenzar la reproducción.
- Persistencia JSON en el contenedor privado: escritura atómica antes de publicar el cambio. Un archivo corrupto o con versión desconocida bloquea escrituras para conservar sus bytes. Los errores de almacenamiento se muestran en la interfaz.
- Restauración de biblioteca y cola en pausa; los flujos temporales se resuelven de nuevo al reanudar. Interfaz con Buscar/Biblioteca, reproductor compacto y controles nativos de video/PiP.

La extracción consulta YouTube desde el dispositivo. Se conservan HLS/MP4 y la ruta alternativa HLS para respuestas SABR, sin servidor propio ni credenciales de cuenta. La integración con la cuenta queda para la segunda etapa.

## Verificación de la compilación 5

[Ejecución 38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217), commit público `9850a39`, con el mismo código que `65d54fc` del repositorio privado:

| Comprobación | Resultado |
| --- | --- |
| `bash scripts/ci.sh test` | 71/71 unitarias y 4/4 de interfaz; cero fallos |
| Favorito después de reiniciar | Contexto anónimo preparado antes de la primera petición del reproductor; ausencia de contexto devuelve error controlado |
| Cola y recuperación | Transiciones nativas con WAV local, identidad de entradas, reintento y progreso conservado |
| Intención de reproducción | Play/pausa nativos, pausa durante preparación y reanudación tras interrupción cubiertos por regresiones |
| Biblioteca | Archivos reales: ida/vuelta, duplicados, fallos de escritura y protección de datos incompatibles/corruptos |
| Interfaz | Buscar→favorito→crear/añadir lista; reapertura en pausa y reproducción del favorito; estados vacío/error; navegación con texto grande y modo oscuro |
| `bash scripts/ci.sh ipa` | Release correcto, artefacto ReproductorPersonal-4 |
| Contenido del IPA | CRC correcto, Mach-O arm64, identificador y versión esperados, audio en segundo plano; proveedor de pruebas ausente |

Herramientas de CI: Xcode 26.6 (17F113), XcodeGen 2.46.0; simulador iPhone 17 Pro. Las pruebas de reproducción usan un WAV local y datos controlados. No demuestran compatibilidad de YouTube en el teléfono ni funcionamiento de accesorios físicos. Las capturas del simulador se inspeccionaron para verificar la distribución y legibilidad de la interfaz.

Archivo: `build/ReproductorPersonal.ipa`. Identificador: `personal.reproductor.ios`. Versión: 0.1.0/5. iOS mínimo: 16.0. `UIBackgroundModes: [audio]`. IPA sin firmar. Tamaño: 1.839.018 bytes. SHA-256: `d90479b4ea258c7c564515605115ac39c4e3381af1dfd5d2348f87e64b187783`. La compilación 4 anterior se conserva en `build/anteriores/ReproductorPersonal-compilacion-4.ipa`.

Xcode conserva advertencias de extracción de metadatos sin AppIntents y de orientaciones para iPad. No hubo errores de compilación ni fallos de tests. Esta entrega se prepara para el iPhone indicado por el usuario; no se ha realizado validación física en iPad.

## Revisión y decisiones

La revisión independiente de todo el cambio desde `11e4fa9` hasta `690096f` encontró un defecto importante: los controles nativos cambiaban el reproductor sin actualizar la intención de reproducción. Se reprodujo con tres tests que fallaron en [38739434464](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38739434464) y se corrigió en `562ed5b`. La suite completa del nuevo código pasó. No hubo observaciones menores diferidas; no se solicitó una segunda revisión.

Decisiones vigentes:

- Mantener los controles nativos de AVKit/PiP y reconocer sus cambios de intención, distinguiendo pausas internas, interrupciones y final de elemento.
- Las opciones de favorito, lista y cola se presentan en una hoja nativa desde el botón de tres puntos, tras reproducir un fallo intermitente del menú emergente en la prueba de interfaz.
- Un fallo al preparar el siguiente elemento se muestra al llegar a él; no se interrumpe la canción actual ni se salta silenciosamente el error.
- Conservar listas locales y referencias, sin adelantar autenticación, sincronización ni descargas.
- Compilar una copia pública de código autorizada por el usuario, después del bloqueo de cuota/facturación del repositorio privado. La copia tiene historial nuevo y excluye conversaciones, capturas, registros y archivos de cuenta.
- Trabajar en la carpeta y rama aprobadas, usando PowerShell para el registro de tareas en Windows. Las interfaces vacías usadas para demostrar RED ya fueron reemplazadas.
- Considerar la evidencia física por separado de CI. Los resultados físicos de las compilaciones 3 y 4 no validan automáticamente la compilación 5.

La revisión anterior del prototipo corrigió selección de formatos y preparación duplicada con regresiones. La ruta HLS alternativa pasó [38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279), con 28 pruebas y el IPA de la compilación 3. El usuario confirmó en esa versión imagen/sonido, continuidad al salir y bloquear y ausencia de anuncios en la muestra probada.

## Pruebas físicas abiertas

Con la instalación del IPA 0.1.0/5 ya confirmada por USB, la reproducción directa desde Favoritos después de cerrar/reabrir, sin pasar por Buscar, pasó según el usuario para «Rata Blanca - Talisman (AUDIO)». Se conserva ese resultado de un recorrido sin extrapolarlo a otros contenidos. Las observaciones previas de controles, continuidad, escucha guiada de quince minutos y ausencia de anuncios pertenecen a una versión anterior sin verificar. Siguen abiertas las pruebas de dos videos (uno de al menos quince minutos), auriculares/interrupciones, CRUD/recientes, conservación completa durante una actualización, fallos de conexión y accesibilidad.

Las pruebas requieren participación del usuario porque esta sesión no tiene control de la interfaz del iPhone. Sigue [instalacion-iphone.md](instalacion-iphone.md) y registra las observaciones en [verificacion-iphone.md](verificacion-iphone.md). El registro y la rama se conservan para continuar con esos resultados.
