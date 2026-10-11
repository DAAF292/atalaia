# Teoría y especificación: tu primer workflow de CI

Paso de la fase 0 que escribes **tú**. Aquí tienes la teoría desde cero y los criterios de aceptación; el YAML lo escribes tú. Documentación oficial de partida: https://docs.github.com/en/actions

## 1. Qué es una CI y por qué

**Integración continua (CI)** = una máquina que, cada vez que alguien propone un cambio, ejecuta automáticamente las mismas comprobaciones (formato, tipos, tests, búsqueda de secretos) y dice "verde" o "rojo". Analogía web: es como el `npm test && npm run lint` de tu `package.json`, pero ejecutado por un servidor limpio y no por tu portátil, así que no depende de "en mi máquina funciona". Es también la condición para que un PR pueda mergearse: la revisión humana deja de gastarse en detalles que una máquina detecta.

En AtalaIA hay un motivo extra: el repo es público, así que un secreto filtrado en un commit queda expuesto para siempre. Por eso `gitleaks` forma parte de la CI desde el primer día.

## 2. Anatomía de GitHub Actions (el vocabulario)

| Concepto | Qué es | Analogía |
|---|---|---|
| **Workflow** | Un fichero YAML en `.github/workflows/` | Un script de `package.json` con nombre y disparador |
| **Evento (`on:`)** | Lo que lo dispara: `push`, `pull_request`, `schedule`... | Un listener de eventos |
| **Job** | Un grupo de pasos que corre en una máquina; varios jobs corren en paralelo salvo que declares `needs:` | Un proceso |
| **Runner** | La máquina (`runs-on: ubuntu-latest`): una VM limpia que nace y muere con el job | Un contenedor desechable |
| **Step** | Un comando (`run:`) o una acción reutilizable (`uses:`) | Una línea del script / un `import` |
| **Action** | Paquete reutilizable (`actions/checkout`, `astral-sh/setup-uv`...) | Una dependencia de npm |
| **Permisos y secretos** | Qué puede hacer el token del workflow y qué credenciales ve | Variables de entorno con control de acceso |

Lectura obligada: https://docs.github.com/en/actions/get-started/understanding-github-actions y la referencia de sintaxis de workflows (`on`, `jobs`, `needs`, `permissions`, `concurrency`, `paths`).

## 3. Decisiones de diseño que tendrás que tomar (y defender)

1. **¿Un job o varios?** Un job por comprobación (lint, tipos, tests, secretos) da feedback más claro y en paralelo; un solo job gasta menos minutos de arranque. Con repo público los minutos son gratuitos: razona cuál prefieres.
2. **Disparadores.** ¿Solo `pull_request`? ¿También `push` a `main`? ¿Qué pasa con un PR de una rama contra un push duplicado?
3. **Filtros por ruta (`paths:`).** El diseño dice que la CI solo prueba lo que cambia. Hoy el repo no tiene apps; piensa qué falla si filtras por ruta y un cambio en `paquetes/contratos` afecta a `apps/dashboard`.
4. **Versiones fijas.** `uses: actions/checkout@v4` vs fijar por hash de commit: qué riesgo de cadena de suministro tiene cada una. En un repo público conviene pensarlo.
5. **Permisos mínimos.** El `GITHUB_TOKEN` por defecto puede ser demasiado generoso: declara `permissions:` explícitos.
6. **Caché.** `uv` y `pnpm` pueden cachear dependencias; mide si compensa con tan poco código.
7. **`concurrency`.** Si empujas tres commits seguidos, ¿quieres tres ejecuciones o solo la última?
8. **Cómo usar `just ci`.** Ya existe en el `justfile`. Si el workflow llama a `just ci`, local y CI hacen lo mismo; si copia los comandos, se desincronizan. Decide y justifica.

## 4. Herramientas que va a ejecutar

- `uv` en CI: https://docs.astral.sh/uv/guides/integration/github/
- `pnpm` en CI: https://pnpm.io/continuous-integration
- `gitleaks` (busca secretos en el historial): https://github.com/gitleaks/gitleaks-action
- `ruff`, `mypy`, `pytest`, `eslint`, `tsc`: ya configurados; los invoca `just ci`.

## 5. Criterios de aceptación

- [ ] El workflow corre automáticamente al abrir o actualizar un PR contra `main`.
- [ ] Ejecuta lint (Python y TypeScript), tipos, tests y gitleaks, y falla si cualquiera falla.
- [ ] Con el repo actual (sin código) debe salir **verde**.
- [ ] Demuestra que no es decorativo: en una rama de prueba, introduce a propósito (a) un fallo de `ruff` y (b) una clave falsa con formato reconocible por gitleaks, y comprueba que el PR sale **rojo** en cada caso. Guarda los enlaces a esos runs fallidos para el README.
- [ ] Declara `permissions:` mínimos y fija las versiones de las acciones de una forma que puedas justificar.
- [ ] Usa `concurrency` o explica por escrito por qué no lo necesitas.
- [ ] Un PR con el workflow, revisado por mí. Cierre: ADR si tomaste una decisión de diseño (p. ej. un job vs varios) y una línea en `docs/diario.md`.

## 6. Cómo trabajar este paso

Rama nueva → escribes `.github/workflows/ci.yml` → PR → revisión. Si te atascas, pide ayuda por niveles (empezamos por una pregunta guía). Para depurar YAML sin ensuciar el historial, `act` permite ejecutar workflows en local, aunque no replica exactamente los runners de GitHub.

**Para pensar antes de escribir:** ¿qué pasaría si dejas de ejecutar gitleaks en los PRs de ramas externas? ¿Quién puede abrir un PR en un repo público, y qué ve su workflow?
