# `datasets/`

Aquí viven los datasets **ya publicados**: el resultado final de cada
pipeline en `R/<slug>/`, listo para que la comunidad lo descargue. Es lo que
la página [Datos abiertos](../datos-abiertos.qmd) enlaza a través de
`data/datasets.yml` (URLs `raw.githubusercontent.com/.../datasets/<slug>/...`).

```
datasets/
  <slug-del-dataset>/
    <slug>.csv        El dataset, en formato abierto.
    diccionario.md     Descripción de cada columna, tipo y % de vacíos.
```

Estos archivos **sí se versionan en git** (a diferencia de `data/raw/` y
`data/processed/`, que son insumos/intermedios de trabajo): son el producto
que Datopedia libera.

No se editan a mano — los genera `publicar_dataset()`
(`R/00_utils/publicar_dataset.R`) al correr el paso 2 de cada pipeline. Para
actualizar un dataset, vuelve a correr su pipeline completo y súbelo de
nuevo.
