# Reproductor personal para iPhone

App personal en SwiftUI con búsqueda interna de videos y canciones, reproducción nativa, cola, favoritos, listas y recientes. La búsqueda y la preparación del contenido se realizan desde el iPhone, sin servidor de extracción propio. No requiere pegar enlaces.

Entrega: versión 0.1.0, compilación 5. La verificación automática pasó 71 pruebas unitarias y 4 de interfaz; se generó y comprobó el IPA Release. Esta actualización prepara el contexto anónimo al reproducir un favorito después de reiniciar, sin una búsqueda manual previa. El usuario confirmó la reproducción desde Favoritos tras reabrir y los cuatro controles de iOS con pantalla bloqueada: pausa, reanudación, siguiente y anterior. También confirmó la escucha guiada de quince minutos bloqueado, sin cortes ni anuncios observados en esa muestra. Las demás comprobaciones físicas siguen abiertas.

En la compilación 4, el usuario confirmó una cola de tres canciones con avance automático y pantalla bloqueada, y conservación del favorito, lista y cola al reabrir en pausa. También encontró el fallo de reproducción en frío que motivó esta actualización. Los resultados físicos de esa versión y de la compilación 3 se conservan por separado; las demás comprobaciones siguen pendientes.

## Instalar y usar

El archivo local es `build/ReproductorPersonal.ipa`. Se firma e instala desde Windows con AltServer, sobre la app existente y con la misma cuenta de Apple. Sigue [la guía de instalación y uso](docs/instalacion-iphone.md). Después de actualizar, comprueba la biblioteca, pausa y cierra la app desde el selector; al reabrir entra directamente en Biblioteca → Favoritos y reproduce, sin pasar antes por Buscar.

La [ejecución 38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217), commit público `9850a39` (mismo código que `65d54fc` del repositorio privado), contiene el artefacto ReproductorPersonal-4. [Estado y evidencia técnica](docs/estado-implementacion.md). [Resultados y pruebas pendientes en el iPhone](docs/verificacion-iphone.md).

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
