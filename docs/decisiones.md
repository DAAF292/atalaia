# AtalaIA: punto de partida y registro de decisiones

Versión consolidada: 2026-10-11. **Léelo primero.** Es el documento semilla del proyecto de Claude "AtalaIA": explica qué es cada documento, resume quién es Diego y cómo trabajar con él, y recoge **todas las decisiones tomadas** con su estado, para que no se pierda ninguna.

---

## 1. Por qué un proyecto aparte, y qué queda en cada uno

AtalaIA nació como un accesorio del homelab (un dashboard para el Echo Show) y ahora es **el proyecto personal de Diego que lo engloba todo**: un ecosistema de herramientas propias que integra la IA de forma práctica, para mejorar su vida personal y profesional, aprender las tecnologías más demandadas y servir de portfolio.

| Proyecto "HomeLab" | Proyecto "AtalaIA" |
|---|---|
| **Dónde corren las cosas**: Proxmox, VMs, LXC, red, Tailscale, Caddy, Authelia, dominio y DNS, **copia del host**, Echo Show a nivel de sistema | **Qué corre**: las herramientas, el código, el diseño y el aprendizaje |
| Ejemplos: crear el LXC "ai", ampliar la RAM, el registro DNS comodín `*.atalaia` | Ejemplos: diseñar el motor de eventos, revisar un PR, preparar la teoría de un paso |

- Los dos proyectos **no se ven entre sí**. El punto común es el repo `DAAF292/atalaia` en GitHub.
- **La fuente de verdad a largo plazo es el repo**, no ningún proyecto de Claude: los documentos van a `docs/` y las reglas operativas a `CLAUDE.md`. Así los lee igual el Claude del proyecto, el de la VM `dev` y cualquiera futuro, y quedan versionados.

## 2. Los documentos y cómo leerlos

| Orden | Documento | Qué es | Estado | En el repo pasará a |
|---|---|---|---|---|
| 1 | `atalaia-traspaso-proyecto-nuevo.md` (este) | Punto de partida y registro de decisiones | Vigente | `docs/decisiones.md` |
| 2 | `atalaia-vision-y-hoja-de-ruta.md` | Qué es AtalaIA, principios, catálogo de herramientas, privacidad, hoja de ruta | **Vigente** | `docs/vision.md` |
| 3 | `atalaia-ecosistema.md` | Arquitectura: capas, MCP, eventos, identidad, laIA, monorepo, reglas de crecimiento, fase 0 | **Vigente** | `docs/ecosistema.md` |
| 4 | `atalaia-metodo-de-trabajo.md` | Cómo se trabaja: Diego programa lo importante | **Vigente** | `docs/metodo.md` |
| 5 | `atalaia-proyecto-portfolio.md` | Diseño detallado del Dashboard: stack justificado, modo demo, tests, evals, observabilidad, seguridad, preguntas de entrevista | Vigente para el Dashboard (lo del asistente, marcado **[→ laIA]**) | `docs/dashboard.md` |
| 6 | `atalaia-dashboard-voz.md` | Diseño original del 2026-10-03 | **Histórico**; referencia para fuentes de datos, permisos y pantalla | `docs/historico/` |
| 7 | `atalaia-validar-hardware.md` | Pruebas del Echo Show | Vigente para las pruebas pendientes | `docs/echo-show.md` |

Si dos documentos parecen decir cosas distintas, manda este registro (sección 5), después la visión y después la arquitectura.

---

## 3. Quién es Diego y cómo trabajar con él

- Desarrollador **FullStack**, GitHub `DAAF292`. Seguirá en su puesto actual al menos hasta el verano de 2027.
- **Siempre en español**, respuestas detalladas, **críticas y no aduladoras**: contrastar, señalar pegas, no darle la razón sin criterio.
- **Nuevo en infraestructura**: explicar cada concepto de sistemas o redes desde cero, con analogías de desarrollo web.
- **Seguridad proporcionada**: no ser paranoico; avisar solo de riesgos que cambian algo (claves, credenciales, acceso a GitHub).
- **Método de aprendizaje** (`atalaia-metodo-de-trabajo.md`): Diego programa lo importante; la IA enseña, especifica, revisa (**señala, no arregla**) y solo programa lo accesorio. Ayuda por niveles cuando se atasca; la solución completa, solo si la pide.

