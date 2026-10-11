# AtalaIA: arquitectura del ecosistema

Versión consolidada: 2026-10-11. **Documento vigente** para cómo se organiza y se comunica el ecosistema. Qué herramientas hay y en qué orden: `atalaia-vision-y-hoja-de-ruta.md`. Diseño del Dashboard: `atalaia-proyecto-portfolio.md`.

---

## 1. Opinión sincera: por qué un ecosistema y sus dos trampas

**Por qué es mejor que una sola aplicación:**

- **Se parece al trabajo real.** En una empresa no se construye una app aislada, sino servicios que se hablan con contratos, autenticación compartida y despliegues independientes. Demostrar eso es lo que separa a un perfil junior de alguien que puede trabajar en un sistema de verdad.
- **El agente encaja mejor como pieza propia.** El Dashboard sabe del homelab; laIA sabe conversar y usar herramientas, sean del Dashboard o de cualquier otra.
- **Crece contigo** en lugar de dejar repos sueltos y olvidados.

**Las dos trampas, y sus reglas:**

1. **Alcance infinito.** Un mapa con diez herramientas "planificadas" y ninguna funcionando resta más que una sola aplicación pulida. Regla: **no se empieza una herramienta hasta que la anterior cumple la definición de terminado** (sección 6).
2. **Plataforma antes que producto.** Montar bus de eventos, SSO, plugins y librerías comunes antes de tener nada útil. Regla: **una pieza compartida solo se extrae cuando la necesitan dos herramientas de verdad.**

Y sobre laIA: un "ChatGPT propio" es de los proyectos de portfolio más repetidos y siempre perdería frente a Claude como asistente general. laIA solo tiene sentido por lo que esos no tienen: **tu contexto, tus herramientas y tus terminales** (sección 4).

---

## 2. Las cuatro capas

```
                    ┌───────────────────────────────────────────────┐
  TERMINALES        │ Echo Show (kiosco) · Web · Móvil · Claude Code │
                    └──────────────────────┬────────────────────────┘
                                           │ HTTP (Caddy + Authelia)
                                           ▼
  AGENTE              ┌──────────────────────────────┐
                      │            laIA              │  conversación (texto y voz),
                      │  agente LLM + cliente MCP    │  historial, avisos proactivos
                      └───┬───────────┬───────────┬──┘
                          │ MCP       │ MCP       │ MCP
                          ▼           ▼           ▼
  HERRAMIENTAS     ┌───────────┐ ┌─────────┐ ┌─────────┐   cada una: API HTTP propia,
                   │ Dashboard │ │  Notas  │ │   ...   │   servidor MCP, interfaz si
                   └─────┬─────┘ └────┬────┘ └────┬────┘   la necesita, y eventos
                         │ eventos    │           │
                         ▼            ▼           ▼
  PLATAFORMA       Voz · Avisos · ProveedorLLM · Contratos · Kit de UI · Identidad
  Y DATOS          Cerebro (PostgreSQL + pgvector)
```

- **Terminales**: el Echo Show, el navegador, el móvil y cualquier cliente MCP (Claude Code en `dev`, Claude Desktop en tu PC). No tienen lógica: muestran y reenvían.
- **Agente (laIA)**: no sabe nada del homelab ni de tus notas por sí misma. Sabe **conversar, decidir qué herramienta usar y combinar resultados**.
- **Herramientas**: cada una resuelve un problema y es **útil sin laIA**. Expone una **API HTTP** (para su interfaz), un **servidor MCP** (para laIA y otros clientes de IA) y **eventos** cuando pasa algo relevante.
- **Plataforma y datos**: lo que comparten varias piezas, extraído solo cuando hace falta.

---

## 3. Cómo se comunican las piezas

### 3.1 laIA ↔ herramientas: MCP

**Explicado desde cero:** MCP (Model Context Protocol) es un estándar abierto, publicado por Anthropic a finales de 2024 y adoptado por la mayoría de clientes de IA, para que una aplicación con LLM descubra y use herramientas de otros sistemas. Es como si cada servicio publicara su OpenAPI en un formato que los LLM entienden directamente: cada herramienta arranca un **servidor MCP** que dice "tengo estas funciones, con estos parámetros y esta descripción", y laIA se conecta como **cliente MCP**.

| A favor | En contra, y por qué se acepta |
|---|---|
| Añadir una herramienta es registrar un servidor MCP más, **sin tocar laIA** | Es una capa más y un protocolo joven que cambia; el SDK oficial de Python oculta casi todo |
| Las herramientas sirven también **fuera de laIA**: Claude Code o Claude Desktop pueden consultar el Dashboard desde el primer día | Algo más de latencia que una llamada directa; despreciable para consultas |
| Tema muy preguntado en entrevistas de puestos con IA | — |

**Seguridad:** las herramientas MCP son **de solo lectura** por defecto. Toda acción que escriba (crear un evento, desplegar) exige **confirmación explícita** en laIA antes de ejecutarse.

### 3.2 Herramientas → resto: eventos

