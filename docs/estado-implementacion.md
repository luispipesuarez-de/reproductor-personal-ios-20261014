# Estado de la primera etapa

Entrega preparada: versión 0.1.0, compilación 4, código `0b391ba`, rama `feat/reproductor-ios` del [repositorio privado](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014). El IPA está comprobado para firma personal. La validación física es parcial: el usuario confirmó el avance automático de una cola de tres canciones con pantalla bloqueada. La biblioteca y las demás comprobaciones siguen abiertas.

## Comportamiento implementado

- Búsqueda por texto, video y audio mediante un único AVQueuePlayer compartido al navegar.
- Cola con entradas independientes para videos repetidos, avance automático, selección, eliminación y preparación del siguiente elemento.
- Pausa/reanudación, anterior/siguiente, saltos de quince segundos y progreso cuando el flujo lo admite. Publicación de metadatos y comandos del sistema; manejo de interrupciones y desconexión de auriculares.
- Recuperación limitada de un flujo caducado, conservando el progreso. Un error de otro tipo se muestra; el usuario puede reintentar.
- Favoritos sin duplicados; listas con nombre y elementos repetibles; recientes al comenzar la reproducción.
- Persistencia JSON en el contenedor privado: escritura atómica antes de publicar el cambio. Un archivo corrupto o con versión desconocida bloquea escrituras para conservar sus bytes. Los errores de almacenamiento se muestran en la interfaz.
- Restauración de biblioteca y cola en pausa; los flujos temporales se resuelven de nuevo al reanudar. Interfaz con Buscar/Biblioteca, reproductor compacto y controles nativos de video/PiP.

La extracción consulta YouTube desde el dispositivo. Se conservan HLS/MP4 y la ruta alternativa HLS para respuestas SABR, sin servidor propio ni credenciales de cuenta. La integración con la cuenta queda para la segunda etapa.

## Verificación de la compilación 4

[Ejecución 38753161729](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38753161729), commit público `a16da8f`, con el mismo código que `0b391ba` del repositorio privado:

| Comprobación | Resultado |
| --- | --- |
| `bash scripts/ci.sh test` | 69/69 unitarias y 4/4 de interfaz; cero fallos |
| Cola y recuperación | Transiciones nativas con WAV local, identidad de entradas, reintento y progreso conservado |
| Intención de reproducción | Play/pausa nativos, pausa durante preparación y reanudación tras interrupción cubiertos por regresiones |
| Biblioteca | Archivos reales: ida/vuelta, duplicados, fallos de escritura y protección de datos incompatibles/corruptos |
| Interfaz | Buscar→favorito→crear/añadir lista; reapertura en pausa; estados vacío/error; navegación con texto grande y modo oscuro |
| `bash scripts/ci.sh ipa` | Release correcto, artefacto ReproductorPersonal-2 |
| Contenido del IPA | CRC correcto, Mach-O arm64, identificador y versión esperados, audio en segundo plano; proveedor de pruebas ausente |

Herramientas de CI: Xcode 26.6 (17F113), XcodeGen 2.46.0; simulador iPhone 17 Pro. Las pruebas de reproducción usan un WAV local y datos controlados. No demuestran compatibilidad de YouTube en el teléfono ni funcionamiento de accesorios físicos. Las capturas del simulador se inspeccionaron para verificar la distribución y legibilidad de la interfaz.

Archivo: `build/ReproductorPersonal.ipa`. Identificador: `personal.reproductor.ios`. Versión: 0.1.0/4. iOS mínimo: 16.0. `UIBackgroundModes: [audio]`. IPA sin firmar. Tamaño: 1.843.134 bytes. SHA-256: `3b00cd74ff20160f426c9008acfb3fd19ff12fc8a85b1330fa049bf7f3fa6ef5`. La compilación 3 comprobada se conserva en `build/anteriores/ReproductorPersonal-compilacion-3.ipa`.

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
- Considerar la evidencia física por separado de CI. Los resultados de la compilación 3 no validan automáticamente la compilación 4.

La revisión anterior del prototipo corrigió selección de formatos y preparación duplicada con regresiones. La ruta HLS alternativa pasó [38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279), con 28 pruebas y el IPA de la compilación 3. El usuario confirmó en esa versión imagen/sonido, continuidad al salir y bloquear y ausencia de anuncios en la muestra probada.

## Pruebas físicas abiertas

El usuario confirmó la prueba guiada de tres canciones y su avance automático con la pantalla bloqueada. La primera etapa sigue pendiente de dos videos (uno de al menos quince minutos), quince minutos medidos de audio bloqueado, controles del sistema, auriculares/interrupciones, biblioteca, conservación durante una actualización, fallos de conexión y accesibilidad. No se promete cobertura del catálogo ni ausencia universal de anuncios.

La instalación requiere participación del usuario porque esta sesión no tiene control del iPhone. Sigue [instalacion-iphone.md](instalacion-iphone.md) y registra las observaciones en [verificacion-iphone.md](verificacion-iphone.md). El registro y la rama se conservan para continuar con esos resultados.
