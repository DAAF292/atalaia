# AtalaIA: visión, herramientas y hoja de ruta

Versión consolidada: 2026-10-11. **Documento vigente** para qué es AtalaIA, qué herramientas tiene y en qué orden se construyen. La arquitectura técnica está en `atalaia-ecosistema.md`, el método de trabajo en `atalaia-metodo-de-trabajo.md` y el diseño detallado del Dashboard en `atalaia-proyecto-portfolio.md`. El registro de todas las decisiones está en `atalaia-traspaso-proyecto-nuevo.md`.

---

## 1. Qué es AtalaIA

En palabras de Diego (2026-10-11):

> Mi ecosistema personal: herramientas que me faciliten la vida, en mis desarrollos como profesional y en el día a día. Un asistente personal llevado a su máximo exponente. Proyecto a largo plazo, una herramienta cada vez y terminada, que sirva para el CV, me facilite la vida laboral y personal y me sirva para aprender las tecnologías más punteras y demandadas.

En una frase:

> **AtalaIA** es un ecosistema personal y autoalojado de herramientas que se comunican entre sí, con **laIA** como agente que las une, y que integra la IA de forma práctica allí donde aporta valor.

### Los tres objetivos, y cómo se equilibran

| Objetivo | Qué exige | Qué pasa si se descuida |
|---|---|---|
| **Mejorarte la vida** | Herramientas que uses de verdad cada semana | Un proyecto que no usas se abandona |
| **Aprender y crecer como profesional** | Que tú programes lo importante (`atalaia-metodo-de-trabajo.md`) y que cada herramienta enseñe algo nuevo (sección 6) | Un repo que no sabrías defender en una entrevista |
| **Servir de portfolio** | Herramientas terminadas, demostrables y documentadas | Diez herramientas a medias, que restan más que suman |

### Principios (decididos)

1. **La IA es un ingrediente, no el producto** (Diego, 2026-10-11): *"lo interesante es aportar valor a lo que sirve integrando la IA de forma práctica"*.
   - Cada herramienta resuelve un problema real y **funciona sin IA**.
   - La IA entra en un punto concreto donde ahorra trabajo o lo hace posible: leer lo que no tienes tiempo de leer, convertir lenguaje natural en datos, explicar, resumir.
   - Si en una herramienta la IA no aporta, no se mete.
2. **Una herramienta cada vez, y terminada** antes de empezar la siguiente (definición de terminado en `atalaia-ecosistema.md`, sección 6).
3. **Tuyo por dentro, estándares hacia fuera.** Los datos y la lógica son de AtalaIA (calendario y notas propios incluidos), pero se habla en formatos estándar (iCalendar, Markdown, OpenAPI, MCP) para no quedar aislado y poder sacar siempre tus datos.
4. **Tus datos son privados aunque el código sea público.** El repo es público; los datos reales nunca entran en él. Para enseñarlo existe el **modo demo** con datos inventados.
5. **Lo importante lo programas tú.** La IA enseña, especifica, revisa y hace lo accesorio.

---

## 2. Opinión sincera sobre la visión

**Es buena y coherente**, y tiene una ventaja que casi ningún proyecto de portfolio tiene: **la vas a usar tú todos los días**. Eso lo mantiene vivo y te da historias reales para una entrevista. Pero conviene tener presentes cuatro cosas:

1. **El alcance es de años.** Está bien asumirlo, siempre que se respete el principio 2. La referencia práctica: **lo que esté terminado en primavera de 2027 es lo que irá al CV** (Diego seguirá en su puesto al menos hasta el verano de 2027). Siendo realistas, con el método de aprender programando, eso serán **el Dashboard y laIA, muy bien hechos**.
2. **Guardar tu vida cambia las prioridades.** En cuanto AtalaIA guarde notas, agenda o lecturas, perder el disco del GEEKOM significa perder años de datos. **Sin copias verificadas no se guarda nada personal.**
3. **La privacidad es una decisión de diseño** (sección 5): qué puede ir a la API de Claude y qué no.
4. **Construir en vez de integrar tiene un coste.** Calendario y notas propios son una decisión tuya y razonable, pero un calendario es un problema difícil (repeticiones, zonas horarias, sincronización). Por eso Notas va antes que Agenda.

---

## 3. Mapa del ecosistema