- **Al principio, webhooks HTTP y SSE.** Cada herramienta publica sus eventos en un endpoint SSE (`/eventos`) y, si alguien se suscribe, le hace un `POST` **firmado con HMAC** (como los webhooks de GitHub).
- **Sobre común desde el primer día**, inspirado en el estándar **CloudEvents**: `id`, `origen` (qué herramienta), `tipo` (por ejemplo `despliegue.fallido`), `fecha`, `datos`. Vive en `paquetes/contratos`. Es barato ahora y muy caro de cambiar después.
- **Broker de mensajes (NATS o Redis Streams) solo cuando haga falta.** Un broker es un buzón central: los productores dejan mensajes y los suscriptores los recogen aunque estuvieran caídos. Se añade cuando dos o más consumidores necesiten el mismo evento con entrega garantizada. Como el sobre ya es común, añadirlo no obliga a cambiar los productores.

### 3.3 Terminales → todo: HTTP detrás de Caddy y Authelia

- **Identidad única:** Authelia autentica y pasa la identidad del usuario a cada servicio en cabeceras (**forward auth**). Ninguna herramienta implementa su propio login. Para la app móvil, Authelia actúa como proveedor **OIDC** (flujo con PKCE).
- **El Echo Show:** no puede hacer login cada vez. Se usa un **token de dispositivo** propio guardado en el kiosco. El bypass de Authelia por IP del Echo es la solución provisional mientras tanto, documentando su debilidad (una IP de la LAN se puede suplantar desde dentro de tu red).
- **Direcciones** (propuesta nueva de esta revisión): `atalaia.daaf-lab.link` es la portada del ecosistema (laIA y el mapa de herramientas) y cada herramienta va en `<herramienta>.atalaia.daaf-lab.link` (`dashboard.atalaia...`, `notas.atalaia...`). Con **un único registro DNS comodín** `*.atalaia` apuntando a la VM `apps` (`192.168.0.202`, sin proxy de Cloudflare) no hace falta crear un registro por herramienta, que es justo el olvido que dio problemas con el simulador. Caddy obtiene los certificados igual que ahora.

---

## 4. laIA: qué es y qué no

**Primera versión (decidido):** el agente del homelab y de las herramientas del ecosistema. Nace usando el Dashboard por MCP y crece con cada herramienta nueva. El nombre nace de Atala**IA**.

| Su razón de existir | Donde siempre perdería |
|---|---|
| Conoce **tu contexto**: tu homelab, tus proyectos, tus notas | Asistente general de preguntas y respuestas |
| Usa **tus herramientas** por MCP | Calidad del modelo (usa Claude por debajo) |
| Está en **tus terminales**: voz en casa, Echo Show, móvil | Generar imágenes, navegar por internet |
| **Te avisa** por iniciativa propia, con los eventos del ecosistema | Ser una interfaz de chat más bonita |

Componentes:

- **Bucle de agente** sobre la interfaz propia `ProveedorLLM`: SDK de Anthropic por debajo, sin LiteLLM ni LangChain. Modelo pequeño (Haiku) por defecto y configurable; las evals dicen si basta. Más adelante, router por sensibilidad hacia un modelo local.
- **Cliente MCP** que carga los servidores del ecosistema desde una configuración.
- **Historial de conversaciones**: SQLite al principio; pasa al Cerebro cuando exista.
- **Interfaz de chat web** en TypeScript + Preact. El kit de UI se extrae aquí, porque ya hay dos frontends.
- **Voz** (fase 4): graba en el navegador, transcribe con el servicio de voz y responde con Piper. **El botón de hablar del Echo llama a laIA**, no al Dashboard.
- **Evals**: preguntas en español sobre estados fijos del sistema; se mide qué herramientas llama y con qué argumentos, e incluyen casos de inyección de prompt (un log que dice "ignora tus instrucciones"). Detalle en `atalaia-proyecto-portfolio.md`, sección 7.4.
- **Trazas desde el primer día**: cada llamada al LLM se registra con coste, latencia y herramientas usadas. Es la base del futuro Laboratorio y lo que no se registra no se puede recuperar.

**Relación con el Dashboard:** el Dashboard v1 **no tiene IA** (cumple el principio de funcionar sin ella). El diagnóstico de fallos con IA ("el despliegue falló porque...") se le añade cuando exista `paquetes/llm`, después de laIA.

---

## 5. Organización del código: monorepo

**Un único repositorio público, `DAAF292/atalaia`**, con todas las herramientas. Un monorepo es un solo repositorio con varios proyectos dentro, cada uno con su código, sus tests y su despliegue, pero compartiendo herramientas, CI y librerías.

| | Monorepo (elegido) | Un repo por herramienta |
|---|---|---|
| Para el CV | Un enlace y un README con el mapa del ecosistema | Atención repartida |
| Contratos compartidos | La CI comprueba a la vez a todos los que los usan | Publicar el paquete y actualizar cada repo |
| Coste | La CI solo prueba lo que cambia (filtros por ruta) | Más simple al principio |
| Despliegue independiente | Sí, una imagen por herramienta | Sí |

