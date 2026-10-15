# Reproductor personal para iPhone

Proyecto personal en SwiftUI, desarrollado desde Windows y compilado con Xcode en GitHub Actions. La primera entrega prepara búsqueda interna de contenido público y reproducción mediante AVQueuePlayer, con audio en segundo plano. La resolución se realiza desde el iPhone, sin servidor de extracción propio.

Estado actual: prototipo 0.1.0, compilación 3, con 28 pruebas automatizadas correctas y un IPA Release comprobado. La primera prueba del iPhone detectó un fallo de reproducción en la compilación 2; esta actualización añade una ruta HLS para la respuesta SABR observada. Falta instalar y probar la actualización en el teléfono. La biblioteca, la cola y la integración con la cuenta de YouTube están sujetas a los hitos de la especificación; no son funciones disponibles todavía.

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
