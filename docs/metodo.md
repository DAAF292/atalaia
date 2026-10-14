# AtalaIA: método de trabajo (aprender construyendo)

Fecha: 2026-10-11 (revisado el mismo día). **Documento vigente.** Diego lo planteó así:

> Este será mi proyecto personal que lo englobará todo. Tiene que mejorarme la vida y además darme el marco práctico y teórico para mejorar al máximo como profesional. Así que hay que enfocarlo paso a paso, no que la IA pique todo el código: lo irrelevante lo pica la IA, pero lo importante debo hacerlo yo.

Esto cambia la forma de trabajar respecto a lo que se hizo con el simulador (donde el Claude de `dev` implementaba y el del proyecto revisaba). **En AtalaIA, tú eres quien programa lo importante, y la IA hace de profesor, revisor y ayudante para lo accesorio.**

---

## 1. Opinión sincera

Es la decisión correcta, y no solo por aprender. **En una entrevista te van a preguntar por cualquier línea del repo**, y si la escribió una IA se nota en dos preguntas. Un proyecto donde puedes explicar cada decisión vale más que uno el doble de grande que no sabrías defender.

El coste también hay que verlo de frente: **irá bastante más lento**. Programar tú, con revisión y correcciones, puede multiplicar por dos o por tres el tiempo de cada fase frente a dejar que la IA lo haga todo. Con el objetivo de llegar a primavera con algo enseñable, eso refuerza lo que ya habíamos dicho: **Dashboard y laIA, muy bien hechos y entendidos**, antes que cualquier otra cosa.

Y un riesgo sutil: **la IA disponible a todas horas tienta a pedir la solución** al primer atasco. Atascarse un rato es justo donde se aprende. Por eso el método tiene niveles de ayuda (sección 4).

---

## 2. Qué haces tú y qué hace la IA

Dos reglas para decidirlo, en caso de duda:

1. **Si no sabrías explicarlo en una entrevista, lo escribes tú.**
2. **Lo primero de cada tipo lo haces tú; las repeticiones, la IA.** El primer adaptador contra una API lo escribes tú; el cuarto, que es igual que los tres anteriores, lo puede escribir la IA y tú lo revisas.

| Lo haces tú (núcleo y aprendizaje) | Lo haces tú con revisión de la IA | Lo hace la IA y tú lo revisas (accesorio) |
|---|---|---|
| Modelos del dominio (la "foto" del sistema, los eventos) | El segundo y siguientes adaptadores de un mismo tipo | Configuración de herramientas: `ruff`, `tsconfig`, ESLint, `pyproject` |
| Motor de eventos y su lógica | Componentes de interfaz que repiten un patrón ya hecho | Estilos CSS de detalle, iconos, maquetación fina |
| Primer adaptador de cada fuente (Proxmox, Docker...) | Ampliar tests siguiendo casos que ya escribiste tú | Datos falsos y escenarios del modo demo |
| Endpoints, SSE y contratos de la API | Optimizaciones que tú detectas y la IA propone | Tipos generados, scripts de pegamento, `justfile` |
| Bucle del agente de laIA, tool calling, cliente y servidor MCP (el primero) | | Formato y redacción final del README (el contenido es tuyo) |
| Esquema de base de datos y migraciones | | Plantillas repetitivas (un endpoint CRUD más, igual a otros) |
| Estado del frontend (store, signals) y componentes clave | | |
| Autenticación, seguridad y modelo de amenazas | | |
| El primer Dockerfile, el primer pipeline de CI, el primer despliegue | | |
| Tests del núcleo (los escribes tú: pensar los casos es la mitad del diseño) | | |
| **Todos los ADR** (escribir la decisión es donde se aprende a decidir) | | |

**Los ADR siempre tuyos.** La IA puede discutir opciones contigo, pero el documento que dice "elegí esto por esto" lo escribes tú: es literalmente tu guion para la entrevista.

---

## 3. El ciclo de cada paso

Cada fase de la hoja de ruta se divide en pasos pequeños (de una o dos sesiones de trabajo). Cada paso sigue este ciclo:

```
1. Teoría        → 2. Especificación   → 3. Implementas  → 4. Revisión  → 5. Corriges  → 6. Cierras
   (qué y por qué)   (qué debe cumplir)    (tú)              (la IA,        (tú)            (ADR, diario,
                                                              como senior)                  merge)
```

1. **Teoría.** Antes de programar algo nuevo, una explicación breve desde cero del concepto (con analogías de lo que ya conoces) y **enlaces a la documentación oficial**, que es lo que tendrás que aprender a leer. No tutoriales de terceros.
2. **Especificación.** Qué tiene que hacer el paso, con **criterios de aceptación** concretos ("si una VM pasa de `running` a `stopped`, se genera exactamente un evento `vm.parada`"). Para pasos con lógica, a veces con algunos tests ya escritos como contrato, y el resto los escribes tú.
3. **Implementas.** Tú, en tu rama, en `dev` o en tu PC.
4. **Revisión.** Abres un pull request y la IA lo revisa **como lo haría un senior exigente**: errores, diseño, legibilidad, casos que no cubren los tests, cosas que te preguntarían en una entrevista. **La revisión señala, no arregla**: no te devuelve el código corregido.
5. **Corriges.** Tú. Si no estás de acuerdo con un comentario, lo discutes: defender una decisión ante una revisión es otra habilidad profesional.
6. **Cierras.** Merge, una línea en `docs/diario.md` (qué aprendiste, qué te costó) y, si hubo una decisión de diseño, su ADR.