```
 TERMINALES     Echo Show (kiosco) · Web · App móvil (Android) · Claude Code/Desktop (vía MCP)
 ─────────────────────────────────────────────┬─────────────────────────────────────────────
 AGENTE                                     laIA
                     (conversa, decide qué herramienta usar, texto y voz, te avisa)
 ─────────────────────────────────────────────┬─────────────────────────────────────────────
 HERRAMIENTAS   Trabajo y homelab           Día a día                 Conocimiento
                ─────────────────           ─────────                 ────────────
                Dashboard                   Notas                     Bitácora
                Copias                      Agenda                    Conocimiento
                Vigía                       Finanzas*                 Rumbo*
                Laboratorio*                Archivo*
 ─────────────────────────────────────────────┬─────────────────────────────────────────────
 DATOS          Cerebro: memoria personal común (PostgreSQL + pgvector)
 ─────────────────────────────────────────────┬─────────────────────────────────────────────
 PLATAFORMA     Voz (Whisper + Piper) · Avisos · Proveedor de LLM (router de privacidad)
                · Contratos · Kit de UI · Identidad (Authelia, OIDC)
                                                              * candidatas, sin fecha
```

### El Cerebro: la memoria común

Notas, Agenda, Bitácora y laIA hablan de las mismas cosas: una nota de voz menciona un libro de la Bitácora y una tecnología que estudias. Si cada herramienta guarda lo suyo por separado, nadie puede cruzarlo y el "asistente al máximo exponente" no existe.

- **Qué es:** **PostgreSQL con la extensión pgvector**. PostgreSQL guarda los datos en tablas, como cualquier base de datos relacional que conozcas; **pgvector** añade un tipo de columna para guardar *embeddings*, la "huella de significado" de un texto convertida en números. Así puedes buscar "notas sobre aprender Rust" y encontrar una que dice "quiero probar el lenguaje de Mozilla", aunque no compartan ninguna palabra.
- **Qué guarda:** entidades con tipo (nota, tarea, evento, recordatorio, libro, película, tema, tecnología, proyecto) y **enlaces entre ellas**, con su texto y su embedding.
- **Quién lo usa:** cada herramienta escribe en **sus propias tablas** a través de su API; laIA consulta por MCP. Nadie escribe en las tablas de otro.
- **Cuándo nace:** con Notas (fase 4). El Dashboard sigue con SQLite: un solo proceso escribe y no necesita más.
- **Descartado:** Neo4j (los enlaces caben en una tabla de relaciones, y a tu escala no notarías la diferencia); una base vectorial aparte como Qdrant o Chroma (con pgvector los datos y los vectores están juntos, con transacciones y una sola copia de seguridad); usar Obsidian como base de datos (es bueno para escribir, no para que varios servicios escriban datos estructurados).

---

## 4. Las herramientas

### 4.1 Catálogo completo

Criterio para que algo sea herramienta: **tiene sus propios datos y su propia interfaz**. Si solo combina datos de otras, es una función de laIA o de la herramienta dueña de esos datos.

