# Reproductor personal para iPhone

App personal en SwiftUI con búsqueda interna de videos y canciones, reproducción nativa, radio continua, recomendaciones, cola y biblioteca local. La búsqueda y la preparación del contenido se realizan desde el iPhone, sin servidor de extracción propio. No requiere pegar enlaces.

Entrega disponible: **0.1.0, compilación 7**, verificada el 16 de octubre de 2026: **147 pruebas unitarias, 16 de interfaz y Release correctos**. El IPA local ya es la 7 y está preparado para firma personal. Su instalación y las pruebas físicas están pendientes; la última versión confirmada por USB es la 5 y el usuario informó después de otra actualización sin completar su lectura por USB.

Esta actualización prioriza canciones de 3–10 minutos en Buscar, recomendaciones y radio; sustituye Merengue por Blues y conserva los géneros añadidos. Deslizar el reproductor inferior en pausa a cualquier lado cierra la reproducción y vacía la cola, conservando favoritos, listas e historial. [Cambios, evidencia y pruebas físicas de la 7](docs/cambios-compilacion-7.md).

La actualización integra historial, imagen en los controles del sistema, mezcla de música, resultados al escribir, «Para ti», «Por descubrir» y radio tanto desde una canción como desde un género. Las recomendaciones están dentro de Buscar. Las elecciones manuales van antes de las sugerencias; se puede desactivar la continuación automática.

En la 5 verificada, el usuario confirmó que «Rata Blanca - Talisman (AUDIO)» reproduce desde Favoritos después de cerrar/reabrir sin pasar por Buscar. Ese resultado y las observaciones de versiones anteriores se conservan por separado en la guía de verificación y deben repetirse al instalar la 7.

## Instalar y usar

El archivo local es `build/ReproductorPersonal.ipa`. Se firma e instala desde Windows con AltServer, sobre la app existente y con la misma cuenta de Apple. Sigue [la guía de instalación y uso](docs/instalacion-iphone.md). Después de actualizar, comprueba la biblioteca, pausa y cierra la app desde el selector; al reabrir entra directamente en Biblioteca → Favoritos y reproduce, sin pasar antes por Buscar.

La [ejecución 38997159679](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38997159679), commit público `5de4cd3` (mismos 64 archivos de compilación que `93e9410` del repositorio privado), contiene el artefacto **ReproductorPersonal-27**. El ZIP y el IPA local se verificaron antes de sustituir la copia de instalación; se conserva el IPA 6 anterior. [Estado y evidencia técnica](docs/estado-implementacion.md). [Resultados y pruebas pendientes en el iPhone](docs/verificacion-iphone.md).

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

Esta etapa conserva listas locales en el almacenamiento privado de la app. La escucha necesita conexión; la integración con la cuenta de YouTube pertenece a una etapa posterior. El diseño y el plan aprobados están en `docs/superpowers/`. Requiere iOS 16 o posterior; el dispositivo del usuario es un iPhone 13 con iOS 26.2.
