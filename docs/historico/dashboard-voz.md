# AtalaIA: dashboard + asistente de voz del homelab en el Echo Show 5

> **Documento histórico (revisado 2026-10-11).** Es el diseño original del 2026-10-03, cuando AtalaIA era una sola aplicación. **Sigue siendo la referencia** para: las fuentes de datos y sus permisos mínimos (tabla de la sección 2), el esbozo de la pantalla de 960×480, el modo noche, Fully Kiosk y la latencia estimada de la voz.
>
> **Ha quedado sustituido** en estos puntos (la versión vigente está entre paréntesis):
> - LiteLLM → `ProveedorLLM` propio con el SDK de Anthropic (`atalaia-ecosistema.md`, sección 4).
> - Dashboard en HTML/JS sin framework → TypeScript + Vite + Preact (`atalaia-proyecto-portfolio.md`, sección 5).
> - `/api/ask` y el agente dentro del Dashboard → el agente es **laIA**, una herramienta aparte; el Dashboard expone un servidor MCP de solo lectura.
> - Una URL `atalaia.daaf-lab.link` para todo → `atalaia.daaf-lab.link` como portada y `<herramienta>.atalaia.daaf-lab.link` por herramienta.
> - Bypass de Authelia por IP del Echo → token de dispositivo (el bypass, solo provisional).
> - Las fases de la sección final → hoja de ruta de `atalaia-vision-y-hoja-de-ruta.md`.
> - "El despliegue automático que está pendiente" → ya está hecho y funcionando (`deploy.sh` + timer de systemd del simulador).
> - Uptime Kuma y el Docker de `dev` como fuentes → descartados.

Fecha: 2026-10-03. Diseño propuesto, pendiente de que Diego lo valide. Nombre elegido por Diego: **AtalaIA** (atalaya + IA).

## Qué es

Una aplicación propia con dos caras que comparten el mismo cerebro:

- **Ojos:** un dashboard hecho a medida para la pantalla de 960×480 del Echo Show, con el estado del homelab de un vistazo y actualizado en directo.
- **Voz:** pulsas un botón de la pantalla, preguntas ("¿cómo va la VM apps?", "¿ha ido bien el último despliegue?", "¿qué contenedor está gastando más memoria?") y te responde hablando. Además, **avisa por sí sola** cuando pasa algo importante, como un despliegue fallido o una VM caída.

## Un cambio respecto a lo que te recomendé antes

En el documento anterior recomendé Home Assistant como base para la voz. **Con un dashboard propio ya no lo recomiendo**, y te explico por qué:

- La página web del dashboard ya es la dueña de la pantalla. Si además metes la app de Home Assistant como satélite de voz, tienes **dos apps peleándose** por la pantalla y el micrófono en un aparato con 1 GB de RAM.
- No tienes domótica. Home Assistant te aportaría solo la tubería de voz, a cambio de ~1 GB de RAM más en el GEEKOM y otra pieza que mantener.
- La tubería de voz por "pulsar para hablar" es **sencilla de hacer tú mismo**: el navegador graba el audio y tu backend lo transcribe, piensa y devuelve audio. Lo difícil de verdad, que es la palabra de activación siempre escuchando, lo dejamos para el final y como opcional.

Así que la propuesta es **todo propio**, con piezas estándar de IA para lo que no tiene sentido reinventar: Whisper para transcribir y Piper para hablar.

---

## Arquitectura

```
┌──────────────── Echo Show 5 (LineageOS) ────────────────┐
│  Fully Kiosk Browser → https://atalaia.daaf-lab.link     │
│   ├─ Dashboard (HTML/JS ligero), recibe datos por SSE    │
│   ├─ Botón "hablar": graba audio (getUserMedia)          │
│   └─ Reproduce las respuestas y los avisos (audio)       │
└──────────────────────────┬──────────────────────────────┘
                           │ HTTPS (Caddy, ya montado)
┌──────────────── VM apps (Docker) ───────────▼───────────┐
│  atalaia-backend  (Python + FastAPI)                     │
│   ├─ Recolectores: cada X s consultan las fuentes        │
│   ├─ Estado actual en memoria + historial en SQLite      │
│   ├─ Motor de eventos: "deploy ok", "VM caída"…          │
│   ├─ /api/stream (SSE) → dashboard                       │
│   └─ /api/ask: audio → texto → LLM + herramientas → voz  │
│  docker-socket-proxy (Docker en SOLO LECTURA)            │
└───────┬────────────────┬────────────────┬───────────────┘
        │                │                │
   API Proxmox      API GitHub      LXC "ai" (nuevo)
   (token solo      (token solo     ├─ faster-whisper (voz→texto)
    lectura)         lectura)       ├─ Piper (texto→voz)
                                    └─ más adelante: llama.cpp (LLM local)
                                          │
                              LLM: API de Claude vía LiteLLM al principio,
                              modelo local cuando exista el LXC "ai" completo
```