| Herramienta | Problema que resuelve (sin IA) | Dónde entra la IA | Se conecta con | Estado |
|---|---|---|---|---|
| **Dashboard** | Ver el estado del homelab sin ir a mirarlo | Diagnóstico de fallos: lee los logs y propone la causa probable (se añade cuando exista laIA) | laIA, Avisos, Vigía (le da el inventario de versiones) | Fase 1 |
| **laIA** | Un único punto de entrada, por texto o voz, a todo el ecosistema | Es el agente: entiende, decide qué herramienta usar y combina resultados | Todas, por MCP | Fase 2 |
| **Copias** | Hacer copias de los datos de AtalaIA (el Cerebro, las bases SQLite) y **comprobar que se pueden restaurar**, con su estado visible en el Dashboard | Poca: explicar un fallo en lenguaje claro. Es la herramienta que demuestra que no todo necesita IA | Dashboard, Avisos | Fase 3 |
| **Notas** | Notas propias en Markdown, enlazadas entre sí, con tareas y listas | Formatear notas de voz (título, resumen, tareas detectadas, etiquetas y enlaces); convertir "apúntame revisar el backup el sábado" en una tarea con fecha | Agenda, Bitácora, laIA | Fase 4 |
| **Agenda** | Calendario propio con eventos, repeticiones y recordatorios | Crear eventos desde lenguaje natural ("el jueves a las 5 reunión con Marta, recuérdamelo una hora antes"); resumen del día por la mañana en el Echo | Notas, Avisos, laIA | Fase 4b |
| **Bitácora** | Registro de libros, películas y series, temas de interés, investigaciones y tecnologías que estudias | Captura por voz o foto de la portada; conexiones ("estudias arquitectura hexagonal y hace un año leíste un libro que la explica") | Notas, Conocimiento, Rumbo | Fase 6 |
| **Vigía** | Actualizaciones y vulnerabilidades (CVE) de lo que tienes instalado, y novedades de los temas que te interesan | Lee changelogs y avisos y te dice **si te afectan y qué hacer**, en dos líneas | Dashboard (versiones), Bitácora (intereses), Avisos | Fase 7 |
| **Conocimiento** | Buscar en tus notas, tus apuntes del máster y la documentación de tus proyectos | Búsqueda por significado con respuestas que citan la fuente (RAG); tarjetas de repaso | Notas, Bitácora, laIA | Fase 8 |
| **Rumbo** | Seguimiento de tu búsqueda de empleo: ofertas, candidaturas, contactos, entrevistas | Comparar cada oferta con tu perfil real (Bitácora + lo construido en AtalaIA), preparar entrevistas con tus propios ADR | Bitácora, Notas, Agenda | Candidata, después de Bitácora |
| **Finanzas** | Gastos y suscripciones a partir de los movimientos del banco (CSV) | Categorizar movimientos, leer tickets desde una foto, detectar suscripciones olvidadas | Agenda, Avisos | Candidata |
| **Laboratorio** | Ver qué hace la IA en todo el ecosistema: coste, latencia, herramientas usadas, errores; comparar modelos con las evals | Es la herramienta que **mide** la IA de las demás (LLMOps) | Todas las que usan LLM | Candidata; **las trazas se guardan desde la fase 2** |
| **Archivo** | Guardar y encontrar facturas, contratos, garantías | Extraer fechas e importes de un documento fotografiado ("la garantía vence en marzo" → recordatorio) | Agenda, Finanzas | Candidata (ojo: Paperless-ngx ya lo hace muy bien) |
| **Despliegues** | Generalizar `deploy.sh` en un servicio con historial e interfaz | Resumir qué cambia en cada despliegue y por qué falló | Dashboard, Avisos | Al final (primera que **ejecuta**) |
| **Agentes** | Supervisar las sesiones de Claude Code que trabajan en `dev` | Resumir qué hizo cada agente y si espera algo de ti | laIA, Avisos | Al final (la más delicada) |

**Piezas de plataforma** (no son herramientas, nacen cuando dos herramientas las necesitan):
- **Voz**: faster-whisper + Piper en el LXC "ai". Nace en la fase 4 con las notas de voz y da voz a laIA en el mismo momento.
- **Avisos**: decide cómo y dónde avisarte (voz en el Echo, notificación en el móvil, horario de silencio, sin repetir lo mismo diez veces). Nace en cuanto dos herramientas necesiten avisarte; previsiblemente entre las fases 4 y 5.
- **Móvil** (fase 5): más que una herramienta, es un terminal. Ver sección 4.4.

### 4.2 Funciones que no son herramientas

| Idea | Dónde va |
|---|---|
| Tareas pendientes | Notas (nota de tipo tarea, con fecha y recordatorio en Agenda). **Sustituye a la herramienta "Tareas" que se propuso antes** |
| Listas (la compra, etc.): "añade leche" al Echo | Notas (nota de tipo lista) |
| Diario personal | Notas (tipo diario) |
| Tarjetas de repaso con repetición espaciada (algoritmo FSRS) | Conocimiento |
| Revisión semanal y resumen de la mañana | laIA, cruzando Agenda, Notas, Bitácora y Dashboard |
| Radar tecnológico | Vigía |
| Observabilidad de la IA (trazas de cada llamada al LLM) | Plataforma desde la fase 2; Laboratorio le pone interfaz |

### 4.3 Descartado

| Idea | Por qué |
|---|---|
| Home Assistant | Competiría por la pantalla y el micro del Echo, y no tienes domótica |
| Palabra de activación ("oye laIA") | Lo más difícil, lo que menos aporta delante de una pantalla táctil, y supone un micro siempre escuchando |
| Uptime Kuma, Docker de `dev` como fuentes del Dashboard | Repiten el mismo patrón de recolector sin enseñar nada nuevo |
| Laya (modelo de decisión) | Descartado por Diego; unas reglas simples bastan para clasificar avisos |
| LiteLLM, LangChain | Una interfaz propia de ~150 líneas es más defendible y una dependencia menos |
| Kubernetes | Un nodo y una persona: Docker Compose basta |
| Personas (contactos) | Guardaría datos de terceros |
| Hábitos y salud | Sin un reloj o pulsera, el registro manual se abandona |
| Domótica | No hay dispositivos; si los hubiera, se integraría Home Assistant por MCP |
| Servidor CalDAV propio o Radicale | CalDAV es enorme; Radicale haría que la agenda dejara de ser "tuya" |
| Neo4j, base vectorial aparte | Ver el Cerebro |

