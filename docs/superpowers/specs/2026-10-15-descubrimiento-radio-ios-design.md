# Reproductor: historial, descubrimiento y radio continua

Fecha: 15 de octubre de 2026.

Estado: diseño conversacional aprobado con «Apruebo con recomendaciones dentro de Buscar». Tras presentar este documento para revisión, el usuario respondió «aprobado todo el plan. ejecutalo». La especificación queda aprobada y la ejecución se solicita en esta conversación. El plan técnico desarrolla este alcance sin añadir funciones.

## 1. Objetivo y base comprobada

Ampliar la app personal del usuario para elegir una canción o un género y continuar escuchando, encontrar recomendaciones y canciones por descubrir, consultar lo escuchado, usar reproducción aleatoria y ver la imagen del contenido en los controles de iOS.

El usuario dispone de Windows y un iPhone 13 con iOS 26.2. La app mantiene iOS 16 como mínimo. El historial, los favoritos y las listas se guardan en el teléfono; las consultas y la reproducción requieren Internet y se realizan directamente con YouTube. La nueva etapa conserva esa ejecución local.

La base es la compilación 0.1.0/5, código privado `65d54fc`. Su instalación se comprobó por USB y el usuario confirmó que el favorito «Rata Blanca - Talisman (AUDIO)» reproduce después de cerrar y reabrir, sin pasar por Buscar. Ese recorrido debe seguir funcionando. Los registros de entrega y pruebas físicas anteriores se conservan por separado.

## 2. Funciones ordenadas por dificultad

La dificultad es relativa al código existente y no constituye una estimación de horas.

| Orden | Función | Dificultad | Cambio previsto |
| --- | --- | --- | --- |
| 1 | Historial y volver a escuchar | Baja | Aprovechar Recientes, darle un acceso claro como Historial y mantener el recorrido de Anterior/Siguiente. |
| 2 | Imagen en pantalla bloqueada y Centro de control | Baja–media | Publicar la miniatura con MediaPlayer y actualizarla al cambiar de contenido. |
| 3 | Reproducción aleatoria | Media | Mezclar la música local o los próximos elementos de una cola preservando el actual y el recorrido anterior. |
| 4 | Resultados mientras se escribe | Media | Reutilizar el buscador con una espera breve y protección contra respuestas antiguas. |
| 5 | Recomendaciones | Media–alta | Obtener relacionadas desde canciones del historial y favoritos y combinarlas sin duplicados. |
| 6 | Canciones por descubrir | Media–alta | Usar la misma selección de recomendaciones, excluyendo contenido ya registrado en el historial. |
| 7 | Radio continua por canción y por género | Alta | Reponer candidatos y alimentar la cola con el reproductor activo aunque la interfaz esté en segundo plano. |

## 3. Experiencia integrada

### Buscar

Se conservan las pestañas **Buscar** y **Biblioteca**. Buscar mantiene el campo visible y, cuando está vacío, ofrece:

- Accesos para iniciar radio por Salsa, Rock y otros géneros habituales; también se podrá escribir otro género.
- **Para ti**, a partir de canciones escuchadas o guardadas en esta app.
- **Por descubrir**, con candidatos que todavía no aparecen en el historial local.

Al escribir, aparecen filas de canciones reproducibles con miniatura, título y autor. Se reutiliza `VideoRow`. La búsqueda comienza después de una pausa aproximada de 400 ms y de al menos dos caracteres. El botón y la tecla Buscar permiten enviarla inmediatamente. Una consulta vacía recupera la vista de descubrimiento. Las solicitudes antiguas no sustituyen los resultados de una consulta nueva y las filas coinciden con la consulta visible.

Si todavía no hay historial ni favoritos, se muestran los géneros como punto de partida y se explica cómo se formarán las recomendaciones. Elegir un resultado inicia su reproducción; añadirlo a la cola sigue siendo una acción disponible.

### Biblioteca, historial y navegación

Recientes pasa a presentarse como **Historial**. Se conserva su información existente: una entrada por video, ordenada por su última reproducción; escuchar de nuevo un elemento lo mueve al principio. Tocar una entrada permite volver a escucharla.

Anterior/Siguiente sigue el orden de la cola, también cuando se ha mezclado. La mezcla de los próximos elementos mantiene el actual y el tramo anterior. Al principio del recorrido, Anterior vuelve al inicio del contenido. El historial permite recuperar canciones de sesiones anteriores.

El registro de escucha y la continuidad de la cola deben funcionar durante la reproducción en segundo plano; no dependerán de que Buscar o Biblioteca estén visibles. Solo se registra como escuchado el contenido que comienza a reproducirse, no una solicitud de preparación fallida.

### Aleatorio