### Las piezas, una por una

**1. Backend `atalaia-backend` (Python + FastAPI), en la VM `apps`.**
Elijo Python porque es el lenguaje del simulador y del ecosistema de IA (Whisper, LiteLLM y los SDKs de LLMs son nativos en Python). Si prefieres Node/TypeScript también funciona, solo cambia esta pieza.

Hace cuatro cosas:
- **Recolectores** (como cron jobs dentro de la app): cada 5-15 s preguntan a cada fuente cómo está y guardan una *foto* normalizada del homelab. Por ejemplo: `{host: {cpu, ram}, vms: [...], containers: [...], deploys: [...]}`.
- **Motor de eventos:** compara la foto nueva con la anterior y genera eventos. Si la VM `dev` estaba `running` y ahora está `stopped`, sale el evento "VM dev parada". Es el mismo patrón que un reducer de Redux: estado anterior + nueva lectura → diferencias → acciones.
- **SSE (Server-Sent Events)** hacia el dashboard: un canal HTTP que se queda abierto y por el que el servidor empuja actualizaciones. Es más simple que WebSockets y basta, porque el dashboard solo *recibe*.
- **`/api/ask`:** el endpoint de voz (ver más abajo).

**2. Fuentes de datos (todas en solo lectura).**

| Fuente | Qué da | Cómo, con permisos mínimos |
|---|---|---|
| **API de Proxmox** | CPU, RAM y disco del host; estado y consumo de cada VM o LXC | Usuario `atalaia@pve` con rol **PVEAuditor** (solo lectura) y un API token. Nunca el root |
| **Docker de `apps`** | Contenedores, estado, CPU/RAM, reinicios, logs | **docker-socket-proxy** con solo los endpoints de lectura activados. Montar el `docker.sock` directamente equivale a dar root sobre la VM |
| **Docker de `dev`** | Lo mismo para `dev` (opcional) | Otro docker-socket-proxy en `dev`, accesible solo desde `apps` |
| **GitHub** | Últimos commits y estado de los workflows de despliegue de `proyecto-simulacion` | **Token fine-grained** limitado a ese repo, con permisos de solo lectura (Actions: read, Contents: read). No tu sesión de `gh` |
| **Webhooks de despliegue** | "El despliegue ha terminado" al instante, sin esperar al sondeo | Se engancha al flujo de despliegue automático que está pendiente: al final del job, un `curl` a `/api/events` con un secreto compartido |
| **Uptime Kuma** (opcional) | Si los servicios responden por HTTP | Su API de solo lectura o un webhook |

**3. Dashboard (frontend), servido por el mismo backend.**
- Diseñado **para 960×480 desde el primer píxel**: texto grande, 4-6 elementos como mucho, colores de estado (verde/ámbar/rojo) y nada de gráficos densos.
- **Ligero**: 1 GB de RAM y una GPU de 2015. Usaría HTML + CSS + un poco de JS sin framework, o como mucho **Preact** o **Svelte** (compilan a muy poco código). React con un bundle de 300 KB funcionaría, pero tiraría más de la cuenta.
- Esbozo de la pantalla:

```
┌───────────────────────────────────────────────────────────┐
│ 21:47    ● Todo OK                         🎤 (botón)     │
├──────────────────┬──────────────────┬─────────────────────┤
│ HOST daaf-lab    │ VMs              │ ÚLTIMO DESPLIEGUE   │
│ CPU  12 %        │ ● apps   38% RAM │ simulador  ✔        │
│ RAM  9,1/16 GB   │ ● dev    21% RAM │ hace 2 h · a1b2c3   │
│ Disco 34 %       │ ○ ai     parada  │                     │
├──────────────────┴──────────────────┴─────────────────────┤
│ CONTENEDORES  caddy ● authelia ● whoami ● simulador ●     │
│ Último aviso: "authelia reiniciado" (hace 3 h)            │
└───────────────────────────────────────────────────────────┘
```

