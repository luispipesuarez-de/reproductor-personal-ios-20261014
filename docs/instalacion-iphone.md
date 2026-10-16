# Instalar y usar Reproductor desde Windows

Dispositivo del usuario: iPhone 13 con iOS 26.2. La app requiere iOS 16 o posterior. Entrega: versión 0.1.0, compilación 5, comprobada en [38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217): 71 pruebas unitarias, 4 de interfaz y compilación Release correctas. La nueva lectura por USB confirmó que esta versión 0.1.0/5 ya está instalada. La prueba física de Favoritos tras cerrar/reabrir está pendiente. Un intento anterior de actualizar había fallado con HTTP 503, y la lectura de ese momento todavía mostraba la compilación 4.

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
7. Abre **Reproductor** en el iPhone. Deben aparecer las pestañas **Buscar** y **Biblioteca**.

Instala sobre la app existente para comprobar la conservación de sus datos. La actualización conserva el identificador de la app; la conservación de la biblioteca durante una actualización posterior sigue siendo una prueba física pendiente.

Si tu iPhone no aparece, vuelve a conectarlo desbloqueado y abre su pantalla Resumen en iTunes antes de repetir el menú de AltServer.

## Usar la biblioteca y la cola

- **Buscar:** escribe un título o artista y toca un resultado. Cerrar «Ahora suena» deja el reproductor compacto disponible al navegar.
- **Favoritos:** abre los tres puntos del resultado o de «Ahora suena» y elige «Guardar en Favoritos». Los encontrarás en Biblioteca → Favoritos; el mismo menú permite quitarlos.
- **Listas:** Biblioteca → + pide el nombre. Para guardar un video, abre sus tres puntos → Añadir a una lista → elige la lista. Dentro de ella, «Reproducir lista» sigue su orden. «Editar» permite quitar posiciones; los tres puntos de la lista permiten renombrarla o eliminarla.
- **Cola:** reproduce el primer elemento y usa los tres puntos de otros resultados → Añadir a la cola. En Ahora suena → Ver cola puedes elegir una entrada o usar Editar para quitarla. Tocar otro resultado para reproducirlo inicia una cola nueva con ese contenido.
- **Controles:** Ahora suena ofrece pausa/reanudación, anterior/siguiente, saltos de quince segundos y una barra de progreso cuando el flujo la admite. La app publica también los controles del sistema; su comportamiento físico se registra en la guía de verificación.
- **Recientes:** Biblioteca → Recientes se actualiza cuando el reproductor confirma que empezó a reproducirse el contenido.

La biblioteca y la cola se guardan en el almacenamiento privado de la app. La escucha necesita conexión; los registros locales contienen referencias y metadatos. Al abrir de nuevo, la cola se restaura en pausa y la app obtiene el flujo de YouTube al reanudar.

## Repetir la prueba de Favoritos después de actualizar

1. Comprueba que aparecen el favorito, la lista y la cola que ya habías guardado.
2. Pausa la reproducción y cierra Reproductor desde el selector de aplicaciones del iPhone.
3. Abre Reproductor de nuevo y entra directamente en **Biblioteca → Favoritos**, sin entrar antes en Buscar.
4. Toca **Rata Blanca - Talisman (AUDIO)**. Comprueba que comienza a sonar. Repite el cierre y la apertura una segunda vez para confirmar el resultado.

Esta actualización prepara el contexto anónimo necesario para reproducir un elemento guardado desde el inicio. La regresión automática pasó. La confirmación física anterior fue corregida después por el usuario y la lectura por USB confirmó que todavía tenía la compilación 4. Ahora que la nueva lectura acredita la instalación de la 5, este recorrido está pendiente de repetirse. Anota si la biblioteca se conservó durante la instalación y si el favorito reproduce después de reiniciar.

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

Puedes descargar el ZIP **ReproductorPersonal-4** de [la ejecución 38813838217](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38813838217), extraerlo y seleccionar **ReproductorPersonal.ipa**. El IPA no está firmado: AltServer realiza la firma personal durante la instalación.
