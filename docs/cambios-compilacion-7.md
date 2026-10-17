# Canciones, géneros y cierre de reproducción — compilación 7

## Alcance solicitado

- Mostrar primero canciones de 3 a 10 minutos, incluidos ambos extremos, en Buscar, Para ti, Por descubrir y radio. Buscar y radio mantienen la relevancia del proveedor dentro de cada grupo; las recomendaciones conservan su criterio previo de variedad de autores dentro de esos grupos. Los videos de una hora o más quedan al final. Las duraciones desconocidas o inválidas no se consideran canciones cortas, pero siguen disponibles. La selección manual y el orden de las listas guardadas no se alteran.
- Sustituir Merengue por Blues en los géneros iniciales. «Otro género» guarda un botón reutilizable, incluso tras cerrar y abrir la app. Los espacios se normalizan y las diferencias de mayúsculas o tildes no crean duplicados.
- Con el reproductor inferior en pausa, deslizar hacia la izquierda o derecha cierra la reproducción y vacía su cola. Esta fue la opción elegida explícitamente por el usuario. Se conservan favoritos, listas, historial y géneros; la cola vacía se guarda. Mientras carga o reproduce, el deslizamiento no la cierra.

Son cambios sobre recorridos existentes, con diseño y plan breves en la conversación. Se usan las herramientas nativas y la persistencia local existentes, sin dependencias nuevas ni servidor.

## Uso

1. Busca un título o artista: las canciones con duración conocida de 3–10 minutos aparecen antes de los demás resultados.
2. En Buscar, deja vacío el campo y toca **Blues**. Para añadir un género, toca **Otro género**, escribe el nombre y pulsa **Iniciar**. El género queda disponible junto a los botones iniciales.
3. Pausa una canción y cierra la vista «Ahora suena» para volver a la app. Desliza el reproductor inferior a cualquier lado para terminar esa cola. Con VoiceOver, el botón que abre el reproductor ofrece la acción **Cerrar reproducción** cuando está en pausa.
4. Para volver a escuchar, toca cualquier resultado, favorito o lista. Se inicia una cola nueva.

La radio consulta hasta tres páginas por lote antes de recurrir a otros resultados si faltan canciones del rango preferido. Conserva candidatos y continuación para los lotes posteriores; un fallo al consultar una página adicional no elimina candidatos ya disponibles. La clasificación depende de las duraciones recibidas y no analiza el audio ni garantiza la afinidad musical de los resultados.

## Verificación automática

La ejecución inicial [38991245072](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38991245072), anterior a la implementación, reprodujo las carencias: siete casos de selección por duración y uno de persistencia de géneros fallaron; también fallaron los recorridos de Blues, Jazz tras reabrir y deslizamiento en pausa. El error `offline` durante el caso de página adicional expuso la pérdida de candidatos de reserva. Los casos de la entrega anterior pasaron y el deslizamiento durante reproducción mantuvo los controles.

La primera ejecución integrada [38992867173](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38992867173) pasó **147 unitarias y 15 de las 16 pruebas de interfaz**. No generó IPA: falló el recorrido de deslizamiento en pausa. La evidencia de video y el registro mostraron que el test había intentado pausar mediante un botón oculto por la hoja (punto de toque `{-1,-1}`); al deslizar, el botón del reproductor inferior además abría de nuevo la hoja. Se corrigió la preparación del test para pausar desde el control visible y esperar el valor «Pausado»; se añadió una comprobación que impide dar por correcta una barra que sigue existiendo detrás de una hoja abierta.

El diagnóstico aislado [38994216495](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38994216495) ejecutó un único test y falló por el motivo previsto: el arrastre abría la hoja. Se cambió `simultaneousGesture` por `highPriorityGesture` para impedir que el botón se active al reconocer un arrastre. CI admite ahora seleccionar una prueba para diagnosticar; la selección está bloqueada al solicitar IPA, que requiere la suite completa.

La ejecución integrada [38994846098](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38994846098) pasó las 147 unitarias, ambos recorridos de gesto, Blues y Jazz tras reabrir. Falló un test previo de prioridad manual: tardó 89,7 segundos y el WAV de 60 segundos ya había avanzado naturalmente a la canción manual al inspeccionar la cola. El registro confirma reproducción antes de `t=21,57s` y la inspección a `t≈89s`. Se añadió una pausa desde el reproductor visible antes de navegar; se mantiene la expectativa original «A continuación · Añadida por ti».

La ejecución [38996566422](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38996566422) pasó 147 unitarias, pero el runner de interfaz no llegó a iniciar ningún test: `XCTDaemonErrorDomain Code=18`, «Timed out waiting for AX loaded notification», con advertencias de clases duplicadas de accesibilidad de WebKit en el simulador. No es una comprobación pasada de interfaz ni produjo IPA. Se repite sin cambiar código en un runner nuevo.

