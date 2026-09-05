# Pipelines de datasets (`R/`)

Cada dataset del catálogo de [Datos abiertos](../datos-abiertos.qmd) tiene su
propia carpeta aquí, con dos scripts:

```
R/
  00_utils/                      Funciones compartidas entre pipelines
    normalizar_ubigeo.R            — cruce de nombres geográficos -> UBIGEO
    publicar_dataset.R             — CSV + diccionario.md + bloque YAML
  <slug-del-dataset>/
    01_procesar_<dataset>.R        Fuente cruda -> data.frame limpio (.rds)
    02_publicar_<dataset>.R        .rds -> CSV + diccionario en datasets/
  _plantilla_nuevo_dataset/       Punto de partida para el siguiente dataset
    01_procesar_TEMPLATE.R
    02_publicar_TEMPLATE.R
```

## Por qué dos pasos

- **`01_procesar_*.R`** hace el trabajo pesado y específico de la fuente:
  parsear el PDF/Excel/KML, limpiar, deduplicar, cruzar geografía. Guarda el
  resultado como `.rds` en `data/processed/<slug>/` — un insumo intermedio,
  no versionado ni publicado.
- **`02_publicar_*.R`** es corto y siempre tiene la misma forma: lee el
  `.rds`, documenta cada columna en una lista `columnas`, y llama a
  `publicar_dataset()`. Esa función escribe el CSV y el diccionario de datos
  en `datasets/<slug>/` (lo que sí se publica) e imprime el bloque YAML para
  pegar en [`data/datasets.yml`](../data/datasets.yml), que es lo que
  alimenta la página de Datos Abiertos del sitio.

Separarlos permite ajustar la documentación o volver a publicar sin tener
que reprocesar la fuente cruda cada vez.

## Cómo agregar un dataset nuevo

1. Copia `R/_plantilla_nuevo_dataset/` a `R/<slug-del-dataset>/` y renombra
   los dos archivos (`01_procesar_TEMPLATE.R` → `01_procesar_<dataset>.R`,
   igual para `02_`).
2. Crea `data/raw/<slug>/` para la fuente cruda (con su propio
   `README.md` si el origen o el formato no es obvio — ver el de
   `data/raw/conflictos-sociales/` como ejemplo).
3. Completa `01_procesar_<dataset>.R`: lee la fuente, limpia, y guarda el
   `.rds` en `data/processed/<slug>/`.
4. Completa `02_publicar_<dataset>.R`: documenta cada columna en `columnas`
   y ajusta los metadatos (`nombre`, `descripcion`, `categoria`,
   `fuente_original`, etc.).
5. Corre ambos scripts desde la raíz del proyecto:

   ```bash
   Rscript R/<slug-del-dataset>/01_procesar_<dataset>.R
   Rscript R/<slug-del-dataset>/02_publicar_<dataset>.R
   ```

6. El segundo script imprime un bloque YAML — pégalo en
   `data/datasets.yml`, bajo `datasets:`.
7. `quarto render` — el catálogo en Datos Abiertos se regenera solo a partir
   de `data/datasets.yml`.
8. Sube `datasets/<slug>/` (el CSV + `diccionario.md`) al repositorio antes
   de publicar el sitio: son los archivos a los que apuntan los enlaces
   "Descargar dataset" y "Ver diccionario".

## Si el dataset trae Departamento/Provincia/Distrito

Usa `R/00_utils/normalizar_ubigeo.R` (`cargar_ubigeo()` + `cruzar_ubigeo()`)
en vez de reescribir el cruce contra la tabla de UBIGEO. Acepta nombres de
columna distintos y crosswalks propios del dataset (variantes de escritura
que solo aparecen en esa fuente) — ver
`R/conflictos-sociales/01_procesar_conflictos.R` como referencia completa.

## Paquetes usados por los pipelines

`tidyverse`, `xml2`, `stringi`, `fs`, `glue`, `readr`, `purrr` — más lo que
requiera cada fuente nueva (p. ej. `readxl` para Excel, `pdftools` para PDF).
