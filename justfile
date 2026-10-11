# Órdenes comunes del monorepo. `just` sin argumentos lista las disponibles.
set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Instala dependencias de Python y TypeScript
instalar:
    uv sync
    pnpm install

# Formato y lint (Python + TypeScript)
lint:
    uv run ruff check .
    uv run ruff format --check .
    pnpm lint

# Corrige lo que ruff sabe corregir solo
arreglar:
    uv run ruff check --fix .
    uv run ruff format .

# Comprobación de tipos
tipos:
    # Código 2 = aún no hay ficheros Python; se quitará con el primer paquete
    uv run mypy . || test $? -eq 2
    pnpm tipos

# Tests de Python
tests:
    # Código 5 = aún no hay tests; se quitará con el primer paquete
    uv run pytest || test $? -eq 5

# Todo lo que correrá la CI
ci: lint tipos tests
