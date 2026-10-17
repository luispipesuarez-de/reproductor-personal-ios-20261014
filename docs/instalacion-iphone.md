# Instalar y usar Reproductor desde Windows

Tu iPhone 13 con iOS 26.2 cumple el requisito de iOS 16 o posterior. Entrega disponible: **0.1.0, compilación 7**, comprobada en [38997159679](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38997159679): 147 pruebas unitarias, 16 de interfaz y Release correctos. El archivo del PC ya se verificó como 7; su instalación sigue pendiente. La última lectura por USB confirmó la 5; el usuario informó de una actualización posterior, cuya lectura por USB se interrumpió al descargarse el teléfono.

## Actualizar la app que ya tienes

El archivo del PC está en:

```text
C:\Users\Olga Lucia\Documents\Codex\2026-10-14\dime-c-mo-puedo-hacer-para\build\ReproductorPersonal.ipa
```

1. Conecta el iPhone por USB y déjalo desbloqueado. Comprueba que iTunes muestra el dispositivo.
2. En Windows, pulsa la flecha de iconos ocultos junto al reloj.
3. Mantén pulsada **Shift (Mayús)** y haz clic en el rombo gris de **AltServer**.
4. Elige **Sideload .ipa… → tu iPhone**.
5. En la ventana **Abrir**, pega la ruta completa anterior en **Nombre de archivo** y pulsa **Abrir**. Usa el archivo del PC: la copia anterior de iCloud Drive no corresponde a esta entrega.
6. Introduce la misma cuenta de Apple que usaste antes y su contraseña directamente en AltServer. Pulsa **Install** y mantén conectado el teléfono hasta que termine.
7. Cuando termine, verificaremos por USB que la versión instalada es **0.1.0/7**. Abre **Reproductor**; deben aparecer las pestañas **Buscar** y **Biblioteca**.

Instala sobre la app existente para comprobar la conservación de sus datos. La actualización conserva el identificador de la app; la conservación de la biblioteca durante una actualización posterior sigue siendo una prueba física pendiente.

Si tu iPhone no aparece, vuelve a conectarlo desbloqueado y abre su pantalla Resumen en iTunes antes de repetir el menú de AltServer.

## Usar la biblioteca y la cola

- **Buscar:** escribe al menos dos caracteres de un título o artista. Los resultados aparecen mientras escribes, sin pulsar Buscar. Las canciones con duración conocida de 3–10 minutos tienen prioridad y los videos de una hora o más quedan al final. Toca uno para reproducirlo; cerrar «Ahora suena» deja el reproductor compacto disponible al navegar.
- **Cerrar la reproducción:** pausa desde el reproductor inferior y deslízalo a la izquierda o derecha. Se cierra y vacía la cola actual; favoritos, listas, historial y géneros siguen guardados. Con VoiceOver, el botón que abre el reproductor ofrece «Cerrar reproducción» cuando está en pausa. Mientras carga o reproduce, el gesto no cierra la cola.
- **Favoritos:** abre los tres puntos del resultado o de «Ahora suena» y elige «Guardar en Favoritos». Los encontrarás en Biblioteca → Favoritos; el mismo menú permite quitarlos.
- **Listas:** Biblioteca → + pide el nombre. Para guardar un video, abre sus tres puntos → Añadir a una lista → elige la lista. Dentro de ella, «Reproducir lista» sigue su orden. «Editar» permite quitar posiciones; los tres puntos de la lista permiten renombrarla o eliminarla.
- **Cola:** reproduce el primer elemento y usa los tres puntos de otros resultados → Añadir a la cola. Tus elecciones quedan antes de las sugerencias y se identifican como «Añadida por ti». En Ahora suena → Ver cola puedes elegir una entrada o usar el botón Edit para quitarla. Tocar otro resultado para reproducirlo inicia una cola nueva desde ese contenido.
- **Controles:** Ahora suena ofrece pausa/reanudación, anterior/siguiente, saltos de quince segundos y una barra de progreso cuando el flujo la admite. La app publica también los controles del sistema; su comportamiento físico se registra en la guía de verificación.
- **Historial:** Biblioteca → Historial muestra lo que empezó a reproducirse. Toca una entrada para volver a escucharla.
- **Aleatorio:** «Mezclar mi música» reúne favoritos, listas e historial. También puedes mezclar favoritos, una lista o la cola. «Mezclar cola» conserva la canción actual y su progreso, y mantiene primero tus elecciones manuales. Anterior/Siguiente recorren el orden resultante.

La biblioteca y la cola se guardan en el almacenamiento privado de la app. La escucha necesita conexión; los registros locales contienen referencias y metadatos. Al abrir de nuevo, una cola conservada se restaura en pausa y la app obtiene el flujo de YouTube al reanudar. Una cola cerrada mediante el deslizamiento permanece vacía y el reproductor no reaparece.

## Radio y recomendaciones dentro de Buscar

