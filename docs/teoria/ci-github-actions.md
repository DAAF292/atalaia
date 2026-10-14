# Tu primer workflow de CI: teoría, ejemplos y especificación

Este paso lo escribes **tú**. Aquí tienes (1) los conceptos desde cero, (2) ejemplos **de un proyecto distinto** para que veas la estructura sin que sea tu solución, (3) qué hace cada herramienta que vas a ejecutar y (4) la especificación con criterios de aceptación.

> Versión 2 (2026-10-14). La primera era una lista de ideas sin explicar las tecnologías ni mostrar código. Esta lo corrige.

## 0. Para qué sirve este paso (objetivos de aprendizaje)

Al terminar este paso deberías poder, **sin mirar el material**:

1. Explicar con tus palabras qué es la CI, qué problema resuelve y por qué un runner "nace vacío".
2. Escribir y depurar un workflow con `on`, `jobs`, `steps`, `uses`, `run`, `needs` y `permissions`, y leer una ejecución fallida.
3. Razonar y defender tus decisiones de diseño: un job o varios, versiones fijadas, permisos mínimos, `just ci` frente a comandos sueltos.
4. Explicar por qué gitleaks está en la CI de un repo público.

**Por qué importa en el mercado**: CI/CD es un requisito en casi cualquier oferta FullStack; saber montar un pipeline y razonar su seguridad (permisos, cadena de suministro) es de las cosas que más separan a un perfil que solo programa de uno que entrega.

**Preguntas de entrevista que este paso te permite contestar**
- ¿Qué pasa desde que haces `git push` hasta que ves el check verde en un PR?
- ¿Por qué fijarías una acción por hash de commit en lugar de `@v4`?
- ¿Cómo evitas que la CI y tu entorno local se desincronicen?
- ¿Cómo sabes que tu CI no es decorativa?

**Autoevaluación antes de empezar** (contesta por escrito en 1-2 líneas cada una, y dime las que no sepas): ¿qué es un runner? ¿por qué hay que hacer `checkout` en cada job? ¿qué diferencia hay entre `run` y `uses`? ¿qué hace que un job falle? Repite la lista al terminar: la diferencia es lo que has aprendido, y va a `docs/diario.md`.

Documentación oficial de partida: https://docs.github.com/en/actions

---

## 1. El problema que resuelve una CI

Hoy, para saber si tu código está bien, ejecutas en tu portátil `npm run lint`, `npm test`... y confías en acordarte de hacerlo. Eso falla por tres motivos:

1. **Se te olvida** (o lo haces a medias con prisa).
2. **"En mi máquina funciona"**: tu portátil tiene versiones, ficheros y variables que el repo no incluye.
3. **Nadie más puede fiarse**: quien revise tu PR no sabe si pasaste las comprobaciones.

**Integración continua (CI)** = un servidor limpio que, cada vez que se propone un cambio, ejecuta siempre las mismas comprobaciones y publica un resultado verde ✅ o rojo ❌ en el PR. Es el mismo `npm test` de siempre, pero ejecutado por una máquina nueva, de forma automática y visible para todos.

La CI de GitHub se llama **GitHub Actions** y es gratuita para repos públicos.

## 2. Imprescindible: lo mínimo de YAML

Un workflow es un fichero YAML. YAML es un formato de datos como JSON, pero con sangría en lugar de llaves. Tres reglas:

```yaml
# Esto es un comentario
clave: valor                 # par clave-valor (como {"clave": "valor"})
lista:                       # lista: cada elemento empieza con "- "
  - uno
  - dos
objeto:                      # objeto anidado: se indica con la sangría (2 espacios)
  campo: 1
  otro: true
```

El mismo contenido en JSON sería `{"clave":"valor","lista":["uno","dos"],"objeto":{"campo":1,"otro":true}}`. Errores típicos: mezclar tabuladores (solo espacios), una sangría mal alineada (cambia el significado, no da error visible) y olvidar entrecomillar valores con `:` o que parecen otro tipo (`"3.10"` ≠ `3.10`, que se lee como número).

## 3. El modelo mental de GitHub Actions

```
 evento (push / PR)
        │
        ▼
 ┌─ workflow (un fichero .yml) ───────────────────────────────┐
 │                                                              │
 │  job "lint"  ──► runner (máquina virtual nueva)              │
 │     step 1: descargar el código                              │
 │     step 2: instalar herramientas                            │
 │     step 3: ejecutar el comando                              │
 │                                                              │
 │  job "tests" ──► OTRA máquina virtual nueva (en paralelo)    │
 │     step 1 ...                                               │
 └──────────────────────────────────────────────────────────────┘
```

