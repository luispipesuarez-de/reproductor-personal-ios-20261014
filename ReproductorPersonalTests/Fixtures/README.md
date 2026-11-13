# Fixtures de YouTube Music (`ytm-*.json`)

Capturadas el 2026-11-13 con `scripts/capture-ytm-fixtures.ps1` contra `https://music.youtube.com/youtubei/v1/*` (cliente `WEB_REMIX`, `clientVersion` `1.20261110.01.00`, `hl=es`, `gl=AR`), anónimas y sin cookies. Artista de ejemplo: Juan Luis Guerra. Se recortaron listas largas, menús, textos de accesibilidad y `responseContext` con `build`-tooling propio (ver `scripts/`). Se conserva la estructura que lee `YTMusicParser`.

| Archivo | Endpoint | Contenido |
|---|---|---|
| `ytm-search-all.json` | `search` | Búsqueda sin filtro: canciones (ATV), videos y chips de filtro |
| `ytm-search-songs.json` | `search` + `params` de «Canciones» | Canciones con artista, álbum, duración y `musicVideoType` |
| `ytm-search-albums.json` | `search` + `params` de «Álbumes» | Álbumes (`MPREb_…`) con tipo, artista y año |
| `ytm-search-artists.json` | `search` + `params` de «Artistas» | Artistas (`UC…`) |
| `ytm-artist.json` | `browse` de `UC…` | Página del artista: canciones, carruseles, cabecera |
| `ytm-artist-albums.json` | `browse` `MPAD…` + params | Lista completa de álbumes |
| `ytm-artist-singles.json` | `browse` `MPAD…` + params | Lista completa de sencillos y EP |
| `ytm-artist-songs.json` | `browse` `VLOLAK5uy_…` | Lista «Canciones más escuchadas» con continuación |
| `ytm-artist-songs-continuation.json` | `browse` continuation | Siguiente página |
| `ytm-album.json` | `browse` de `MPREb_…` | Pistas de un álbum |
| `ytm-radio.json` | `next` `RDAMVM{videoId}` | Radio de una canción |
| `ytm-radio-continuation.json` | `next` continuation | Siguiente página de la radio |

## Hallazgos de la captura

- Los tipos de pista presentes son `MUSIC_VIDEO_TYPE_ATV` (catálogo), `MUSIC_VIDEO_TYPE_OMV` (videoclip oficial) y `MUSIC_VIDEO_TYPE_PODCAST_EPISODE`.
- **No hay ninguna etiqueta de IA** en las respuestas anónimas. La clasificación de autenticidad se apoya en tipo de pista e IDs de artista.
- Los resultados de búsqueda de canciones tienen el título en `flexColumns[0]`, artistas, álbum y duración en `flexColumns[1]`, y el `videoId` en `playlistItemData`.

Para regenerar: `powershell -File scripts/capture-ytm-fixtures.ps1` y recortar con el script de `scripts/`.
