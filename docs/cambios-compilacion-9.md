# Cambios Compilación 9: Corrección de Reproducción Inmediata y Prevención de Pausa Espuria

## Contexto y Causa Raíz
En la Compilación 8, la configuración de `AVQueuePlayer.automaticallyWaitsToMinimizeStalling = false` provocaba que ante la latencia natural de inicio de conexión en streams de YouTube remotos, `AVPlayer` reportara temporalmente `timeControlStatus == .paused`. Debido a que la bandera `isStartingItem` se apagaba antes de iniciar la reproducción, el controlador interpretaba esa pausa transitoria de red como una acción del usuario, cancelando `wantsPlayback` y dejando la canción congelada en estado pausado.

## Correcciones Aplicadas
1. **Restauración de `automaticallyWaitsToMinimizeStalling = true`**:
   - `AVQueuePlayer` mantiene el manejo de búfer suave nativo de iOS.
   - En espera de datos el reproductor entra en `.waitingToPlayAtSpecifiedRate(reason: .toMinimizeStalls)` sin abortar la intención de reproducir.
2. **Protección de la bandera `isStartingItem`**:
   - En `startCurrent` y `resume`, `isStartingItem` permanece en `true` hasta que el reproductor alcanza formalmente el estado `.playing` (o el usuario invoca explícitamente `pause()`).
   - Cualquier estado `.paused` transitorio generado por AVPlayer durante la inicialización es ignorado de forma segura sin apagar `wantsPlayback`.
3. **Pruebas Unitarias y Versión**:
   - `PlaybackControllerTests` valida que `automaticallyWaitsToMinimizeStalling == true`.
   - `project.yml` incrementa `CURRENT_PROJECT_VERSION` a `9`.

## Verificación y Entrega
- Artifact: ReproductorPersonal-35
- Run CI: 40614315730 (100% exitoso en 25m 46s)
- SHA-256: 104621bde3e80a5f184313bbf2a67c48f5cdf790c0a58137a5e113d29d82a825
- Tamaño: 2,091,157 bytes
- Entregado en: Desktop/ReproductorPersonal.ipa