### 4.4 Detalle de las herramientas nuevas

**Notas.**
- Markdown guardado en el Cerebro, con editor propio en web y móvil, etiquetas y enlaces al estilo Obsidian (`[[otra nota]]`).
- Las notas de voz, las tareas, las listas y el diario son **notas con tipo**: todo vive en el mismo sitio y se busca igual.
- **Obsidian (tu vault MasterIA):** al principio se **importa en un solo sentido** y Obsidian sigue funcionando igual. Más adelante decides si migras del todo. Exportar todo a Markdown tiene que ser siempre posible.
- **El problema difícil:** editar la misma nota sin conexión en el móvil y en el PC. Primera versión: historial de versiones y "gana la última escritura", avisando del conflicto. Más adelante, si hace falta, **CRDT** con Yjs. Un CRDT es una estructura de datos que permite fusionar solas dos copias editadas por separado, como un `git merge` que nunca falla. Es lo que usan Notion o Figma. Muy demandado y muy difícil: solo cuando duela.

**Agenda** (calendario propio, decidido por Diego).
- AtalaIA es la **fuente de verdad**: los eventos viven en el Cerebro y tienen interfaz propia.
- Modelo basado en el estándar **iCalendar (RFC 5545)**: fechas en UTC más la zona horaria del evento, y repeticiones como reglas `RRULE` ("cada martes hasta junio, salvo el día 12"). Las repeticiones se calculan con librerías probadas (`python-dateutil`, `icalendar`), **nunca a mano**: zonas horarias, cambios de hora y excepciones son una fuente clásica de bugs, y por eso mismo es una pregunta de entrevista excelente.
- **Salidas estándar:** enlace `.ics` de suscripción (solo lectura, con token secreto) para ver la agenda en el calendario del móvil; importar `.ics` cuando te llegue una invitación; más adelante, enviar invitaciones por correo con un `.ics` adjunto.
- Recordatorios propios a través de Avisos.
- Crear o mover eventos desde laIA **siempre con confirmación**.

**Bitácora.**
- Fichas con estado (pendiente, en curso, terminado), valoración, notas y fechas. Metadatos de servicios abiertos: **Open Library** (libros) y **TMDB** (películas y series).
- Sin la IA y el Cerebro sería un proyecto de bootcamp; con ellos enseña modelado de datos, integración con APIs y búsqueda híbrida.
- Extra para el CV: como registra las tecnologías que estudias, al cabo de un año AtalaIA puede generarte la lista de lo aprendido, con fechas y con dónde lo aplicaste.

**Móvil.**

| Opción | Veredicto |
|---|---|
| **PWA** (las webs del ecosistema instalables) | **Primer paso**: casi gratis y con notificaciones en Android |
| **React Native + Expo** | **La app de verdad**: mismo TypeScript, mismos tipos generados, acceso nativo (widget de nota rápida, "compartir con AtalaIA", sin conexión). Muy demandado |
| Flutter, Kotlin nativo | Descartados: no reaprovechan nada de tu stack |

- Acceso desde fuera por **Tailscale**; nada expuesto a internet.
- Inicio de sesión con **OIDC + PKCE** usando Authelia como proveedor: el flujo estándar de las apps móviles.
- Funciones: Dashboard, hablar con laIA, captura rápida de notas de voz, compartir enlaces desde otras apps, notificaciones de Avisos y cola sin conexión.

**Copias: dónde está la frontera con el homelab.**
- La **copia del host Proxmox** (VMs completas a un disco USB o a Proxmox Backup Server) es **infraestructura**: se hace en el proyecto HomeLab y **no debe esperar a AtalaIA**. Lleva pendiente desde el principio y hoy ya hay trabajo que perder.
- **AtalaIA Copias** se ocupa de lo que es del ecosistema: copias de los datos de AtalaIA (volcados del Cerebro, bases SQLite), **pruebas de restauración automáticas** y el estado de todas las copias (incluidas las del host) visible en el Dashboard y en Avisos.

---

## 5. Privacidad: qué puede salir de casa

| Dato | ¿Puede ir a la API de Claude? | Si no, dónde se procesa |
|---|---|---|
| Estado técnico del homelab, logs, changelogs | Sí | — |
| Audio | **Nunca** (decidido) | Whisper local |
| Notas, agenda y lecturas | **Pendiente de decidir** (recomendación abajo) | LLM local para lo marcado como privado |
| Embeddings del Cerebro | No hace falta | Modelo de embeddings local (pequeño) |
| Finanzas, documentos personales | Recomendado: no | LLM local |

