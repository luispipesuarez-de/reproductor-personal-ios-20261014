# Reproductor personal para iPhone

App personal en SwiftUI con búsqueda interna de videos y canciones, reproducción nativa, cola, favoritos, listas y recientes. La búsqueda y la preparación del contenido se realizan desde el iPhone, sin servidor de extracción propio. No requiere pegar enlaces.

Entrega: versión 0.1.0, compilación 4. La verificación automática pasó 69 pruebas unitarias y 4 de interfaz; se generó y comprobó el IPA Release. El usuario confirmó que una cola de tres canciones avanza con la pantalla bloqueada en esta versión. Siguen pendientes controles, biblioteca y escucha prolongada medida. La compilación 3 había reproducido contenido sin anuncios observados en su muestra; ese resultado no se extrapola a toda la nueva entrega.

## Instalar y usar

El archivo local es `build/ReproductorPersonal.ipa`. Se firma e instala desde Windows con AltServer. Sigue [la guía de instalación y uso](docs/instalacion-iphone.md) para actualizar la app existente y empezar con favoritos, listas y cola. La biblioteca se guarda en el almacenamiento privado de la app; la escucha necesita conexión.

La [ejecución 38753161729](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38753161729), commit público `a16da8f` (mismo código que `0b391ba` del repositorio privado), contiene el artefacto ReproductorPersonal-2. [Estado y evidencia técnica](docs/estado-implementacion.md). [Resultados y pruebas pendientes en el iPhone](docs/verificacion-iphone.md).

## Código y compilación

Desarrollado desde Windows y compilado con Xcode en GitHub Actions. Dependencia: [b5i/YouTubeKit](https://github.com/b5i/YouTubeKit), fijada a `6532af39da4c1612b0a1af603792419d8fb0e67f`. XcodeGen genera el proyecto desde `project.yml`.

En macOS con Xcode y XcodeGen:

```bash
bash scripts/ci.sh test
bash scripts/ci.sh ipa
```

Desde Windows, abre [el workflow de compilación](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/workflows/ios.yml), elige `codex/public-build` y activa la opción para generar IPA. Los tests utilizan respuestas controladas y un WAV local; Release usa el proveedor real y excluye el modo de pruebas de interfaz.

## Alcance

La app usa HLS o MP4 combinado compatible. Cuando la respuesta inicial solo ofrece SABR, solicita HLS con un perfil nativo y un identificador anónimo de visitante. El contenido restringido o incompatible muestra un error. No se garantiza compatibilidad con todo el catálogo ni se eliminan anuncios que el creador haya incluido dentro del propio video.

Esta etapa conserva listas locales. La integración con la cuenta de YouTube pertenece a una etapa posterior. El diseño y el plan aprobados están en `docs/superpowers/`. Requiere iOS 16 o posterior; el dispositivo del usuario es un iPhone 13 con iOS 26.2.