- **Por género:** deja vacío el campo de Buscar y toca Salsa, Rock, Pop, Bachata, Blues o Vallenato. «Otro género» permite escribir uno distinto; al pulsar Iniciar queda guardado como un botón junto a los demás, incluso tras reabrir. Los nombres equivalentes no crean duplicados. La app prepara una selección y solicita más canciones al avanzar.
- **Desde una canción:** reproduce un resultado con «Continuar automáticamente» activado para seguir con canciones relacionadas. También puedes abrir los tres puntos de un resultado → «Iniciar radio».
- **Tus elecciones primero:** añade una canción a la cola; queda antes de las sugerencias. «Ver cola» distingue «Añadida por ti» y «Sugerida».
- **Desactivar las sugerencias:** apaga «Continuar automáticamente» en Ahora suena o Ver cola. La canción actual continúa y se retiran las sugerencias futuras; tus elecciones manuales se conservan.
- **Para ti / Por descubrir:** escucha o guarda canciones y luego vacía el campo de Buscar. Desliza para ver las recomendaciones y usa «Actualizar recomendaciones» para renovarlas. «Por descubrir» omite las referencias del historial local; no significa que sean lanzamientos recientes.
- **Imagen de la canción:** la app envía la miniatura disponible a la pantalla bloqueada y al Centro de control y la cambia al seleccionar otra canción. La comprobación en el teléfono está pendiente.

La afinidad de género procede de los metadatos y sugerencias disponibles. La radio y las recomendaciones priorizan canciones de 3–10 minutos; consultan un número limitado de páginas y pueden recurrir a otros resultados si faltan canciones del rango. Hay que escuchar Salsa, Rock y Blues en el iPhone para comprobar la selección real. Las recomendaciones no requieren iniciar sesión en YouTube.

## Repetir la prueba de Favoritos después de actualizar

1. Comprueba que aparecen el favorito, la lista y la cola que ya habías guardado.
2. Pausa la reproducción y cierra Reproductor desde el selector de aplicaciones del iPhone.
3. Abre Reproductor de nuevo y entra directamente en **Biblioteca → Favoritos**, sin entrar antes en Buscar.
4. Toca **Rata Blanca - Talisman (AUDIO)**. Comprueba que comienza a sonar. Repite el cierre y la apertura una segunda vez para confirmar el resultado.

La compilación 5 corrigió la preparación del contexto anónimo al reabrir. Después de comprobar por USB esa instalación, el usuario respondió «La canción se reproduce» al probar el favorito. La regresión sigue pasando en la 7; el recorrido físico y la conservación de la biblioteca deben repetirse después de actualizar.

## Otras comprobaciones en el iPhone

1. Busca la misma canción que ya funcionó. Comprueba imagen/sonido y prueba pausa/reanudación tanto en los controles de la app como en los del video.
2. Busca otras dos canciones y, en sus tres puntos, toca «Añadir a la cola». Abre «Ahora suena» → «Ver cola» y confirma el orden de tres elementos.
3. Bloquea el teléfono y escucha quince minutos, incluyendo al menos un cambio automático de canción. Prueba también pausa/reanudación y siguiente/anterior en los controles de iOS. Anota cortes, errores o anuncios que observes.
4. Guarda un favorito y crea una lista con dos elementos. Renombra la lista y quita una entrada. Pausa, cierra la app desde el selector y ábrela: comprueba que se conservan los datos y la cola, sin empezar a sonar por sí sola.

Registra cada resultado en [verificacion-iphone.md](verificacion-iphone.md), donde están también los criterios restantes de videos, accesorios, actualización y accesibilidad. Si aparece «contenido no disponible», anota la búsqueda y el título exactos; los tests automáticos usan contenido controlado y no prueban todo el catálogo de YouTube.

## Renovar la firma gratuita

La [documentación oficial de AltServer](https://faq.altstore.io/release-notes/altserver) indica que las instalaciones directas requieren reinstalación manual cada siete días. Con una cuenta gratuita, repite la instalación con el mismo IPA y la misma cuenta antes del vencimiento. El vencimiento no obliga a pasar a una cuenta de pago.

Las apps gestionadas desde **AltStore → My Apps** pueden renovarse con **Refresh All** mientras AltServer esté disponible, según [la guía de AltStore](https://faq.altstore.io/altstore-classic/your-altstore). No se ha comprobado si esta instalación directa aparece allí; usa la ruta de AltServer que ya funcionó.

## Preparar otro equipo u obtener el artefacto

En un Windows nuevo, sigue [la instalación oficial de AltStore Classic](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows) para iTunes, iCloud y AltServer. Conecta el iPhone, acepta confiar en el equipo y activa la sincronización Wi-Fi en iTunes. El perfil de desarrollador y Modo de desarrollador ya se habilitaron en el iPhone del usuario.

Puedes descargar el ZIP **ReproductorPersonal-21** de [la ejecución 38956368533](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38956368533), extraerlo y seleccionar **ReproductorPersonal.ipa**. El IPA no está firmado: AltServer realiza la firma personal durante la instalación. La copia anterior del PC se conserva en `build/anteriores/ReproductorPersonal-compilacion-5.ipa`.