---

## 4. Lo que el proyecto necesita saber del homelab

- **Host**: GEEKOM A8 (Ryzen 7 8745HS, iGPU 780M), 16 GB de RAM en un solo módulo (ampliable a 32 GB), 1 TB NVMe. Proxmox en `192.168.0.200`. **La copia del host sigue pendiente** y se hace en el proyecto HomeLab, sin esperar a AtalaIA.
- **VM `apps`** (`192.168.0.202`, 4 núcleos, 4 GB): Docker; Caddy (certificados Let's Encrypt por DNS de Cloudflare) + Authelia en `~/stacks/proxy`, red `proxy_default`. Aquí se despliega AtalaIA.
- **VM `dev`** (`192.168.0.203`, 4 núcleos, 4 GB): donde programa Diego. Claude Code, herdr (sesiones persistentes), `gh` autenticado como DAAF292, Docker, Python 3.13.
- **Dominio** `daaf-lab.link` en Cloudflare: registros A hacia IPs privadas, **sin proxy** (nube gris). Cada nombre necesita su registro DNS además de la entrada en Caddy; por eso se propone un comodín `*.atalaia`.
- **Acceso remoto**: Tailscale con subnet routing (toda la LAN accesible desde el móvil). Lo que algún día sea público, por **Cloudflare Tunnel**.
- **Despliegue que ya funciona**: el simulador en `https://simulador.daaf-lab.link`, con `~/stacks/simulador/deploy.sh` (fetch → tests en contenedor desechable → build → comprobación de arranque → rollback si falla) y `simulador-deploy.timer` cada 5 minutos. AtalaIA reutiliza el patrón, tirando de imágenes de GHCR.
- **Echo Show 5** (1.ª gen, 1 GB de RAM, 960×480): liberado con LineageOS; pantalla, altavoz y micrófono funcionan. Pendiente medir el micro a distancia, el micro dentro del WebView y el aguante del kiosco.
- **LXC "ai"**: no existe todavía; se crea para la fase 4 (Whisper y Piper).
- Otros repos de Diego: `proyecto-simulacion` (simulador), `MasterIA` (vault de Obsidian del máster, que Notas importará y Conocimiento indexará), `docia-gestor-pec`.

---

## 5. Registro de decisiones

Estado: **D** = decidido por Diego · **P** = propuesto por Claude y no objetado (se considera vigente salvo que Diego diga lo contrario) · **R** = propuesto en la revisión de coherencia del 2026-10-11, pendiente de visto bueno · **⏳** = pendiente de Diego.

### Visión y alcance

| # | Decisión | Estado | Dónde |
|---|---|---|---|
| 1 | AtalaIA es un ecosistema personal a largo plazo (vida personal y profesional, aprendizaje, portfolio) | D | Visión §1 |
| 2 | La IA es un ingrediente, no el producto: cada herramienta funciona sin IA | D | Visión §1 |
| 3 | Una herramienta cada vez, terminada antes de empezar otra | D | Ecosistema §6 |
| 4 | El agente se llama **laIA**; Laya descartado | D | Ecosistema §4 |
| 5 | laIA v1 = agente del homelab y de las herramientas del ecosistema | P (deducido de Diego) | Ecosistema §4 |
| 6 | Calendario y notas **propios**, sin depender de Google u otros servicios | D | Visión §4.4 |
| 7 | "Secretario" descartado: quedan **Notas** y **Agenda**; el papel de secretario lo hace laIA | D | Visión §4.1 |
| 8 | "Tareas" deja de ser herramienta: son notas de tipo tarea con recordatorio en Agenda | D (2026-10-11) | Visión §4.2 |
| 9 | Rumbo (empleo) no es prioritaria: después de Bitácora | D | Visión §4.1 |
| 10 | Hito: lo terminado en primavera de 2027 va al CV (realista: Dashboard y laIA) | D/P | Visión §7 |
| 11 | Hoja de ruta: 0 Cimientos · 1 Dashboard · 2 laIA · 3 Copias · 4 Voz + Notas · 4b Agenda · 5 Móvil · 6 Bitácora · 7 Vigía · 8 Conocimiento | P | Visión §7 |
| 12 | La copia del host Proxmox se hace ya en HomeLab; AtalaIA Copias cubre los datos del ecosistema y las pruebas de restauración | D (2026-10-11) | Visión §4.4 |
| 13 | Descartados: Home Assistant, palabra de activación, Uptime Kuma y Docker de `dev` como fuentes, LiteLLM, LangChain, Kubernetes, Personas, Hábitos, Domótica, CalDAV propio, Radicale, Neo4j, base vectorial aparte | D/P | Visión §4.3 |

### Repo y forma de trabajar

| # | Decisión | Estado | Dónde |
|---|---|---|---|
| 14 | Repo **público** desde el primer commit | D | Portfolio §12 |
| 15 | **Todo en español**, también los nombres en el código (salvo lo que imponen librerías y estándares) | D | Ecosistema §5 |
| 16 | Proyecto de Claude propio para AtalaIA; HomeLab solo para infraestructura | D | §1 |
| 17 | Diego programa lo importante; la IA enseña, especifica, revisa y hace lo accesorio | D | Método |
| 18 | Monorepo con `apps/`, `servicios/`, `paquetes/`, `despliegue/`, `docs/`; `uv` + `pnpm`; sin Nx ni Turborepo | P | Ecosistema §5 |
| 19 | El repo es la fuente de verdad (`docs/` + `CLAUDE.md`) | P | §1 |

### Arquitectura y stack

| # | Decisión | Estado | Dónde |
|---|---|---|---|
| 20 | laIA ↔ herramientas por **MCP**; solo lectura por defecto, escritura con confirmación | P | Ecosistema §3.1 |
| 21 | Eventos con sobre común tipo CloudEvents, por SSE y webhooks firmados; sin broker hasta que dos consumidores lo necesiten | P | Ecosistema §3.2 |
| 22 | Identidad con Authelia (forward auth; OIDC + PKCE para el móvil) | P | Ecosistema §3.3 |
| 23 | Echo Show con **token de dispositivo**; bypass por IP solo provisional | P | Portfolio §7.6 |
| 24 | Direcciones: `atalaia.daaf-lab.link` portada, `<herramienta>.atalaia.daaf-lab.link`, registro DNS comodín | D (2026-10-11) | Ecosistema §3.3 |
| 25 | Backend Python 3.13 + FastAPI + Pydantic v2 + httpx; puertos y adaptadores | P | Portfolio §5 |
| 26 | Frontend TypeScript + Vite + Preact (signals), tipos generados desde OpenAPI, uPlot | P | Portfolio §5 |
| 27 | SSE con `Last-Event-ID` para el tiempo real | P | Portfolio §5 |
| 28 | `ProveedorLLM` propio sobre el SDK de Anthropic, Haiku por defecto; router por sensibilidad más adelante | P (revisada por #39) | Ecosistema §4 |
| 29 | Voz local: faster-whisper + Piper en el LXC "ai"; pulsar para hablar; **el audio nunca sale de casa** | D/P | Visión §5 |
| 30 | SQLite en el Dashboard y, al principio, en laIA; **Cerebro** = PostgreSQL + pgvector desde Notas | P | Visión §3 |
| 31 | Agenda sobre iCalendar/RRULE con librerías, enlace `.ics`, sin CalDAV | P (sobre la D #6) | Visión §4.4 |
| 32 | Notas en Markdown, enlaces `[[...]]`, importación de Obsidian en un sentido, exportable; conflictos: última escritura + historial, CRDT solo si hace falta | P (sobre la D #6) | Visión §4.4 |
| 33 | Móvil: PWA y después React Native + Expo, por Tailscale | P | Visión §4.4 |
| 34 | Dashboard v1 **sin IA**; el diagnóstico de fallos con IA se añade después de laIA | D (2026-10-11) | Ecosistema §4 |
| 35 | Trazas de cada llamada al LLM desde la fase 2 | D (2026-10-11) | Ecosistema §4 |
| 36 | CI en GitHub Actions (lint, tipos, tests, GHCR, gitleaks); despliegue por pull con el patrón `deploy.sh` | P | Portfolio §5 |
| 37 | Modo demo con recolector falso en todas las herramientas; demo pública opcional por Cloudflare Tunnel | P | Portfolio §6 |
| 38 | **Coste de la API de Claude como criterio de diseño**: Haiku por defecto, subir de modelo solo si las evals lo justifican; tope de iteraciones y de gasto diario en `ProveedorLLM`; caché de prompts; Batch API para evals | R (2026-10-11) | docs/costes-api.md |
| 39 | **Proveedor de LLM multi-fuente**: `ProveedorLLM` con formato neutro y adaptadores (Anthropic y dialecto compatible con OpenAI al principio); el modelo por defecto se elige con evals propias por coste por tarea, no por catálogo. Sustituye el "sobre el SDK de Anthropic" de #28 | R (2026-10-11) | docs/estudio-modelos.md |

### Pendientes de Diego

| # | Pregunta | Cuándo hace falta | Recomendación |
|---|---|---|---|
| ⏳ 1 | ¿Pueden notas, agenda y lecturas ir a la API de Claude? | Fase 4 | Sí, solo el fragmento necesario, con etiqueta de sensibilidad; lo privado a local cuando haya 32 GB |
| ✅ 2 | Visto bueno a las propuestas **R** (#8, #12, #24, #34, #35) | — | Aceptadas por Diego el 2026-10-11 |
| ⏳ 3 | Licencia del repo público | Sin prisa | Diego: se deja sin licencia de momento (2026-10-11) |

---

## 6. Primeros pasos

1. **HomeLab:** copia del host Proxmox (no esperar).
2. **Diego:** crear el repo con `gh repo create DAAF292/atalaia --public` desde `dev`.
3. **Proyecto AtalaIA, fase 0:** la IA monta la estructura, la configuración y el `CLAUDE.md`, y copia estos documentos a `docs/`; Diego escribe su primer workflow de CI, el README, el primer ADR y el sobre de eventos.
4. **Fase 1, primer paso de Diego:** el modelo de la "foto" del sistema y el motor de eventos con tests.

## 7. Instrucciones para el proyecto de Claude "AtalaIA"

Para pegar en las instrucciones del proyecto:

```
AtalaIA es mi ecosistema personal de herramientas que integra la IA de forma práctica (laIA como agente, AtalaIA Dashboard, Notas, Agenda, Bitácora...). Sirve para mejorar mi vida personal y profesional, aprender las tecnologías más demandadas y como portfolio.

- Responde siempre en español, de forma detallada, crítica y contrastada; no me des la razón sin criterio.
- Soy FullStack pero nuevo en infraestructura: explica los conceptos de sistemas desde cero.
- Método: yo programo lo importante. Tú enseñas (teoría + documentación oficial), especificas con criterios de aceptación, revisas mis PRs como un senior exigente sin darme el código corregido, y solo programas lo accesorio (configuración, estilos, datos de demo, repeticiones). Si me atasco, ayuda por niveles: pregunta, pista, ejemplo análogo, fragmento; la solución completa solo si la pido.
- La IA es un ingrediente, no el producto: cada herramienta debe servir sin IA.
- Una herramienta cada vez, terminada (desplegada, modo demo, tests/evals, README, ADR, MCP) antes de empezar otra.
- Todo en español, también los nombres en el código.
- La fuente de verdad es el repo DAAF292/atalaia (docs/ y CLAUDE.md); si hay contradicciones, manda docs/decisiones.md. Los cambios de infraestructura del homelab se hacen en el proyecto HomeLab.
```