```
atalaia/
├── apps/
│   ├── dashboard/          # backend FastAPI + frontend Preact + servidor MCP
│   └── laia/               # agente, cliente MCP, chat web
├── servicios/
│   └── voz/                # Whisper + Piper como API HTTP (LXC "ai"), desde la fase 4
├── paquetes/
│   ├── contratos/          # modelos Pydantic de eventos y APIs + tipos TS generados
│   ├── llm/                # ProveedorLLM (se extrae con laIA)
│   └── ui/                 # kit de componentes Preact (se extrae con el 2.º frontend)
├── despliegue/             # Compose por herramienta, fragmentos de Caddy, deploy.sh
├── docs/
│   ├── vision.md           # visión y hoja de ruta (de este conjunto de documentos)
│   ├── ecosistema.md       # el mapa vivo: qué existe, en qué estado, cómo se comunica
│   ├── metodo.md           # método de trabajo
│   ├── diario.md           # diario de aprendizaje y problemas
│   └── adr/                # decisiones de arquitectura
├── CLAUDE.md               # reglas para los Claude que trabajen en el repo (tutor, núcleo)
└── .github/workflows/      # CI con filtros por ruta
```

- **Herramientas del monorepo:** espacios de trabajo de `uv` (Python) y `pnpm` (TypeScript), más un `justfile` con las órdenes comunes. Sin Nx ni Turborepo: con dos o tres herramientas no compensan.
- **Convención de nombres (decidido: todo en español):** carpetas, módulos, clases, funciones, variables, rutas de la API y eventos en español (`Recolector`, `ProveedorLLM`, `/kiosco`, `vm.parada`). Se quedan en inglés solo los nombres que imponen librerías o estándares (`/healthz`, `/metrics`, campos de APIs externas) y las palabras sin traducción habitual (`apps`, `token`).

---

## 6. Reglas de crecimiento

### Definición de terminado de una herramienta (versión 1)

1. **Desplegada** en el homelab y en uso.
2. **Modo demo** que funciona con datos simulados, sin tu infraestructura ni tus claves.
3. **Tests en la CI** y, si usa IA, **evals** con su resultado publicado.
4. Su sección en el README con GIF o captura, y sus **ADR** escritos por ti.
5. Su **servidor MCP** y sus **eventos** con los contratos comunes, si aplica.
6. Una entrada en `docs/diario.md` con lo aprendido.

### Filtro para aceptar una herramienta nueva

1. ¿La usarías al menos cada semana?
2. ¿Demuestra algo que el ecosistema todavía no demuestra?
3. ¿Se integra con lo que ya hay (MCP, eventos, Cerebro)? Si no, es otro proyecto.
4. ¿Tiene datos e interfaz propios? Si no, es una función de otra herramienta.

---

## 7. Fase 0: cimientos

| Pieza | Quién la hace |
|---|---|
| Estructura de carpetas, configuración de `uv`, `pnpm`, `ruff`, ESLint, TypeScript estricto, plantilla de PR | La IA (accesorio) |
| `CLAUDE.md` con las reglas de tutor y las carpetas del núcleo | La IA, revisado por Diego |
| Copiar estos documentos a `docs/` | La IA |
| **Primer workflow de GitHub Actions** (lint, tipos, tests, gitleaks) | **Diego**, con la teoría delante |
| **README inicial** y **primer ADR** (por qué un monorepo) | **Diego** |
| `paquetes/contratos` con el sobre de eventos | **Diego** (es diseño) |

---

## 8. Cómo se cuenta en el CV y en la entrevista

Borrador para cuando estén terminados el Dashboard y laIA (**no poner números sin medir**):

> **AtalaIA**: ecosistema personal de herramientas con IA, autoalojado · github.com/DAAF292/atalaia
> - **Arquitectura**: monorepo de servicios independientes (Python/FastAPI, TypeScript/Preact) integrados mediante **MCP** y eventos con contratos compartidos; identidad centralizada con forward auth.
> - **AtalaIA Dashboard**: observabilidad en tiempo real (SSE) del homelab, con motor de eventos y servidor MCP de solo lectura; funcionando en un Echo Show reciclado con LineageOS.
> - **laIA**: agente LLM (Claude, tool calling vía MCP), validado con evals propias (X % de herramienta correcta) y con trazas de coste y latencia.

| Pregunta probable | Respuesta corta |
|---|---|
| ¿Por qué MCP y no llamar a las APIs? | Desacopla el agente de las herramientas: añadir una no toca laIA, y sirven también a otros clientes como Claude Code |
| ¿Por qué no Kubernetes? | Servicios independientes, pero un solo nodo y una persona: Docker Compose basta |
| ¿Por qué no hay broker? | El sobre de eventos ya es común y el broker se puede añadir sin cambiar productores; lo añadiré cuando dos consumidores necesiten entrega garantizada |
| ¿Por qué monorepo? | Contratos verificados en cada cambio, un punto de entrada y despliegues independientes |
| ¿Cómo evitas que el agente haga algo peligroso? | Solo lectura por defecto, escritura con confirmación, evals con inyección de prompt |