Trabajar con pull requests aunque estés solo no es burocracia: es exactamente el flujo de cualquier empresa, y el historial de PRs con revisiones también se ve en tu GitHub.

---

## 3b. Estándar de la teoría (añadido 2026-10-14)

Diego lo dejó claro: **este proyecto es una forma de aprender, así que la teoría tiene que servir para lograr los fines que nos marcamos** (entender las tecnologías más demandadas y poder defender cada decisión en una entrevista), no ser un trámite previo al código. Todo documento de teoría de `docs/teoria/` cumple esto:

1. **Objetivo de aprendizaje**: al terminar, ¿qué sabrás hacer y explicar? Redactado como capacidades comprobables, no como temas.
2. **Por qué importa**: dónde aparece esto en el trabajo real y qué pregunta de entrevista responde.
3. **El concepto desde cero**, con analogía de lo que Diego ya conoce (desarrollo web).
4. **Ejemplo análogo**: la estructura en un caso distinto del suyo, comentado. Nunca su solución.
5. **Errores típicos y cómo se diagnostican.**
6. **Comprobación de comprensión**: preguntas que debe poder contestar con sus palabras, sin mirar, antes y después de implementar. Si no puede, la teoría no ha cumplido.
7. **Documentación oficial** de cada tecnología, para aprender a leerla.
8. **Conexión con el proyecto**: cómo esto encaja en AtalaIA y en su portfolio.

La teoría se mide por lo que Diego es capaz de explicar y construir después, no por su extensión. Si tras leerla no puede ni plantear una pregunta concreta, está mal escrita y se rehace.

---

## 4. Niveles de ayuda cuando te atascas

Cuando pidas ayuda en algo que te toca a ti, se sube de nivel solo si el anterior no basta:

1. **Pregunta guía:** "¿qué pasa con la foto anterior la primera vez que arranca el sistema?".
2. **Pista conceptual:** "esto es un problema de comparar dos diccionarios por clave; mira qué te da un `set` de las claves".
3. **Explicación con ejemplo análogo:** el mismo concepto resuelto en un caso parecido, no el tuyo.
4. **Fragmento concreto:** solo la parte en la que estás bloqueado.
5. **Solución completa:** solo si la pides de forma explícita ("dame la solución"), y entonces la lees, la entiendes y la reescribes tú sin mirar.

Por defecto se empieza en el nivel 1. Si en algún momento prefieres ir más rápido en un paso concreto, basta con decirlo.

---

## 5. Quién hace qué entre los Claude

- **Aquí, en el proyecto:** diseño, teoría, especificación de cada paso, revisión de tus PRs y seguimiento de la hoja de ruta.
- **El Claude Code de la VM `dev`:** ayudante en el editor, pero **configurado como tutor**. El repo llevará un `CLAUDE.md` (las instrucciones que Claude Code lee siempre al trabajar en un repo) con estas reglas: no escribir código en las partes marcadas como núcleo, responder con los niveles de ayuda de la sección 4, y sí encargarse libremente de lo accesorio. Así la regla no depende de que te acuerdes de pedirlo cada vez.
- **Marcado del código:** las carpetas del núcleo se listan en ese `CLAUDE.md` (por ejemplo `apps/dashboard/backend/dominio/`), para que quede claro dónde puede escribir la IA y dónde no.

---

## 6. Cómo se aplica a la fase 0 y al primer paso

El reparto concreto de la fase 0 está en `atalaia-ecosistema.md`, sección 7. En resumen:

- **IA:** estructura de carpetas, configuración de `uv`, `pnpm`, `ruff`, ESLint, TypeScript, plantilla de PR, `CLAUDE.md` y copiar estos documentos a `docs/`.
- **Tú, con teoría previa:** el **primer workflow de GitHub Actions** (qué es una CI, cómo se escribe un workflow, por qué cada paso), el `README` inicial, el **primer ADR** (por qué un monorepo) y el sobre de eventos de `paquetes/contratos`.
- **Primer paso de la fase 1 que harás tú entero:** el modelo de la "foto" del sistema y el motor de eventos con sus tests. Es pequeño, es pura lógica, no depende de ninguna infraestructura y es la pieza que más vas a enseñar en una entrevista.

## 7. Dónde vive este método

Cuando exista el repo, este documento pasa a `docs/metodo.md` y sus reglas operativas se resumen en el `CLAUDE.md` de la raíz, que es lo que lee cualquier Claude que trabaje en el repo.
