# Cambios Compilación 11: Catálogo Oficial, Discografías Completas y Control de Reproducción Automática

## Resumen de mejoras
1. **Catálogo estructurado de YouTube Music (`gl=AR`, anónimo y sin cookies):**
   - Nuevo cliente `YouTubeMusicClient` (`WEB_REMIX`) y parser tolerante `YTMusicParser` con respaldo automático a la ruta anterior de YouTubeKit si la fuente falla o cambia.
   - Búsqueda musical con filtros («Todo», «Canciones», «Artistas», «Álbumes»), paginación («Cargar más») e insignias discretas («Oficial» / «Posible versión no oficial»).
   - Páginas de artista con discografía completa («Álbumes», «Singles y EPs», «Canciones populares» con «Ver todas» paginado) y pistas reales ordenadas por álbum (`MPREb_…`), con deduplicación de remasterizados/ediciones respetando grabaciones en vivo.

2. **Reproducción automática más fiable (Problema 1):**
   - Nuevo clasificador `TrackAuthenticity` (`verifiedCatalog`, `officialChannel`, `unknown`, `suspicious`) que excluye versiones con marcadores de IA, covers, karaokes o imitaciones de la radio, recomendaciones («Para ti», «Por descubrir») y Siri.
   - Eliminada la regla de la nota musical (`♪♫♬`) en `Video.isOfficialChannelName` y restringido `vevo` a sufijo.
   - Continuidad de artista en radio (`RecommendationSeed.artist`), ventana de 120–600 s para catálogo verificado (`ATV`/`OMV`) y respaldo a 180–600 s para el resto.
   - Siri (`PlayArtistIntent`, `PlaySongIntent`) resuelve por identidad de artista y encola una sola pista para que la radio continúe automáticamente.

3. **Control del usuario:**
   - Interruptor **«Solo grabaciones oficiales»** en los controles de radio (**activado por defecto**).
   - Opción **«No reproducir este canal»** en el menú de cada pista y sección **«Canales bloqueados»** en Biblioteca para gestionarlos.

## Fixtures y versión de cliente
- Capturadas el **2026-11-13** contra `https://music.youtube.com/youtubei/v1/*` (`clientName: WEB_REMIX`, `clientVersion: 1.20261110.01.00`, `hl: es`, `gl: AR`).

## Límites conocidos
- Ninguna señal del catálogo garantiza autenticidad absoluta: pistas distribuidas a través de sellos o agregadores también pueden contener audio generado con IA si la fuente no lo etiqueta.
- La disponibilidad de lanzamientos depende del catálogo regional configurado (`AR`).

## Verificación en CI
- Ejecución `44569132686` en `feature/catalogo-oficial`: **231 pruebas unitarias (0 fallos)** y **19 pruebas de interfaz (0 fallos)**.