- **Modo noche:** de madrugada, brillo al mínimo o pantalla apagada. La pantalla se despierta si hay un aviso rojo o si la tocas.

**4. Voz: pulsar para hablar** (el flujo de `/api/ask`).

```
[toque en 🎤] → el navegador graba (MediaRecorder) → suelta → POST audio
   → faster-whisper (LXC ai) → texto: "¿cómo va la VM apps?"
   → LLM con herramientas ──llama──▶ get_vm("apps")  (lee la foto actual)
   → texto: "La VM apps está encendida, al 38 % de RAM y con 4 contenedores sanos."
   → Piper (LXC ai) → audio WAV/OGG → el navegador lo reproduce
```

- **Herramientas del LLM** (tool calling): funciones de **solo lectura** que leen la foto que ya tiene el backend, sin llamar directamente a Proxmox. Así responden rápido y no puede romper nada:
  `get_resumen()`, `get_host()`, `listar_vms()`, `get_vm(nombre)`, `listar_contenedores(vm)`, `get_logs(contenedor, lineas)`, `ultimos_despliegues()`, `ultimos_eventos(n)`.
- **Qué LLM:**
  - **Al principio, la API de Claude (un modelo pequeño y barato) detrás de LiteLLM.** Es la opción con tool calling fiable y respuestas en español de buena calidad, y el LXC "ai" con un LLM local todavía no existe. Lo que sale de casa es el *texto* de tu pregunta y el estado del homelab, nada sensible. El audio se queda dentro.
  - **Después, un modelo local** (llama.cpp en el LXC "ai") cambiando solo la configuración de LiteLLM. Tu código no se entera, porque LiteLLM expone la misma API para los dos. Ojo: los modelos pequeños (3-8B) hacen tool calling bastante peor. Es un experimento interesante, pero no esperes la misma calidad.
- **Aviso de seguridad proporcionado:** la clave de la API de Claude va como variable de entorno o secreto del contenedor, **nunca en el repo**, y con **límite de gasto** configurado en la consola. Y las herramientas **solo leen**. Cuando quieras acciones ("reinicia el contenedor X"), lo hablamos aparte con confirmación explícita.

**5. Avisos hablados.**
Cuando el motor de eventos genera algo importante (despliegue fallido o correcto, VM caída, contenedor en bucle de reinicios, disco por encima del 90 %), el backend genera la frase, la pasa por Piper y la manda por SSE. El dashboard la muestra y la reproduce. Con **horario de silencio** por la noche: el aviso solo se muestra en pantalla, salvo que sea crítico.

**6. Palabra de activación ("oye AtalaIA"): al final y opcional.**
Es lo más difícil y lo que menos aporta, porque vas a estar delante de una pantalla táctil. Las opciones reales son tres, todas con pegas:
- Mandar el audio del micro **continuamente** al servidor y detectar allí la palabra con openWakeWord. Funciona, pero tienes un micro abierto en casa transmitiendo audio todo el rato.
- Detectarla **en el propio aparato**: en el navegador es complicado y con 1 GB de RAM no lo veo. Con **techo5** (Alpine) sí viene resuelto, pero entonces el dashboard tendría que adaptarse a su sistema.
- No hacerla. **Mi recomendación**, al menos hasta tener todo lo demás.

---

## Cómo encaja con lo que ya tienes

- **Caddy + Authelia** en `apps`: AtalaIA es un subdominio más (`atalaia.daaf-lab.link`), con certificado igual que `whoami`. Con un problema: Authelia pediría login en el Echo Show y la sesión caduca. Propuesta: **regla de Authelia `bypass` solo para la IP del Echo Show**, que fijaremos en el propio aparato, y login normal desde cualquier otro sitio. Es aceptable porque AtalaIA solo lee; si algún día tiene acciones, habrá que revisarlo.
- **HTTPS es obligatorio aquí:** los navegadores solo dejan usar el micrófono (getUserMedia) en páginas HTTPS. Como ya tienes los certificados de Let's Encrypt montados con Caddy, esto sale gratis.
- **El despliegue automático del simulador** que tenías pendiente sirve para los dos proyectos: el mismo mecanismo desplegará AtalaIA, y AtalaIA *mostrará y anunciará* los despliegues del simulador.
- **LXC "ai":** AtalaIA le da su primer uso real. Al empezar solo necesita faster-whisper (modelo `small` o `base` en int8, menos de 1 GB de RAM) y Piper (unos 100 MB). Con unos **2-3 GB** para el LXC sobra, y cabe en los ~6 GB libres del GEEKOM.
- **Desarrollo:** en la VM `dev`, con los agentes de Claude Code y herdr, en un repo nuevo y privado (`DAAF292/atalaia`). Puedes desarrollar y probar todo **en el navegador del PC con la ventana a 960×480 sin haber liberado aún el Echo Show**. El aparato no bloquea el proyecto.

