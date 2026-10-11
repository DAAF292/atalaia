# Estudio de modelos y proveedores de LLM (calidad/precio)

Fecha: 2026-10-11. **Primera pasada, no definitiva.** Los precios salen de las páginas oficiales de cada proveedor consultadas ese día (USD por millón de tokens, MTok); lo que no pude verificar está marcado. Cambian rápido: revisar antes de decidir.

## 1. Precios verificados (página oficial)

| Proveedor | Modelo | Entrada | Caché (lectura) | Salida | Notas |
|---|---|---|---|---|---|
| Anthropic | Haiku 5.5 | 0,10 | 0,01 | 0,50 | Sube a 0,50/2,50 con prompts > 100k. Batch -50 % |
| Anthropic | Sonnet 5.5 | 2 | 0,10 | 10 | |
| OpenAI | GPT-5.6 Luna | 0,20 | 0,02 | 1,20 | El barato de su familia. Batch -50 % |
| OpenAI | GPT-5.6 Terra | 2 | 0,20 | 12 | |
| Google | gemini-3.1-flash-lite | 0,25 | 0,025 | 1,50 | Capa gratuita; sin caché |
| Google | gemini-3.5-flash-lite | 0,30 | 0,03 | 2,50 | Capa gratuita; sin caché |
| Google | gemini-3-flash-preview | 0,50 | 0,05 | 3,00 | Capa gratuita |
| Google | gemini-3.6 / 3.8-flash | 0,75 | 0,075 | 3,75 | Sube con prompts > 200k |
| Mistral | Mistral Large | 0,5 | — | 1,5 | Única cifra visible en su web |
| DeepSeek | `deepseek-flash`, `deepseek-v4-pro` | **no verificado** | | | La página consultada no mostraba precios |
| Mistral | Small 4 / Medium 3.5 | **no verificado** | | | Pesos abiertos (Apache 2.0 / MIT modificada) |

Lectura rápida: en la gama barata **Haiku 5.5 sigue siendo el más barato** en entrada y salida entre los verificados; Luna de OpenAI y los Flash-Lite de Google están en 2-3× de precio. La diferencia absoluta con tu volumen (centenas de miles de tokens al día) es de céntimos a pocos dólares al mes, así que **el precio no debe decidir solo**.

## 2. Lo que el precio por token no te dice

1. **Coste por tarea, no por token.** Tokenizadores distintos (Anthropic: ~30 % más tokens desde 4.7), modelos con razonamiento que gastan tokens de salida ocultos y bucles de herramientas más largos pueden invertir el orden. Se compara con **tus evals**: coste total por pregunta resuelta.
2. **Fiabilidad al llamar herramientas** es lo que pide laIA. Existen rankings (BFCL v4 en benchlm.ai), pero su propia página avisa de que **22 de 23 filas son autoinformes del proveedor, no ejecuciones independientes**, y el primero de la lista es un laboratorio que no conozco. No se decide con eso: es un filtro para elegir candidatos.
3. **Privacidad y jurisdicción.** Enviar notas y agenda a un proveedor depende de dónde procesa y qué retiene. Un API chino (DeepSeek, Alibaba, Moonshot) es muy barato pero no es lugar para lo marcado como sensible (etiqueta de sensibilidad ya prevista en la visión). No he verificado sus políticas de retención: hay que leerlas antes de enviarles nada personal.
4. **Latencia** (importa en voz) y **límites de tasa** de cada capa gratuita.
5. **Caché de prompts**: no es igual en todos (Anthropic explícito, otros automático, Google Flash-Lite sin caché). Cambia el coste real de un prompt de sistema largo.
6. **Modelos locales**: gratis por token pero con coste de hardware (hoy 16 GB de RAM en el host; 32 GB previstos) y menos fiabilidad con herramientas. Entran por el router de sensibilidad (fase 4), no antes.

## 3. Diseño del proveedor multi-fuente (propuesta)

El diseño actual (`ProveedorLLM` sobre el SDK de Anthropic) ya iba en esta dirección; hay que **retirar el "sobre el SDK de Anthropic" de la decisión #28** y quedarse con la interfaz.

- **Interfaz propia y pequeña** `ProveedorLLM`: entrada = mensajes + herramientas + parámetros en un formato **neutro propio**; salida = respuesta neutra (texto, llamadas a herramientas, `uso` de tokens, motivo de parada). Cada proveedor es un adaptador.
- **Adaptadores**: uno para Anthropic (SDK oficial) y uno para el **dialecto "compatible con OpenAI"**, que hablan OpenAI, Google (modo compatible), DeepSeek, Mistral y la mayoría de servidores locales (llama.cpp, Ollama, vLLM). Con dos adaptadores cubres casi todo el mercado. Regla del método: **los dos primeros los escribes tú**; los siguientes, repeticiones.
- **Configuración por tarea, no global**: qué modelo usa cada función (conversación, resúmenes, evals) y qué etiqueta de sensibilidad admite cada modelo. El router elige.
- **Tope de coste y trazas** en la interfaz, independientes del proveedor (ya decidido en #35 y #38).
- **Pruebas de contrato**: una misma batería de tests que cualquier adaptador debe pasar, y adaptador falso para el modo demo y la CI sin red ni claves.
- **Qué no se abstrae**: funciones exclusivas (extended thinking, búsqueda web del proveedor, herramientas de servidor). Si se usan, quedan detrás de una capacidad opcional que declara el adaptador.
- **Alternativa descartada por ahora**: un agregador (OpenRouter u otro) como único adaptador. Simplifica, pero añade un intermediario con el que pasan tus datos, y se pierde justo lo que enseña el proyecto. Sigue siendo válido como un adaptador más para probar modelos.
- LiteLLM/LangChain siguen descartados (#13): la interfaz propia es más pequeña y es lo que te preguntarán en entrevista.

## 4. Cómo se elige de verdad: el estudio medido

1. **Batería de evals de laIA** (fase 2): preguntas con herramienta esperada, argumentos esperados, casos de inyección de prompt y de herramienta inexistente.
2. **Candidatos iniciales** (3-5): Haiku 5.5, GPT-5.6 Luna, un Flash-Lite de Google, un modelo de pesos abiertos servido por API (DeepSeek o Mistral Small) y uno local pequeño como línea base.
3. **Métricas**: acierto de herramienta y de argumentos, coste por pregunta, latencia p50/p95, tasa de error. Se publica la tabla en el README (es material de entrevista).
4. **Modelo por defecto** = el más barato que supere el umbral de acierto que fijes (propongo 90 % en herramienta correcta, a discutir). Un modelo mejor se usa solo donde la tabla lo justifique.
5. Repetir el estudio cuando salgan modelos nuevos: con el proveedor abstracto cuesta una línea de configuración.

## 5. Lo que falta verificar

Precios de DeepSeek y de Mistral Small/Medium; políticas de retención y localización de datos de cada proveedor; mínimo de tokens para activar caché en cada modelo; calidad real con herramientas en español (los rankings son mayormente en inglés).