Habrá una acción para mezclar Favoritos o una lista y otra para **Mezclar mi música**, combinando favoritos, listas e historial por identificador de video. Una canción presente en varias colecciones aparece una vez en esa combinación.

El botón **Mezclar cola** del reproductor baraja los elementos siguientes. Conserva el contenido actual, su progreso y las identidades de las entradas. Los duplicados añadidos explícitamente a una lista o cola siguen siendo entradas independientes. El orden preparado se conserva al cerrar y reabrir en pausa. Las acciones de mezcla preparan un orden nuevo; no requieren reconstruir después un orden anterior.

### Imagen del contenido

Se usa la miniatura disponible del video como imagen de Ahora suena. La app la carga de forma asíncrona y la publica como `MPMediaItemArtwork`, junto con el título, autor y progreso existentes. iOS gestiona su presentación en la pantalla bloqueada y el Centro de control.

Cambiar rápidamente de canción invalida una carga anterior. La actualización periódica del progreso conserva la imagen ya cargada. Se reutiliza la caché de red de la plataforma; un fallo de imagen mantiene la reproducción y no muestra la portada de la canción anterior. Las descargas y la decodificación tendrán límites adecuados para miniaturas.

## 4. Recomendaciones y géneros

El usuario eligió expresamente **ambas modalidades de radio**:

1. **Desde una canción:** al elegir contenido individual, la continuación automática, activada por defecto, prepara canciones relacionadas. Habrá un control visible para desactivarla y una acción para iniciar una radio desde una canción concreta.
2. **Desde un género:** iniciar Radio Salsa, Radio Rock u otro género consulta candidatos de ese género, comienza con uno de ellos y continúa reponiendo la cola.

YouTubeKit, en la revisión ya fijada, expone recomendaciones y sus continuaciones mediante `MoreVideoInfosResponse`. La clasificación actual de videos no ofrece un género musical fiable para cada resultado. Por eso, la radio por canción utiliza relacionadas como señal de afinidad; la radio por género mantiene la consulta elegida como contexto. La coherencia musical se comprobará con canciones reales, y el usuario podrá cambiar el género o la canción de partida.

Para ti combina candidatos relacionados con una selección pequeña del historial y favoritos, priorizando relevancia y variedad de autores cuando los datos lo permiten. Por descubrir reutiliza ese conjunto y filtra los identificadores ya escuchados. «Por descubrir» significa nuevo para el historial local; puede incluir grabaciones antiguas. No necesita un modelo de aprendizaje ni un servicio propio.

Las recomendaciones son candidatos: su disponibilidad real se comprueba al resolver cada reproducción. La primera implementación validará las respuestas actuales de relacionadas y continuación antes de basar la radio en ellas.

## 5. Cola y continuidad

Se conserva un único `AVQueuePlayer` y el mecanismo existente que prepara el siguiente elemento. La nueva lógica obtiene pequeños lotes de candidatos antes de que la cola se agote, con una sola reposición activa por sesión. Solo se prepara por adelantado el recurso multimedia siguiente, como en la base actual.

- Las canciones añadidas manualmente tienen prioridad sobre las sugerencias automáticas pendientes.
- Los candidatos automáticos excluyen el contenido actual, los que ya están pendientes y las repeticiones recientes del recorrido. Esta regla no elimina duplicados pedidos expresamente por el usuario.
- Cambiar de género, iniciar otra radio o desactivar la continuación invalida las respuestas tardías y las tareas de reposición anteriores.
- Al agotarse una lista elegida manualmente, la continuación activada puede obtener relacionadas de su último elemento. Desactivarla permite terminar en el último elemento de la cola.
- Al cerrar y reabrir, se recuperan la cola y el contexto necesario en pausa; el audio comienza por decisión del usuario.
- El historial y la persistencia de la cola se atienden desde el flujo de reproducción, con la biblioteca local disponible, incluso con las pantallas de contenido ocultas.

### Errores

Un fallo al buscar más recomendaciones no interrumpe la canción que ya suena ni elimina la cola manual. Si no quedan candidatos válidos se muestra el estado y se ofrece reintentar o elegir otro punto de partida. Las consultas y continuaciones tienen un límite por reposición para evitar bucles sin resultados.

Si falla un candidato automático al prepararse, se prueban hasta tres candidatos consecutivos y luego se detiene el avance con un aviso. El fallo de un elemento elegido manualmente conserva las acciones Reintentar/Siguiente existentes. La falta de conexión mantiene accesible la biblioteca y los controles disponibles.

## 6. Cambios mínimos en la estructura

Se reutilizan las responsabilidades actuales:

