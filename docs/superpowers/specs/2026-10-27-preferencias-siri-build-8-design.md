# Preferencias locales y Siri — diseño de compilación 8

## Intención

Añadir señales locales de gusto sin alterar Favoritos: «Me gusta» guía las recomendaciones y «No me gusta» impide que un vídeo vuelva a proponerse automáticamente. Añadir atajos de Siri para reproducir Favoritos, pausar o reanudar, y reproducir la música local. La app mantiene iOS 16 como mínimo y no añade dependencias ni servicios externos.

## Decisiones

- La biblioteca persiste `liked` y `disliked` como vídeos, con valores por defecto al leer bibliotecas de compilaciones anteriores. Una valoración es mutuamente excluyente: marcar No me gusta elimina el like y viceversa. Favoritos conserva su significado y no cambia.
- Discovery usa primero los likes como semillas, después Favoritos e Historial, y elimina los IDs marcados No me gusta antes de formar resultados. Radio recibe esos IDs como exclusiones de cada lote y los elimina tanto del búfer como de cada página nueva.
- Player y el menú contextual ofrecen las dos acciones con estado reversible. No se crea una pantalla de colección adicional.
- Los App Intents delegan en un servicio de reproducción del proceso de la app, registrado al iniciarla. El servicio es testeable sin Siri y devuelve un error localizado si no hay contenido que reproducir.
- La entrega sube `CURRENT_PROJECT_VERSION` de 7 a 8. La documentación describe alcance y verificaciones pendientes de dispositivo físico, sin afirmar una instalación o compilación que aún no se haya ejecutado.

## Límites

- No se sincronizan preferencias con YouTube.
- No se borra un favorito ni historial al marcar una valoración.
- Las exclusiones no bloquean una reproducción manual del vídeo: sólo afectan Discovery y Radio.
