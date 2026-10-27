# Preferencias locales y Siri — compilación 8

## Alcance

- **Me gusta** y **No me gusta** se pueden cambiar desde el menú de cada vídeo y desde Ahora suena. Son estados excluyentes y se guardan en la biblioteca local; no cambian Favoritos, listas ni Historial.
- Los Me gusta pasan a ser las primeras semillas de **Para ti**. Los No me gusta se excluyen estrictamente de Para ti, Por descubrir y cada lote de radio, incluso si ya estaban en el búfer de radio.
- Siri dispone de atajos para **Reproducir favoritos**, **Pausar o reanudar música** y **Reproducir mi música**. Funcionan con el contenido local de la app y abren Reproductor para ejecutar la acción.
- `project.yml` declara `CURRENT_PROJECT_VERSION: 8`; la versión mínima sigue siendo iOS 16 y no se añaden dependencias.

## Compatibilidad

Las bibliotecas de compilaciones anteriores no contienen los nuevos campos y se cargan con listas vacías de preferencias. Un vídeo manualmente seleccionado sigue siendo reproducible aunque figure como No me gusta: la exclusión sólo aplica a selecciones automáticas.

## Verificación pendiente

Esta documentación no acredita una compilación ni instalación. En macOS se debe ejecutar:

```bash
bash scripts/ci.sh test
bash scripts/ci.sh ipa
```

En el iPhone, comprobar que los atajos aparecen tras abrir la app, que reproducen la colección esperada, que pausan/reanudan el elemento actual y que un No me gusta no vuelve a aparecer al actualizar recomendaciones o iniciar radio.