La ejecución completa [38997159679](https://github.com/luispipesuarez-de/reproductor-personal-ios-build-20261015/actions/runs/38997159679), sobre el mismo código, pasó **147 unitarias y 16 pruebas de interfaz, cero fallos**, y **Release compiló correctamente**. Los logs contienen `TEST SUCCEEDED` y `BUILD SUCCEEDED`. Incluyen Blues, Jazz tras reabrir, ambos deslizamientos en pausa, cola vacía al relanzar, conservación del favorito, protección mientras reproduce y prioridad manual con la precondición estable.

El commit público probado es `5de4cd3702d1810eb03b9487ee53084de55d3bb2`; sus 64 archivos de compilación coinciden con el commit privado `93e9410ef0e6b2a3201a27bb07e73db6894428c5`. Los cambios posteriores de documentación no alteran esas fuentes.

| Verificación de entrega | Resultado |
| --- | --- |
| Artefacto | ReproductorPersonal-27, id 12088365887 |
| ZIP | 11.170.606 bytes; SHA-256 `265f8642643df9c4882ceee63b0e35cc2c3f0fa28e869e711362bc9cb7c3707c`, coincide con GitHub antes de extraer |
| IPA | 2.012.432 bytes; SHA-256 `ba32cf9626f986e25f40f3af76ce2ace0352ea1473b8dbebabf10c147a2972c6` |
| Contenido del IPA | CRC correcto, una app, bundle `personal.reproductor.ios`, versión 0.1.0/7, arm64, iOS mínimo 16.0, audio en segundo plano, sin firma personal todavía |
| Release | Sin proveedor, WAV, recursos ni argumentos de pruebas de interfaz |
| Capturas | Cuatro inspeccionadas de las once exportadas: Radio Blues, Jazz conservado tras reabrir, favorito conservado sin reproductor inferior y géneros con texto grande/modo oscuro |
| Copia anterior | Compilación 6 conservada y hash verificado en `build/anteriores/ReproductorPersonal-compilacion-6.ipa` |
| Archivo de instalación | `build/ReproductorPersonal.ipa` sustituido y vuelto a verificar como 7 |
| iPhone físico | Instalación y pruebas de esta entrega pendientes |

Se conservan las advertencias previas de RadioControls/Sendable, metadatos AppIntents y orientaciones de iPad; no hubo errores de compilación. La escucha del catálogo real y los controles del teléfono se verifican por separado.

## Revisión independiente

La revisión de `6dac4fb…a690ee1` no encontró problemas críticos, importantes ni menores. Su valoración queda condicionada a que pasen la suite completa y Release. No se solicitaron cambios ni una segunda revisión.

Se aceptaron las siguientes delimitaciones señaladas por el revisor:

- Conservar la variedad de autores ya existente en recomendaciones, con las canciones del rango preferido delante. La nueva petición no impone un orden exacto entre esas canciones.
- Mantener los proveedores, resolución de flujos y audio en segundo plano existentes; se revisó su interacción con el cierre y se incluyen sus regresiones en la suite completa.
- Invalidar el efecto de una resolución pendiente mediante el identificador de petición existente. Su respuesta ya no puede restaurar reproducción, aunque la petición de red del llamador puede terminar posteriormente. Las tareas de radio y preparación del siguiente elemento sí se cancelan explícitamente.
- Mantener como pendientes las comprobaciones físicas de gestos, VoiceOver y controles de iOS. La revisión estática no acredita su comportamiento en el teléfono; la suite de interfaz comprueba el recorrido programado en simulador.

## Pruebas físicas pendientes

Antes de atribuir resultados a esta entrega, instalar sobre Reproductor con la misma cuenta de Apple y comprobar por USB `CFBundleVersion=7`.

| Recorrido | Resultado físico |
| --- | --- |
| Buscar Salsa/Rock y revisar duraciones de los primeros resultados; elegir también un video largo manualmente | Pendiente |
| Iniciar radio por género y desde canción; comprobar duración de las primeras canciones y continuidad bloqueada | Pendiente |
| Tocar Blues y escuchar la selección real | Pendiente |
| Añadir Jazz u otro género, cerrar y abrir; iniciarlo desde su botón | Pendiente |
| Pausar y deslizar el reproductor a la izquierda y después repetir hacia la derecha; comprobar que desaparece | Pendiente |
| Reabrir tras el cierre de la cola: no debe reaparecer el reproductor; favoritos, listas, historial y géneros deben seguir disponibles | Pendiente |
| Deslizar mientras suena: la reproducción y los controles se conservan | Pendiente |
| Volver a reproducir un favorito directamente tras cerrar y abrir, sin Buscar | Pendiente |

Las pruebas con respuestas controladas y audio local en simulador no sustituyen estas comprobaciones del catálogo y del teléfono real. Las observaciones anteriores se conservan en [verificacion-iphone.md](verificacion-iphone.md).
