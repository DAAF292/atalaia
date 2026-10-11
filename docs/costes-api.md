# Costes de la API de Claude

Fecha: 2026-10-11. Precios de https://platform.claude.com/docs/en/about-claude/pricing (consultados ese día; **revisar antes de decidir**, cambian). USD por millón de tokens (MTok).

## 1. Precios relevantes

| Modelo | Entrada | Salida | Caché: lectura | Batch (entrada/salida) |
|---|---|---|---|---|
| Haiku 5.5 (prompt ≤ 100k) | 0,10 | 0,50 | 0,01 | 0,05 / 0,25 |
| Sonnet 5.5 | 2 | 10 | 0,10 | 1 / 5 |
| Opus 5.5 | 4 | 20 | 0,20 | 2 / 10 |
| Haiku 4.5 (anterior) | 1 | 5 | 0,10 | — |

- Haiku 5.5 sube a 0,50 / 2,50 si el prompt supera 100k tokens (incluye lecturas de caché). Irrelevante para laIA salvo que se le meta un documento enorme.
- Escribir en caché cuesta 1,25× la entrada (5 min) o 2× (1 h); leer cuesta 0,1× (0,05× en Sonnet y Opus 5.5).
- Batch API: -50 %, acumulable con caché, pero asíncrona: sirve para evals, no para el chat.
- Los modelos desde 4.7 usan un tokenizador que genera ~30 % más tokens para el mismo texto: no compares con cifras antiguas sin ajustar.
- Uso de herramientas: ~286 tokens fijos por petición (Haiku 5.5, Sonnet 5.5, Opus 5.5), más el esquema de cada herramienta MCP que definas.

## 2. Estimación para laIA (hipótesis mías, **no medidas**)

Supuestos: una pregunta de laIA = 3 llamadas al LLM (bucle de herramientas); cada llamada lleva ~3.000 tokens de prompt de sistema + herramientas (cacheables), ~1.000 de historial y resultados nuevos, y ~150 de salida; 50 preguntas al día.

| Modelo | Por pregunta | Al mes (50/día) |
|---|---|---|
| Haiku 5.5 | ~0,0006 $ | ~1 $ |
| Sonnet 5.5 | ~0,011 $ | ~17 $ |
| Opus 5.5 | ~0,023 $ | ~34 $ |

Sin caché los números suben (más en los modelos caros). Reserva: Haiku requiere un mínimo de tokens para que el caché se active; hay que comprobar en la documentación de caché que el prompt de laIA lo alcanza, o el ahorro no existe.

**Lectura crítica:** con tu volumen personal el gasto de Haiku es casi irrelevante; la diferencia entre modelos es de decenas de dólares al mes, no de cientos. El riesgo real de coste no es el precio por token, sino **un bucle de agente descontrolado** o un proceso proactivo (avisos) que llama al LLM cada pocos minutos.

## 3. Dónde sí puede dispararse

1. Bucle de herramientas sin tope de iteraciones.
2. Avisos proactivos / Vigía que consultan al LLM por cada evento en lugar de filtrar antes con reglas normales.
3. Historial de conversación que crece sin resumirse: cada turno reenvía todo.
4. Evals ejecutadas a menudo con el modelo caro.
5. Fase 8 (RAG): contexto grande en cada consulta y embeddings (Anthropic no ofrece modelo de embeddings: van locales, ya decidido).
6. Voz: ya es local (Whisper y Piper), sin coste de API.

## 4. Decisión propuesta (#38, pendiente de visto bueno)

1. **Haiku 5.5 por defecto** en laIA; subir a Sonnet 5.5 solo para las preguntas donde las evals muestren que Haiku falla. "Sin perder capacidad" se demuestra con datos: mismas evals, ambos modelos, tabla de acierto vs coste.
2. En `ProveedorLLM`: tope de iteraciones del bucle (p. ej. 6), `max_tokens` explícito, tope de gasto diario configurable que corta con error claro.
3. Prompt de sistema y herramientas **estables y al principio** para aprovechar el caché; resumir el historial pasado cierto tamaño.
4. Trazas con coste por llamada desde la fase 2 (ya decidido, #35); alerta si el gasto del día supera un umbral.
5. Evals por Batch API siempre que no necesiten respuesta inmediata.
6. Límite de gasto mensual fijado en la consola de Anthropic como red de seguridad externa al código (comprobar el nombre exacto del ajuste en la consola).
7. Descartado por ahora el router entre modelos: hasta tener evals no hay datos para decidir cuándo subir de modelo. Se revisa con el router por sensibilidad (fase 4).

## 5. Qué falta medir

Tokens reales de una pregunta típica de laIA (el SDK devuelve `usage` en cada respuesta), tasa de acierto de Haiku en las evals, y si el caché se activa. Hasta entonces, las cifras de la sección 2 son órdenes de magnitud.

> Nota (2026-10-11): la decisión #39 amplía este análisis a varios proveedores; ver docs/estudio-modelos.md.