| Parte existente | Ampliación |
| --- | --- |
| `YouTubeClient` y `YouTubeProviding` | Consultar relacionadas y páginas de candidatos usando la misma instancia anónima y la dependencia fijada. |
| `YouTubeMapping` | Compartir la transformación de videos de búsqueda y recomendaciones. |
| `SearchViewModel` y `SearchView` | Búsqueda al escribir y secciones de géneros, Para ti y Por descubrir. |
| `PlaybackQueue` y `PlaybackController` | Mezcla, prioridad manual, sesión de radio, reposición e invalidación de solicitudes antiguas. |
| `SystemMediaControls` | Carga de miniatura y publicación de imagen en los metadatos del sistema. |
| `LibraryStore`, modelos y vistas | Acceso a Historial y conservación de cola, preferencias y datos existentes. |

La selección de candidatos se comparte entre descubrimiento y radio; la reproducción continúa siendo responsabilidad del controlador. Las vistas muestran estados y solicitan acciones. Se añadirá únicamente el código necesario para esa separación, sin un sistema genérico de proveedores nuevo.

Se mantienen Foundation, SwiftUI, AVFoundation, MediaPlayer y YouTubeKit. La resolución de recursos conserva la inicialización del visitante anónimo que corrigió Favoritos en la compilación 5. La nueva información persistida tendrá valores por defecto al leer archivos anteriores. La biblioteca no guardará recursos multimedia ni URLs temporales de reproducción.

## 7. Orden de entrega y comprobación

El plan detallado desarrollará tres bloques, en este orden:

1. **Biblioteca y controles:** historial, navegación de cola, imagen y aleatorio.
2. **Búsqueda y descubrimiento:** resultados al escribir, consultas de recomendaciones y secciones dentro de Buscar.
3. **Radio continua:** ambas modalidades, reposición, prioridad manual y recuperación de errores.

Cada bloque tendrá comprobaciones automatizadas del comportamiento que introduce. La compilación integrada debe conservar las regresiones existentes, especialmente la reproducción del favorito después de reabrir. Los cambios de código y pruebas se compilan con el flujo macOS ya utilizado y se entrega un nuevo IPA con número de compilación distinguible. Las observaciones personales permanecen en la documentación privada.

### Criterios de aceptación

- El Historial existente se conserva y permite reproducir su contenido.
- Aleatorio conserva canción y progreso actuales al mezclar próximos elementos; Anterior recorre la cola conservada y el orden se recupera en pausa después de relanzar.
- Una portada tardía de A no aparece cuando ya está seleccionado B; actualizar progreso no retira la imagen de B.
- Escribir y borrar consultas rápidamente deja únicamente resultados correspondientes al texto vigente. Buscar manualmente sigue funcionando.
- Para ti obtiene candidatos de las referencias locales y Por descubrir excluye los identificadores del historial. Los resultados repetidos se combinan por identificador.
- Ambas radios continúan cuando se consume el lote inicial; añadir una canción manual la sitúa antes de las sugerencias pendientes.
- Cambiar de radio durante una solicitud impide que el lote anterior se añada después.
- Sin red, respuestas vacías o contenido automático no disponible no producen bucles ni pérdida de biblioteca.
- Los archivos de biblioteca de la compilación 5 se leen y conservan, y cerrar/reabrir mantiene la reproducción en pausa.
- En el iPhone se comprueban imagen en pantalla bloqueada y Centro de control, cambio de portada, varias transiciones automáticas con la pantalla bloqueada, Salsa y Rock, Anterior/Siguiente y la regresión de Favoritos.

Las pruebas con datos controlados verifican las reglas del programa. La compatibilidad de las recomendaciones actuales, su coherencia musical y la presentación real de iOS se verifican por separado en red y en el teléfono. Las pruebas físicas generales pendientes de la etapa anterior siguen registradas en `docs/verificacion-iphone.md`.

## 8. Fuentes revisadas

- [Apple: información de reproducción](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter): iOS presenta los metadatos y determina su formato.
- [Guía de Apple: metadatos e imagen en pantalla bloqueada y Centro de control](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/MediaPlaybackGuide/Contents/Resources/en.lproj/RefiningTheUserExperience/RefiningTheUserExperience.html).
- [YouTubeKit: relacionadas y continuaciones en la revisión fijada](https://github.com/b5i/YouTubeKit/blob/6532af39da4c1612b0a1af603792419d8fb0e67f/Sources/YouTubeKit/YouTubeResponseTypes/VideoInfos/MoreVideoInfosResponse.swift).
- [YouTubeKit: búsqueda y continuación en la revisión fijada](https://github.com/b5i/YouTubeKit/blob/6532af39da4c1612b0a1af603792419d8fb0e67f/Sources/YouTubeKit/YouTubeResponseTypes/Search/SearchResponse.swift).
- [YouTubeKit: metadatos disponibles de un video](https://github.com/b5i/YouTubeKit/blob/6532af39da4c1612b0a1af603792419d8fb0e67f/Sources/YouTubeKit/BaseStructs/YTVideo.swift).
