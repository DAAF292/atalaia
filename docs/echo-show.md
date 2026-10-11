# AtalaIA: cómo validar qué hardware funciona

> **Estado a 2026-10-11 (confirmado por Diego el 2026-10-09):** el Echo Show está **liberado con LineageOS** (amonet sobre la build NS65741/8146; copia de particiones en `Escritorio\AtalaIA\backup`). **Pantalla, altavoz y micrófono funcionan** (graba con la grabadora preinstalada). Por tanto los pasos 1 y 2 de abajo están hechos y las dudas de la sección final sobre si Lineage está instalado ya no aplican.
>
> **Pendiente**, por orden: calidad del micro a 1 m y 3 m (paso 4), altavoz al 80 % (paso 5), micro dentro del WebView con HTTPS (paso 7, imprescindible antes de la fase 4 de la hoja de ruta, Voz + Notas) y prueba de aguante de 24-48 h con el kiosco (paso 8, durante la fase 1, Dashboard).
>
> **Nota de numeración:** donde abajo pone "fase 3" o "fase 4" se refiere a las fases del diseño original. En la hoja de ruta vigente (`atalaia-vision-y-hoja-de-ruta.md`) la voz llega en la **fase 4** y el kiosco del Dashboard en la **fase 1**.

Fecha: 2026-10-09. Se refiere al **Echo Show 5 1.ª gen ("checkers", MT8163, 1 GB RAM)**. El propio plan (`atalaia-dashboard-voz.md`, "Riesgos y pegas honestas") ya lo marca como el eslabón débil: LineageOS no oficial, Android 11, y micrófono con fallos reportados en algunas builds.

## Qué necesita AtalaIA del aparato (y qué es crítico)

| Necesidad | Para qué | Riesgo según las guías | Si falla |
|---|---|---|---|
| Pantalla + táctil | Dashboard y botón "pulsar para hablar" | Bajo (funciona según Android Authority/Hackaday) | Proyecto inviable en el aparato |
| Wi-Fi estable (WPA2) | SSE continuo al backend | Bajo; WPA3 dudoso (las fuentes se contradicen) | Poner el router en modo mixto WPA2/WPA3 |
| WebView moderno + HTTPS | Dashboard y `getUserMedia` | Medio: Android 11 con 1 GB | Probar Fully Kiosk / otro WebView |
| Altavoz | Avisos hablados (Piper) | Bajo-medio (Liliputing cita "calidad del altavoz") | Fase 3 se degrada, no muere |
| **Micrófono** | Voz (fase 4) | **Alto: fallos reportados** | Fase 4 sin aparato: usar el móvil/PC como terminal de voz |
| RAM (1 GB) | Kiosco estable horas/días | Medio | Página ligera, recarga programada |

Lo único que puede tumbar una fase entera es el micro. Todo lo demás se degrada.

## Qué se puede validar YA, sin tocar el Echo

1. **Dashboard a 960×480 en el PC**: Chrome → F12 → modo dispositivo → dimensiones 960×480. (Fase 1 del plan.)
2. **Micrófono en HTTPS desde el navegador**: la parte de software (getUserMedia, subir audio, Whisper) se prueba con el micro del PC o del móvil antes de que exista el Echo.
3. **Peso del dashboard**: medir tamaño del bundle y memoria en Chrome (pestaña Rendimiento/Memoria). Objetivo: muy por debajo de 100 MB de RAM de página.
4. **Latencia de voz** (la tabla de ~3-5 s del plan es estimación, no medida): medirla con el PC como cliente.

## Qué hay que validar en el propio Echo (orden recomendado, de barato a caro)

**Estado actual detectado en tu PC (Escritorio\AtalaIA):** ya existe la carpeta `backup/` con fecha 2026-10-03 (≈19:13-19:27), con las particiones completas (kb, lk, tee, boot, recovery, system, persist, GPT, boot0/boot1...). El `system` de la copia es **NS65741, ro.product.device=checkers**. Es decir: el exploit parece haberse ejecutado y la copia de seguridad (fase 3 de la guía) está hecha, o sea, **amonet funcionó sobre tu build 8146**. Lo que no puedo saber desde los archivos es si LineageOS ya está instalado. Compruébalo en el paso 1.

Pasos, con el aparato conectado por USB al PC (carpeta `platform-tools-latest-windows\platform-tools`, PowerShell):

1. **¿En qué estado está?**
   - Enciéndelo normal. Si arranca Lineage, verás un asistente de Android; si arranca Alexa, aún no está instalado.
   - Con depuración USB activada: `.\adb.exe devices` → debe listar el aparato.
   - `.\adb.exe shell getprop ro.build.display.id` y `getprop ro.lineage.version` → si responde, es Lineage.
   - Si estás en fastboot: `.\fastboot.exe getvar unlock_status` → `true` = bootloader desbloqueado.
2. **Si aún no hay Lineage:** seguir fases 4-5 de `echo-show-5-gen1-guia.md` (TWRP → wipe de system/data/cache → instalar el zip → reiniciar). Ojo: el README oficial de v2.0.1 no existe en la carpeta; los scripts son autoexplicativos (`fastbrick.bat` → desbloquea; `boot-recovery.sh` → flashea TWRP).
3. **Inventario de hardware con adb** (2 min, sin instalar nada):
   - `adb shell dumpsys audio | findstr /i "mic input"` y `adb shell tinymix` (si existe) para ver si hay dispositivo de captura.
   - `adb shell dumpsys media.audio_flinger` → buscar dispositivos de entrada.
   - `adb shell cat /proc/meminfo | findstr MemTotal` → confirmar ~1 GB.
   - `adb shell dumpsys display | findstr mBaseDisplayInfo` → resolución real.
   - `adb shell getprop ro.build.version.release` → Android 11.
4. **Prueba de micrófono real** (la clave): instalar una grabadora (p. ej. `adb install` de una APK de grabadora de F-Droid), grabar 10 s hablando a 1 m, reproducir. Anotar: ¿graba?, ¿nivel?, ¿ruido?, ¿a 3 m se entiende? También `adb shell` + `tinycap /sdcard/t.wav` si hay tinyalsa.
5. **Prueba de altavoz**: reproducir un audio y una frase TTS; ¿distorsiona al 80 %?
6. **Prueba de pantalla/táctil**: abrir Chrome/WebView a una página de test táctil; y a la URL del dashboard cuando exista.
7. **Prueba de micro en WebView + HTTPS**: abrir en el Echo una página mínima con `getUserMedia` servida por Caddy (`https://...daaf-lab.link`). Es la prueba que de verdad importa para la fase 4, porque combina micro + WebView + permisos de Fully Kiosk.
8. **Prueba de aguante**: dejar el dashboard 24-48 h; mirar `adb shell dumpsys meminfo` y si el WebView se reinicia o el aparato se cuelga por RAM.

## Criterio de decisión

- Micro OK → plan tal cual.
- Micro no funciona → no es el fin: terminal de voz = móvil/PC (la misma página con botón de hablar); el Echo queda como pantalla + altavoz para avisos. El diseño no depende del aparato.
- WebView/RAM insuficiente → página más ligera; si no basta, cualquier tablet Android barata como pantalla (alternativa que ya contemplan las guías).

## Cosas que NO sé (y no afirmo)

- Si Lineage está ya instalado: depende de lo que pase al encender el aparato.
- Si el micro funciona en la build `lineage-18.1-20260904`: solo se sabe probándolo.
- La latencia real de voz.
