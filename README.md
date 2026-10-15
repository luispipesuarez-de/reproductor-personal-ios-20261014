# Reproductor personal para iPhone

Proyecto personal en SwiftUI, desarrollado desde Windows y compilado con Xcode en GitHub Actions. La primera entrega prepara búsqueda interna de contenido público y reproducción mediante AVQueuePlayer, con audio en segundo plano. La resolución se realiza desde el iPhone, sin servidor de extracción propio.

Última entrega comprobada: prototipo 0.1.0, compilación 3, con 28 pruebas automatizadas correctas y un IPA Release comprobado. El usuario confirmó reproducción en su iPhone 13, continuidad al salir y bloquear la pantalla y ausencia de anuncios en la muestra probada. La actualización añade una ruta HLS para la respuesta SABR que fallaba en la compilación 2. La cuenta de YouTube pertenece a una etapa posterior.

La ampliación con cola, controles, favoritos, listas y recientes está escrita, pero aún no tiene un IPA comprobado. En `9ef14b3` pasan 69 pruebas unitarias y 3 de las 4 pruebas de interfaz; queda el recorrido para añadir a una lista. El cambio posterior `b6eb12f` usa una hoja de opciones nativa para ese recorrido. [Su ejecución](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38749396947) no llegó a iniciarse por el bloqueo de facturación/cuota de GitHub. `build/ReproductorPersonal.ipa` sigue siendo la compilación 3.

## Código y compilación

Dependencia: [b5i/YouTubeKit](https://github.com/b5i/YouTubeKit), fijada a la revisión `6532af39da4c1612b0a1af603792419d8fb0e67f`. XcodeGen genera el proyecto a partir de `project.yml`.

En macOS con Xcode y XcodeGen:

```bash
bash scripts/ci.sh test
bash scripts/ci.sh ipa
```

Desde Windows, abre [el workflow privado](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/workflows/ios.yml), elige la rama `feat/reproductor-ios` y activa la opción para generar IPA. Los tests no consultan YouTube: prueban datos controlados y reproducción nativa de un WAV local. El IPA usa el proveedor real.

La compilación genera un IPA sin firmar. Sigue [la guía de instalación](docs/instalacion-iphone.md) para firmarlo con AltStore Classic en tu equipo.

Entrega comprobada: [ejecución 38676199279](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279), commit `586a761`. Archivo local: `build/ReproductorPersonal.ipa`, compilación 3. [Estado y decisiones de implementación](docs/estado-implementacion.md).

## Alcance y comprobación

La app prepara HLS o formatos MP4 combinados compatibles cuando YouTube los ofrece. Si la petición inicial solo devuelve SABR, solicita HLS mediante el perfil nativo VISIONOS con un identificador anónimo obtenido en la búsqueda o la página del video. Todas las peticiones se realizan en el dispositivo. Los datos SABR y las pistas de audio/video separadas no se entregan a AVPlayer como si fueran reproducibles. El contenido restringido o incompatible muestra un error; no se añade una extracción remota.

La compatibilidad actual con YouTube y el audio con pantalla bloqueada requieren comprobación física. [verificacion-iphone.md](docs/verificacion-iphone.md) distingue los resultados observados de las pruebas pendientes. No se garantiza compatibilidad con todos los videos ni la ausencia de anuncios incluidos por el creador dentro de su propio contenido.

El diseño y el plan aprobados están en `docs/superpowers/`. La app requiere iOS 16 o posterior; el dispositivo informado es un iPhone 13 con iOS 26.2.
