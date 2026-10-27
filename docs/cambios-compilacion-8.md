# Preferencias locales y Siri — compilación 8

## Alcance

- **Me gusta** y **No me gusta** se pueden cambiar desde el menú de cada vídeo y desde Ahora suena. Son estados excluyentes y se guardan en la biblioteca local; no cambian Favoritos, listas ni Historial.
- Los Me gusta pasan a ser las primeras semillas de **Para ti**. Los No me gusta se excluyen estrictamente de Para ti, Por descubrir y cada lote de radio, incluso si ya estaban en el búfer de radio.
- Siri dispone de atajos para **Reproducir favoritos**, **Pausar o reanudar música** y **Reproducir mi música**. Funcionan con el contenido local de la app y abren Reproductor para ejecutar la acción.
- `project.yml` declara `CURRENT_PROJECT_VERSION: 8`; la versión mínima sigue siendo iOS 16 y no se añaden dependencias.

## Compatibilidad

Las bibliotecas de compilaciones anteriores no contienen los nuevos campos y se cargan con listas vacías de preferencias. Un vídeo manualmente seleccionado sigue siendo reproducible aunque figure como No me gusta: la exclusión sólo aplica a selecciones automáticas.

## Verificación completada

- **Ejecución en GitHub Actions:** [40588645019](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/40588645019)
- **Resultado:** 100% de pruebas unitarias y de interfaz superadas, cero fallos, empaquetado Release generado exitosamente.
- **Artefacto:** `ReproductorPersonal.ipa` (2.091.158 bytes)
- **SHA-256:** `2485118599b0030a8a25a30872d863a5f72d24675029c9da3237236f5cd277cd`
- **Versión:** 0.1.0 / Compilación 8 (`personal.reproductor.ios`, arm64 Mach-O, iOS 16.0+)

En el iPhone, comprobar que los atajos aparecen tras abrir la app, que reproducen la colección esperada, que pausan/reanudan el elemento actual y que un No me gusta no vuelve a aparecer al actualizar recomendaciones o iniciar radio.