## Latencia esperable (estimación mía, no medida)

| Paso | Tiempo aprox. |
|---|---|
| Subir 3-5 s de audio por la LAN | <0,2 s |
| faster-whisper `small` en CPU (Ryzen 8745HS) | 1-2 s |
| LLM por API con 1-2 llamadas a herramientas | 1-3 s |
| Piper | <0,5 s |
| **Total** | **~3-5 s** |

Para consultar el estado está bien. No va a ser una conversación fluida como con Alexa, y con un LLM local en la 780M será más lento todavía.

---

## Fases (cada una deja algo funcionando)

| # | Fase | Resultado visible | Necesita |
|---|---|---|---|
| 1 | **Backend + recolectores de Proxmox y Docker + dashboard por SSE** | Ves el estado del homelab en directo en `atalaia.daaf-lab.link` (desde el PC) | Token PVEAuditor, docker-socket-proxy |
| 2 | **Echo Show en kiosco** | El dashboard vive en el Echo Show | Liberar el Echo (guía), Fully Kiosk, regla de Authelia |
| 3 | **Eventos + avisos hablados** | "Despliegue del simulador correcto" suena en casa | LXC "ai" con Piper; webhook desde el despliegue |
| 4 | **Pulsar para hablar** | Le preguntas y responde | faster-whisper, LiteLLM + clave de API |
| 5 | GitHub, Uptime Kuma, `dev`, historial y gráficos | Más información y tendencias | Tokens de solo lectura |
| 6 (opc.) | LLM local en el LXC "ai" | Todo dentro de casa | llama.cpp/Vulkan, RAM |
| 7 (opc.) | Palabra de activación | Manos libres | Ver punto 6 de la arquitectura |

**Orden recomendado:** la 1 primero, aunque el Echo Show aún no esté liberado, porque te da algo útil en el PC desde el primer día. Mientras, liberas el Echo Show con calma (y vigilando la versión de Fire OS).

## Decisiones que he tomado por defecto (cámbialas si quieres)

- Todo propio, **sin Home Assistant**.
- Backend en **Python/FastAPI**; frontend ligero (vanilla o Preact/Svelte).
- Corre en la VM **`apps`** como un stack de Docker Compose más; la voz va en un **LXC "ai"** nuevo.
- **SSE** en vez de WebSockets.
- **LLM por API (Claude vía LiteLLM)** al empezar y local más adelante.
- **Pulsar para hablar**; sin palabra de activación.
- **Solo lectura** en todo; las acciones se discuten aparte.
- Repo nuevo y privado `DAAF292/atalaia`, desarrollado en `dev`.

## Riesgos y pegas honestas

- **El Echo Show es el eslabón débil:** LineageOS no oficial, Android 11 y 1 GB de RAM. Si un día falla el WebView o el micro, el proyecto sigue sirviendo en cualquier navegador o móvil, porque el diseño no depende del aparato.
- **El micro en LineageOS para checkers** tiene problemas reportados en algunas builds. **Pruébalo nada más liberarlo**, antes de invertir en la fase 4: graba algo con cualquier app de grabadora.
- **Fully Kiosk:** permisos del micro dentro del WebView. Funciona, pero hay que activarlo en su configuración. Algunas funciones de kiosco son de la versión Plus, de pago (licencia única barata).
- **RAM del GEEKOM:** apps (4) + dev (4) + ai (2-3) + Proxmox (~1-2) ≈ 11-13 GB de 16. Cabe, pero un LLM local de verdad no entrará a la vez.
- **Alcance:** es un proyecto de semanas a ratos, no de una tarde. La fase 1 sola ya es un buen proyecto de fin de semana.