**Diseño:** la interfaz `ProveedorLLM` lleva en cada petición una **etiqueta de sensibilidad** y actúa como router: lo público va a Claude y lo privado a un modelo local cuando exista. Se puede empezar con todo en Claude y mover cosas a local sin tocar las herramientas.

**Recomendación para la decisión pendiente:** empezar con Claude enviando **solo el fragmento necesario** de cada petición (nunca el Cerebro entero), etiquetar la sensibilidad desde el primer día y pasar lo privado a local cuando tengas los 32 GB de RAM (`ia-local-32gb.md`). La decisión no hace falta hasta la fase 4.

---

## 6. Qué aprendes con cada fase

Cada herramienta debe enseñar algo **nuevo y demandado**, sin repetir.

| Fase | Tecnologías nuevas | Demanda (2026) |
|---|---|---|
| 0 Cimientos | Monorepo (uv, pnpm), GitHub Actions, linters y tipado estricto | Alta |
| 1 Dashboard | FastAPI, SSE, Preact + TypeScript, tipos desde OpenAPI, Docker, testing por capas, **servidor MCP** | Alta: la base de cualquier FullStack |
| 2 laIA | Agentes con tool calling, **cliente MCP**, **evals**, streaming, trazas de LLM (OpenTelemetry) | Muy alta |
| 3 Copias | restic, automatización, pruebas de restauración, gestión de secretos | Alta en plataforma y DevOps |
| 4 Voz + Notas | **PostgreSQL + pgvector**, **structured outputs**, voz en producción, editor de Markdown | Muy alta |
| 4b Agenda | Modelado temporal (RRULE, zonas horarias), estándares (iCalendar) | Media, pero muy valorada en entrevista |
| 5 Móvil | **React Native + Expo**, OIDC + PKCE, notificaciones, sin conexión y sincronización | Muy alta |
| 6 Bitácora | Modelado de datos rico, APIs externas, **búsqueda híbrida** | Alta |
| 7 Vigía | Integración con varias APIs, tareas programadas, SBOM (inventario de dependencias) | Alta |
| 8 Conocimiento | **RAG** completo: troceado, embeddings locales, reranking, evals de recuperación | Muy alta |
| Plataforma | LLM local (llama.cpp, cuantización, router de modelos) | Alta y creciendo |

---

## 7. Hoja de ruta

| # | Qué | Por qué en este lugar |
|---|---|---|
| — | **Copia del host Proxmox** (proyecto HomeLab) | **Ya**, sin esperar a AtalaIA |
| 0 | **Cimientos** del monorepo | La base de todo |
| 1 | **Dashboard** + su servidor MCP + kiosco en el Echo | Diseño hecho, sin datos personales, primer subproyecto terminado |
| 2 | **laIA** por texto (+ trazas desde el primer día) | El agente que une todo; nace usando el Dashboard |
| 3 | **Copias** | Antes de guardar ningún dato personal |
| 4 | **Voz** + **Notas** (nace el Cerebro) | La de más uso diario; laIA gana voz al mismo tiempo |
| 4b | **Agenda** | Más difícil que Notas, por eso después |
| 5 | **Móvil**: PWA y después Expo | Notas y Agenda sin captura en el móvil se quedan a medias |
| 6 | **Bitácora** | Sobre el Cerebro ya existente |
| 7 | **Vigía** | Puede adelantarse si te apetece más; es pequeña y de solo lectura |
| 8 | **Conocimiento** | RAG con el Cerebro y los embeddings ya montados |
| Después | Rumbo, Finanzas, Laboratorio (interfaz), Archivo, Despliegues, Agentes | Pasando siempre el filtro de `atalaia-ecosistema.md` (sección 6) |
| Cuando toque | LLM local | Cuando haya datos privados que no deban salir y tengas los 32 GB |

**Hito de primavera de 2027:** Dashboard y laIA terminados según la definición de terminado. Todo lo demás es ganancia.

---

## 8. Cómo se cuenta en el CV

Una sola entrada, **AtalaIA**, con una viñeta por herramienta **terminada** (nunca por las planificadas). La frase de cabecera, cuando el ecosistema haya crecido:

> Ecosistema personal autoalojado que integra la IA de forma práctica en herramientas de uso diario, con una memoria común (PostgreSQL + pgvector), un agente que las orquesta por MCP, app móvil en React Native y procesamiento local de los datos sensibles.

El borrador concreto para la primera versión (Dashboard + laIA) está en `atalaia-ecosistema.md`, sección 8.

---

## 9. Decisiones pendientes de Diego

1. **¿Pueden tus notas, agenda y lecturas ir a la API de Claude?** No hace falta hasta la fase 4. Recomendación en la sección 5.