| Término | Qué es | Analogía de desarrollo web |
|---|---|---|
| **Workflow** | Un fichero en `.github/workflows/*.yml`. Puede haber varios | Un script de `package.json` con nombre y disparador |
| **Evento** (`on:`) | Lo que lo dispara: `pull_request`, `push`, `schedule`, `workflow_dispatch` (a mano) | `addEventListener` |
| **Job** | Un conjunto de pasos que se ejecuta en **una** máquina. Varios jobs corren **en paralelo** salvo que uses `needs:` | Un proceso / un worker |
| **Runner** | La máquina que ejecuta un job (`runs-on: ubuntu-latest`). **Nace vacía y muere al terminar**: no recuerda nada del job anterior | Un contenedor desechable |
| **Step** | Un paso dentro de un job: un comando (`run:`) o una acción (`uses:`) | Una línea de un script |
| **Action** | Un paso reutilizable publicado por otros (`actions/checkout`, `astral-sh/setup-uv`...) | Un paquete de npm que importas |
| **`with:`** | Los parámetros de una acción | Los argumentos de una función |
| **`env:` / secrets** | Variables de entorno / valores privados guardados en GitHub | `.env` |
| **`permissions:`** | Qué puede hacer el token automático del workflow sobre tu repo | Scopes de un token de API |

**Punto clave que más confunde:** como el runner nace vacío, **tu código no está ahí** hasta que un paso lo descarga (`actions/checkout`), y las herramientas (Python, Node, uv...) **tampoco están instaladas** hasta que un paso las instala. Todo lo que tú tienes ya en tu máquina lo tienes que "recrear" en el workflow.

## 4. Ejemplos de estructura (de OTRO proyecto, no el tuyo)

Los tres ejemplos son para un proyecto Node pequeño inventado (`npm`, ESLint y Vitest). **No son tu solución**: tu stack es distinto (Python con `uv`, TypeScript con `pnpm`, y `just`), y tendrás que traducirlo leyendo la documentación de cada herramienta.

### Ejemplo A: el workflow más pequeño posible

Fichero `.github/workflows/ejemplo-a.yml`:

```yaml
name: Hola                     # nombre que verás en la pestaña Actions

on:                            # CUÁNDO se ejecuta
  pull_request:                #   al abrir o actualizar un PR
    branches: [main]           #   solo si el PR va contra main

jobs:                          # QUÉ se ejecuta
  saludo:                      # nombre del job (lo eliges tú)
    runs-on: ubuntu-latest     # en qué tipo de máquina
    steps:
      - name: Decir hola       # un paso con un comando
        run: echo "hola desde la CI"
```

Cuando lo subes y abres un PR, en la pestaña **Actions** aparece el workflow, entras al job y ves la salida de cada paso, como una terminal.

### Ejemplo B: un proyecto real, un job, varios pasos

```yaml
name: CI

on:
  pull_request:
    branches: [main]

permissions:
  contents: read               # el token solo puede LEER el repo (principio de mínimo privilegio)

jobs:
  comprobar:
    runs-on: ubuntu-latest
    steps:
      - name: Descargar el código
        uses: actions/checkout@v4          # acción: baja el repo al runner

      - name: Instalar Node
        uses: actions/setup-node@v4        # acción: instala Node
        with:                              # parámetros de la acción
          node-version: 22

      - name: Instalar dependencias
        run: npm ci                        # comando normal de terminal

      - name: Lint
        run: npm run lint

      - name: Tests
        run: npm test
```

Lectura de arriba abajo: *"cuando abran un PR contra `main`, en una máquina Ubuntu nueva: descarga el código, instala Node 22, instala dependencias, pasa el lint, pasa los tests. Si **cualquier paso devuelve error, el job falla** y el PR sale rojo."* No hace falta programar nada más para que falle: un comando que termina con código distinto de 0 ya es un fallo.

Las versiones `@v4` son orientativas: mira en el repositorio de cada acción (github.com/actions/checkout, github.com/actions/setup-node) cuál es la actual.

### Ejemplo C: varios jobs en paralelo, uno que espera a otro

