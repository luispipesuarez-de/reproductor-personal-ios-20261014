# Reproductor personal para iPhone: búsqueda y biblioteca local

Fecha: 14 de octubre de 2026.

Estado: alcance de la primera etapa acordado en la conversación; especificación técnica pendiente de revisión del usuario. Todavía no hay una aplicación implementada ni pruebas de reproducción en el iPhone.

## 1. Objetivo y decisiones acordadas

Construir una aplicación propia para uso personal que permita buscar contenido de YouTube, ver videos y escuchar música en segundo plano, con el objetivo de evitar los anuncios insertados por el reproductor de YouTube.

El usuario dispone de Windows y un iPhone. Quiere encontrar y elegir contenido dentro de su aplicación. Pegar enlaces no es el flujo principal ni un requisito para escuchar música.

La primera etapa incluye búsqueda y listas locales porque es la opción más sencilla. Una segunda etapa incorporará la integración con la cuenta de YouTube, sus listas y suscripciones, después de validar su viabilidad. Las listas locales deberán conservarse al añadir esa integración.

La ejecución y los datos personales de la primera etapa estarán en el iPhone. El teléfono se comunicará directamente con YouTube y sus servidores de contenido, por lo que necesitará Internet. GitHub Actions se utilizará para compilar el proyecto, no para resolver búsquedas, extraer contenido o transmitir la reproducción.

## 2. Alcance de la primera etapa

| Función | Comportamiento esperado |
| --- | --- |
| Búsqueda | Escribir una canción, un artista, un video o el nombre de un canal; enviar la consulta y obtener videos reproducibles. |
| Resultados | Mostrar miniatura, título, autor y duración cuando los datos estén disponibles. Tocar un resultado inicia la preparación de su reproducción. |
| Video | Ver el contenido con el reproductor nativo del iPhone. |
| Escucha | Mantener el audio al cambiar de aplicación o bloquear la pantalla. |
| Controles | Reproducir, pausar, avanzar, retroceder y pasar entre elementos de la cola desde la app; integrar los comandos disponibles en la pantalla bloqueada. |
| Cola | Añadir y quitar elementos, elegir el siguiente y continuar automáticamente cuando termine el actual. |
| Favoritos | Guardar y quitar videos sin iniciar sesión. |
| Listas | Crear, renombrar y eliminar listas locales; añadir y quitar elementos y reproducir una lista en orden. |
| Recientes | Mostrar los últimos contenidos reproducidos para encontrarlos de nuevo. |

La primera etapa se limita a contenido público que pueda reproducirse sin autenticación. La navegación completa por páginas de canales, las recomendaciones personalizadas de una cuenta, las descargas sin conexión y la sincronización con Google pertenecen a trabajos posteriores.

Los patrocinios que el creador haya grabado dentro del propio video no se eliminan mediante este diseño. El objetivo sobre anuncios se refiere a las inserciones publicitarias de YouTube, y debe comprobarse con reproducción real.

## 3. Experiencia de uso

La aplicación abre en **Buscar**, con un campo de texto visible. La búsqueda se envía al pulsar Buscar en el teclado; no requiere copiar un enlace ni abrir otra aplicación.

El usuario toca una tarjeta de resultado para reproducir. La app muestra el contenido actual y permite abrir una vista de reproducción con video y controles. Un reproductor compacto permanece disponible al volver a Buscar o visitar Biblioteca.

En **Biblioteca** se encuentran Favoritos, Listas y Recientes. Los resultados y el contenido actual ofrecen acciones para guardar en Favoritos, añadir a una lista o añadir a la cola. La creación de una lista pide únicamente su nombre.

Al bloquear el teléfono, la reproducción continúa como audio. La app publica el título, el autor y los controles de reproducción compatibles en el sistema. Volver a abrirla recupera la vista del contenido que sigue sonando.

Cuando el contenido está cargando, se muestra un estado breve y se impide iniciar varias preparaciones iguales. Un resultado que no se pueda reproducir debe comunicarlo sin aparentar que ha comenzado a sonar.

La interfaz inicial utilizará componentes de SwiftUI, texto en español, compatibilidad con tamaños de letra del sistema y etiquetas accesibles para los controles. La estética detallada se ajustará cuando la reproducción esté validada.

## 4. Arquitectura mínima

Aplicación nativa con **SwiftUI**, **AVFoundation** y **MediaPlayer**, con iOS 16 como versión mínima de la primera implementación. La versión del iPhone se comprobará antes de la instalación; este requisito puede revisarse si el dispositivo necesita una versión anterior.

La aplicación tendrá tres responsabilidades principales:

1. **Acceso a YouTube.** Realiza búsquedas por texto, transforma sus resultados en datos de la app y obtiene un flujo que pueda reproducir AVPlayer. Las particularidades de YouTube permanecen en este módulo.
2. **Reproducción.** Mantiene un único reproductor, la cola, el elemento actual, el progreso y los comandos del sistema. Su vida útil no depende de que la pantalla de reproducción esté abierta.
3. **Biblioteca local.** Guarda favoritos, listas y recientes de forma persistente y atiende las operaciones solicitadas por las pantallas.

