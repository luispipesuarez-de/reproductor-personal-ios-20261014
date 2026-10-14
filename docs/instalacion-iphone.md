# Instalar el prototipo desde Windows

Dispositivo indicado por el usuario: iPhone 13, iOS 26.2. La app requiere iOS 16 o posterior. El IPA generado no está firmado; se firma en el equipo mediante AltStore Classic.

## Obtener el archivo

La entrega comprobada está en `build/ReproductorPersonal.ipa` dentro de la carpeta de este proyecto. Puedes transferir ese archivo directamente al iPhone. Su [ejecución de origen](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/runs/38638945973) contiene las 25 pruebas correctas y el mismo IPA.

1. Abre [las ejecuciones privadas del proyecto](https://github.com/luispipesuarez-de/reproductor-personal-ios-20261014/actions/workflows/ios.yml) con tu cuenta de GitHub.
2. Elige la ejecución 38638945973 y descarga su artefacto ReproductorPersonal-8, o una entrega posterior comprobada que haya generado IPA.
3. Extrae el ZIP y busca ReproductorPersonal.ipa. Transfiérelo a Archivos en el iPhone, por ejemplo mediante iCloud Drive.

## Preparar AltStore Classic

1. Sigue la [guía oficial de instalación en Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows): instala las versiones de iTunes e iCloud que indica y después AltServer.
2. Conecta el iPhone desbloqueado por USB y acepta confiar en el PC. Activa la sincronización Wi-Fi en iTunes.
3. En el icono de AltServer, selecciona Install AltStore y tu iPhone. Introduce tus datos de Apple directamente allí.
4. En el iPhone, confía en el perfil desde Ajustes → General → VPN y gestión de dispositivos.
5. Activa Modo de desarrollador en Ajustes → Privacidad y seguridad y completa el reinicio solicitado.
6. Abre AltStore → My Apps → +, selecciona el IPA y espera la instalación.

Con cuenta gratuita, renueva antes de siete días con Refresh All mientras AltServer está disponible. Consulta los detalles de [renovación y límites](https://faq.altstore.io/altstore-classic/your-altstore).

## Probar la reproducción local

Abre Reproductor, busca por título o artista y toca un resultado. Prueba un video y una canción; con esta última bloquea la pantalla y cambia de aplicación. Registra el resultado en [verificacion-iphone.md](verificacion-iphone.md). El Mac de GitHub compila la app; las búsquedas y la preparación del contenido se ejecutan desde el iPhone.

Si aparece «contenido no disponible», prueba otro contenido público y anota el título. La extracción depende del formato actual de YouTube; una compilación correcta no demuestra compatibilidad con todo el catálogo.