```yaml
jobs:
  lint:                        # job 1
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "aquí iría el lint"

  tests:                       # job 2: se ejecuta A LA VEZ que lint, en otra máquina
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4   # ¡hay que repetirlo! cada job tiene su máquina vacía
      - run: echo "aquí irían los tests"

  publicar:                    # job 3: espera a que los otros dos terminen BIEN
    needs: [lint, tests]
    runs-on: ubuntu-latest
    steps:
      - run: echo "solo llego aquí si lint y tests pasaron"
```

Lo que enseña: los jobs son independientes (cada uno repite el `checkout`), corren en paralelo por defecto, y `needs:` crea dependencias. Esto es el trade-off de "un job o varios" del apartado 6.

### Ejemplo D: otros campos útiles que verás en la documentación

```yaml
on:
  pull_request:
    paths:                     # solo ejecutar si cambian ficheros de estas rutas
      - "apps/**"
  push:
    branches: [main]           # y también al hacer push directo a main

concurrency:                   # si llega un commit nuevo, cancela la ejecución anterior de la misma rama
  group: ci-${{ github.ref }}  # ${{ ... }} = expresiones: leen datos del contexto de GitHub
  cancel-in-progress: true

jobs:
  uno:
    runs-on: ubuntu-latest
    timeout-minutes: 10        # corta el job si se queda colgado
    env:
      MI_VARIABLE: valor       # variable de entorno para todos los pasos del job
    steps:
      - run: echo "$MI_VARIABLE"
```

## 5. Las herramientas que vas a ejecutar (qué es cada una)

Tu repo ya las tiene configuradas; ejecutar todo junto es `just ci`. Entenderlas es la parte teórica de este paso.

| Herramienta | Para qué sirve | Analogía web | Configurada en |
|---|---|---|---|
| **uv** | Gestor de Python: instala versiones de Python y dependencias, crea el entorno virtual, bloquea versiones | `npm` + `nvm` en uno. `uv.lock` ≈ `package-lock.json` | `pyproject.toml`, `uv.lock` |
| **ruff** | Linter y formateador de Python (muy rápido) | ESLint + Prettier | `[tool.ruff]` en `pyproject.toml` |
| **mypy** | Comprueba tipos de Python **sin ejecutar** el código | `tsc --noEmit` | `[tool.mypy]` |
| **pytest** | Ejecuta los tests de Python | Vitest / Jest | `[tool.pytest.ini_options]` |
| **pnpm** | Gestor de paquetes de Node/TypeScript | Una alternativa a `npm`, más rápida y con menos duplicados | `package.json`, `pnpm-workspace.yaml`, `pnpm-lock.yaml` |
| **ESLint** | Linter de TypeScript | — | `eslint.config.js` |
| **tsc** | Compilador/comprobador de TypeScript | — | `tsconfig.base.json` |
| **just** | Ejecutor de órdenes con nombre (`just ci`). Es un `package.json > scripts` que sirve para cualquier lenguaje | Los `scripts` de npm | `justfile` |
| **gitleaks** | Busca secretos (claves de API, tokens) en el código y en **todo el historial de git** | Un antivirus para commits | Se invoca desde la CI |

**Por qué gitleaks importa en tu repo:** es público. Si un día pegas una clave por error y la borras en el commit siguiente, **sigue en el historial** y cualquiera puede verla. La CI es la red de seguridad.

Qué hace `just ci` hoy (míralo en el `justfile`): `lint` (ruff + ESLint), `tipos` (mypy + `pnpm tipos`) y `tests` (pytest). Aún no incluye gitleaks.

## 6. Decisiones que tendrás que tomar y poder defender

Cada una es una pregunta de entrevista. No hay una respuesta única; hay una que **tú puedas justificar**.

1. **¿Un job o varios?** Varios dan feedback más claro (ves qué comprobación falló) y corren en paralelo, pero cada uno repite `checkout` e instalación. Un job gasta menos y es más simple.
2. **¿`just ci` o los comandos sueltos?** Si el workflow llama a `just ci`, la CI y tu máquina hacen exactamente lo mismo (una sola fuente de verdad). Si copia los comandos, se desincronizan con el tiempo. Tiene el coste de instalar `just` en el runner y de ver menos detalle por paso.
3. **Disparadores.** ¿Solo `pull_request`, o también `push` a `main`? ¿Qué pasa si no hay `push` a main y alguien mergea algo roto por un conflicto de última hora?
4. **Versiones de las acciones.** `@v4` se mueve (el autor puede publicar código nuevo bajo la misma etiqueta) y fijar por hash de commit (`@a1b2c3...`) no. En un repo público es un riesgo real de cadena de suministro; pregúntate cuánto te importa y cómo lo mantendrías al día.
5. **Permisos mínimos.** Declara `permissions:` explícitos (como en el ejemplo B) en lugar de dejar los de por defecto.
6. **Caché.** `uv` y `pnpm` pueden cachear las descargas entre ejecuciones. Con tan poco código quizá no compense; mídelo.
7. **`concurrency`.** ¿Tres commits seguidos = tres ejecuciones o solo la última?
8. **Filtros por ruta (`paths:`).** El diseño dice "solo probar lo que cambia". Piensa qué falla si filtras por ruta y un cambio en `paquetes/contratos` rompe a `apps/dashboard`.