Las pantallas consumen estas responsabilidades directamente. La primera etapa no necesita un servidor propio, una base de datos remota, un sistema de cuentas de la app ni una arquitectura de proveedores genéricos.

### 4.1. Búsqueda y extracción

La integración inicial utilizará **b5i/YouTubeKit** como biblioteca candidata, porque ofrece búsqueda y datos de reproducción en Swift. La implementación fijará una revisión concreta del paquete; las actualizaciones posteriores serán explícitas y requerirán repetir la prueba de reproducción.

El módulo de acceso devolverá identificadores de video y metadatos propios de la app. Resolverá el flujo en el iPhone cuando se vaya a reproducir un elemento. Preferirá una URL HLS reproducible con AVPlayer; también podrá utilizar una URL directa compatible que contenga las pistas necesarias. Si la biblioteca no proporciona un flujo nativo válido, devolverá un error de contenido no disponible.

No se interpretará una dirección de la página web de YouTube como si fuera un archivo de audio o video. Tampoco se activará un servicio remoto de extracción como sustituto de la resolución local.

Esta biblioteca utiliza una integración no oficial. Su documentación y sus incidencias sirven para elegir un punto de partida, pero no demuestran que la extracción funcione hoy con todos los contenidos o en el iPhone del usuario. Esa comprobación es el primer hito funcional del proyecto.

La API oficial de YouTube impone restricciones sobre el bloqueo de anuncios y la reproducción en segundo plano; este proyecto no se presentará como una integración oficial aprobada por YouTube.

### 4.2. Reproducción y segundo plano

La reproducción usará un único AVQueuePlayer, compatible con los controles de AVPlayer. El componente de reproducción mantiene la cola de identificadores y prepara el siguiente flujo antes de que termine el elemento actual, cuando sea posible. La sesión de audio se configurará para reproducción y el proyecto declarará el modo de audio en segundo plano.

El modo de escucha inicial conserva la reproducción al ocultar la interfaz o bloquear el teléfono. No promete reducir el consumo de datos a un flujo exclusivamente de audio: esa optimización depende de los formatos que entregue la integración y se evaluará después.

MediaPlayer publicará la información del contenido actual y atenderá los comandos aplicables de la pantalla bloqueada. El cambio automático al siguiente elemento debe resolverse desde el componente de reproducción, sin depender de una pantalla visible.

La app pausa al desconectar auriculares. Una interrupción del sistema pausa o suspende la reproducción según la sesión de audio; la reanudación respeta la indicación del sistema y la intención del usuario. Forzar el cierre de la app termina su reproducción.

### 4.3. Persistencia

La biblioteca se almacenará mediante archivos JSON con Codable en el directorio privado de datos de la app. Las escrituras serán atómicas y se ejecutarán de forma ordenada.

Los registros guardan identificador de video, título, autor, miniatura y duración si está disponible. Cada lista tiene un identificador local y un orden explícito de elementos. Los favoritos no duplican un mismo identificador de video. El archivo de biblioteca incluye también el orden de la cola, la referencia del elemento actual y su último progreso guardado.

La biblioteca guarda referencias y metadatos, no archivos descargados de YouTube ni URLs temporales de reproducción. Al abrir un elemento guardado se vuelve a resolver su flujo. Se registrará una versión del formato de datos para permitir cambios posteriores sin perder las listas.

Cerrar y volver a abrir la app conserva la biblioteca y la cola guardada, pero no inicia audio automáticamente. El usuario decide cuándo reanudar.

## 5. Errores y límites de la integración

| Situación | Respuesta de la app |
| --- | --- |
| No hay conexión | Explicar que se necesita Internet y ofrecer Reintentar; mantener accesible la biblioteca local. |
| La búsqueda no tiene resultados | Mostrar un estado vacío con la consulta enviada. |
| Se envía otra búsqueda | Ignorar resultados tardíos de la consulta anterior para que no sustituyan los nuevos. |
| El video fue eliminado, restringido o requiere cuenta | Informar que no está disponible en esta versión; conservar su referencia en la lista. |
| La extracción falla | Mostrar un error comprensible y permitir reintentar. No sustituirla por un servidor externo. |
| Una URL temporal caduca | Volver a resolverla una vez y recuperar el progreso cuando sea posible; evitar reintentos ilimitados. |
| Falla un elemento de la cola | Mostrar el fallo y pausar. El usuario decide reintentar o pasar al siguiente. |
| Falla el guardado local | Informar del fallo y conservar los datos previamente guardados; evitar anunciar que una operación se guardó si no ocurrió. |

## 6. Desarrollo, compilación e instalación

El código y la documentación se editarán desde Windows. Un flujo manual de GitHub Actions con un ejecutor macOS utilizará Xcode para compilar y generar un archivo IPA sin firmar para la instalación personal.

El repositorio remoto y su primera ejecución se prepararán después de revisar el plan de implementación. Las credenciales de Apple y los datos de la cuenta de YouTube no forman parte del repositorio ni de la compilación en GitHub.

