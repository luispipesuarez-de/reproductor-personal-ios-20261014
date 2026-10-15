# Instalar el prototipo desde Windows

Dispositivo indicado por el usuario: iPhone 13, iOS 26.2. La app requiere iOS 16 o posterior. El IPA generado no está firmado; se firma en el equipo mediante AltServer o AltStore Classic.

## Obtener el archivo

La entrega comprobada está en `build/ReproductorPersonal.ipa` dentro de la carpeta de este proyecto: versión 0.1.0, compilación 3. Su [ejecución de origen](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38676199279) contiene las 28 pruebas correctas y el mismo IPA. Puedes seleccionarlo directamente desde AltServer con la ruta USB indicada más abajo.

1. Abre [las ejecuciones privadas del proyecto](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/workflows/ios.yml) con tu cuenta de GitHub.
2. Elige la ejecución 38676199279 y descarga su artefacto ReproductorPersonal-10, o una entrega posterior comprobada que haya generado IPA.
3. Extrae el ZIP y busca ReproductorPersonal.ipa. Transfiérelo a Archivos en el iPhone, por ejemplo mediante iCloud Drive.

## Preparar AltStore Classic

1. Sigue la [guía oficial de instalación en Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows): instala las versiones de iTunes e iCloud que indica y después AltServer.
2. Conecta el iPhone desbloqueado por USB y acepta confiar en el PC. Activa la sincronización Wi-Fi en iTunes.
3. En el icono de AltServer, selecciona Install AltStore y tu iPhone. Introduce tus datos de Apple directamente allí.
4. En el iPhone, confía en el perfil desde Ajustes → General → VPN y gestión de dispositivos.
5. Activa Modo de desarrollador en Ajustes → Privacidad y seguridad y completa el reinicio solicitado.
6. Abre AltStore → My Apps → +, selecciona el IPA y espera la instalación.

Para las aplicaciones gestionadas desde AltStore → My Apps, renueva antes de siete días con Refresh All mientras AltServer está disponible. Consulta los detalles de [renovación y límites](https://faq.altstore.io/altstore-classic/your-altstore).

## Instalar o actualizar directamente por USB

Esta ruta se utilizó en el iPhone del usuario después de que el IPA no apareciera en iCloud Drive. Permite seleccionar el archivo del PC directamente.

1. Conecta el iPhone por USB, desbloquéalo y comprueba que iTunes permite abrir su pantalla Resumen.
2. En Windows, pulsa la flecha de iconos ocultos junto al reloj. Mantén pulsada Shift (Mayús) y haz clic en el rombo gris de AltServer.
3. Selecciona Sideload .ipa… y tu iPhone.
4. En la ventana Abrir, selecciona `build/ReproductorPersonal.ipa` de este proyecto.
5. Introduce la cuenta de Apple y su contraseña directamente en AltServer y pulsa Install. Mantén conectado el iPhone hasta que termine.
6. Abre Reproductor en el teléfono y repite la búsqueda y reproducción.

La [documentación oficial de AltServer](https://faq.altstore.io/release-notes/altserver) indica que las instalaciones directas requieren reinstalación manual cada siete días con una cuenta gratuita. La renovación sigue siendo gratuita. No se ha comprobado si esta instalación aparece en My Apps de AltStore; no se debe dar por hecho que Refresh All la incluye.

## Probar la reproducción local

Abre Reproductor, busca por título o artista y toca un resultado. Prueba un video y una canción; con esta última bloquea la pantalla y cambia de aplicación. Registra el resultado en [verificacion-iphone.md](verificacion-iphone.md). El Mac de GitHub compila la app; las búsquedas y la preparación del contenido se ejecutan desde el iPhone.

Si aparece «contenido no disponible», prueba otro contenido público y anota el título. La extracción depende del formato actual de YouTube; una compilación correcta no demuestra compatibilidad con todo el catálogo.