## 7. Cómo se lee un fallo

Pestaña **Actions** del repo → pulsa la ejecución roja → pulsa el job → los pasos aparecen como acordeón; el que falló está marcado con ✗ y expandido, con la salida exacta del comando. 90 % de los fallos de CI se resuelven reproduciendo en local el mismo comando que falló. Si lo reproduces y pasa en local pero falla en CI, casi siempre es una herramienta no instalada o con otra versión en el runner.

## 8. Flujo de trabajo con git para este paso

```bash
git clone https://github.com/DAAF292/atalaia.git   # una sola vez
cd atalaia
git switch -c ci/primer-workflow                   # crea y cambia a una rama nueva
# ...creas .github/workflows/ci.yml...
git add .github/workflows/ci.yml
git commit -m "Añade el primer workflow de CI"
git push -u origin ci/primer-workflow              # sube la rama
# en GitHub: "Compare & pull request" → base: main
```

Usa la plantilla de PR (se rellena sola). Para ver tu CI funcionando necesitas el PR abierto: el workflow solo se activa con los eventos que declares.

Estructura final esperada en esta parte del repo:

```
atalaia/
├── .github/
│   ├── pull_request_template.md   ← ya existe
│   └── workflows/
│       └── ci.yml                 ← lo creas tú
├── justfile                       ← ya existe (`just ci`)
└── ...
```

## 9. Especificación y criterios de aceptación

- [ ] El workflow corre automáticamente al abrir o actualizar un PR contra `main`.
- [ ] Ejecuta lint (Python y TypeScript), tipos, tests y gitleaks, y falla si cualquiera falla.
- [ ] Con el repo actual (sin código de aplicación) sale **verde**.
- [ ] **Prueba de que no es decorativo**: en una rama aparte, (a) introduce a propósito un fallo de formato o de lint de Python y comprueba que el PR sale **rojo**; (b) añade una clave falsa con formato reconocible (busca en la documentación de gitleaks cómo es un ejemplo de token) y comprueba que gitleaks la detecta. Guarda el enlace a esas ejecuciones fallidas para el README. **No dejes la clave falsa en `main`.**
- [ ] Declara `permissions:` mínimos y las versiones de las acciones fijadas de una forma que puedas justificar.
- [ ] Usa `concurrency` o explica por qué no lo necesitas.
- [ ] PR abierto para revisión. Al cerrar: ADR si tomaste una decisión de diseño (por ejemplo, job único frente a varios) y una línea en `docs/diario.md`.

## 10. Documentación oficial para cada tecnología

- GitHub Actions, conceptos y referencia: https://docs.github.com/en/actions (busca "Understanding GitHub Actions" y "Workflow syntax for GitHub Actions")
- uv en GitHub Actions: https://docs.astral.sh/uv/guides/integration/github/
- pnpm en CI: https://pnpm.io/continuous-integration
- gitleaks y su acción: https://github.com/gitleaks/gitleaks-action
- just: https://just.systems/man/en/
- Ruff: https://docs.astral.sh/ruff/ · mypy: https://mypy.readthedocs.io · pytest: https://docs.pytest.org

## 11. Conexión con AtalaIA

Esta CI es la red de seguridad de todo lo que viene: cada herramienta del ecosistema se prueba aquí antes de desplegarse. En la fase 2 se ampliará para ejecutar las evals de laIA, y el despliegue en el homelab tirará de las imágenes que construya. Lo que decidas hoy sobre permisos y versiones se hereda.

## 12. Ayuda por niveles

Si te atascas, dime en qué punto y empiezo por una pregunta guía, después una pista, un ejemplo análogo, un fragmento y, solo si lo pides, la solución completa. Para depurar el YAML en local sin ensuciar el historial puedes usar `act` (https://github.com/nektos/act), con el matiz de que no replica exactamente los runners de GitHub.