El usuario instalará **AltServer en Windows y AltStore Classic en el iPhone**, siguiendo su documentación oficial. El archivo IPA se firmará e instalará con la cuenta personal de Apple a través de ese proceso. En iOS 16 o posterior será necesario habilitar el modo de desarrollador.

Con una cuenta gratuita de Apple, la instalación requiere renovación cada siete días y hay un límite de aplicaciones instaladas mediante este mecanismo. AltServer participa en esa renovación; Windows no necesita permanecer encendido para escuchar el contenido una vez instalada la app.

Se documentarán tanto la instalación inicial como la actualización del archivo IPA y la renovación de su firma. La disponibilidad y las cuotas de compilación dependen de la cuenta de GitHub usada.

## 7. Hitos y verificación

### Hito 1: comprobar el camino técnico

Antes de completar la interfaz, obtener una compilación instalable y verificar en el iPhone:

- Una búsqueda por texto devuelve resultados seleccionables.
- Tocar un resultado resuelve localmente un video público y lo reproduce con video y audio.
- Una canción pública se reproduce y continúa al bloquear la pantalla.
- La app funciona sin un servidor remoto de extracción.

Si este hito falla, se investiga y corrige la integración local antes de ampliar la biblioteca y las pantallas. Si no se puede obtener reproducción local estable, se presenta el fallo y sus alternativas al usuario para revisar el diseño. No se cambia silenciosamente el requisito de ejecución local.

### Hito 2: comprobar el uso cotidiano

En el iPhone real, probar tres canciones y dos videos públicos, uno de estos últimos de al menos quince minutos. La selección se realiza desde el buscador de la app.

- Mantener una escucha de al menos quince minutos con la pantalla bloqueada y otra prueba cambiando entre aplicaciones.
- Verificar que una cola de tres elementos pasa al siguiente con el teléfono bloqueado.
- Probar pausa, reanudación, siguiente y anterior desde los controles del sistema, cuando estén disponibles.
- Probar desconexión de auriculares y una interrupción de audio.
- Registrar si se observan anuncios insertados durante las pruebas; ese resultado no se extrapola a todo el catálogo ni a futuras versiones de YouTube.

### Hito 3: comprobar biblioteca e instalación

- Crear una lista, añadir y quitar elementos, renombrarla y reproducirla.
- Guardar y quitar favoritos; comprobar que no se duplican.
- Cerrar y abrir la app para verificar persistencia de listas, favoritos, recientes y referencias de la cola.
- Comprobar búsqueda sin resultados, contenido no disponible y pérdida de conexión.
- Instalar una actualización sin perder la biblioteca y documentar la renovación de la firma.

Las pruebas automatizadas se centrarán en selección de resultados vigentes, transformación de datos, avance de cola, persistencia y manejo de errores. Las pruebas de datos controlados no sustituyen la reproducción real ni prueban por sí solas que YouTube siga siendo compatible.

La primera etapa solo se considerará funcional cuando se hayan documentado estas comprobaciones, incluida la reproducción real en el iPhone. Compilar correctamente o mostrar resultados de búsqueda no basta para afirmar que se cumplió el objetivo.

## 8. Segunda etapa: cuenta de YouTube

Después de validar la primera etapa, el siguiente trabajo previsto es consultar las listas y suscripciones de la cuenta del usuario desde la app.

Antes de implementarlo se revisarán el mecanismo de autenticación disponible, las restricciones de acceso y su compatibilidad con la reproducción. La experiencia de conexión debe dejar al usuario iniciar sesión directamente y almacenar cualquier sesión en el dispositivo; no se solicitará la contraseña en el chat ni se incorporará al proyecto.

Los identificadores de video compartidos entre la biblioteca local y los datos de la cuenta permiten reproducir contenido con el mismo componente. La biblioteca local sigue siendo independiente. Esta fase no exige implementar ahora pantallas de acceso, almacenamiento de sesiones ni sincronización anticipada.

Las primeras operaciones de la integración con la cuenta serán de consulta. La edición de listas de YouTube y la sincronización de cambios requieren una decisión de alcance propia cuando se llegue a esa etapa.

## 9. Fuentes técnicas consultadas

- [YouTubeKit: búsqueda, solicitudes y datos de videos](https://github.com/b5i/YouTubeKit).
- [Datos de reproducción y URLs temporales en YouTubeKit](https://github.com/b5i/YouTubeKit/blob/main/Sources/YouTubeKit/YouTubeResponseTypes/VideoInfos/VideoInfosResponse.swift).
- [Incidencia reportada sobre extracción del reproductor](https://github.com/b5i/YouTubeKit/issues/57).
- [Apple: AVAudioSession y configuración de reproducción](https://developer.apple.com/documentation/avfaudio/avaudiosession).
- [Apple: modos de ejecución en segundo plano](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes).
- [GitHub: ejecutores alojados y selección de macOS](https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/use-github-hosted-runners).
- [AltStore Classic: instalación desde Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).
- [AltStore Classic: renovación de aplicaciones y límites](https://faq.altstore.io/altstore-classic/your-altstore).
- [YouTube: políticas de sus servicios de API](https://developers.google.com/youtube/terms/developer-policies).
