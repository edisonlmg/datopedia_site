# Datopedia — sitio + pipelines de datos abiertos

Proyecto único en Quarto/R para [Datopedia](https://datopedia.org): el
sitio (presentación, blog, catálogo de datos abiertos) **y** los pipelines
en R que producen cada dataset del catálogo a partir de fuentes públicas no
estructuradas (informes PDF, Excel de reporte físico, archivos KML, etc.).

## Estructura del proyecto

```
_quarto.yml               Configuración del sitio (navbar, tema, footer)
index.qmd                 Homepage: banner + accesos a las 4 secciones
presentacion.qmd          Página "Presentación"
blog.qmd                  Listado del blog (Quarto listing)
posts/                    Posts del blog (una carpeta con index.qmd por post)
  _metadata.yml           Metadatos por defecto de todos los posts
datos-abiertos.qmd        Catálogo de datasets (se genera desde data/datasets.yml)
styles/
  datopedia.scss          Tema (paleta, tipografía) sobre el theme cosmo
  styles.css               Estilos del hero, tarjetas y "ledger" de datasets
images/                   Logo (sello.svg) y favicon

R/                        Pipelines de datos — ver R/README.md
  00_utils/
    normalizar_ubigeo.R     Cruce compartido de nombre geográfico -> UBIGEO
    publicar_dataset.R      CSV + diccionario.md + bloque YAML del catálogo
  conflictos-sociales/
    01_procesar_conflictos.R
    02_publicar_conflictos.R
  _plantilla_nuevo_dataset/  Punto de partida para el próximo dataset

data/
  datasets.yml             Catálogo que lee datos-abiertos.qmd (SÍ se versiona)
  raw/<slug>/               Fuente cruda por dataset (NO se versiona)
  interim/                  Tablas de referencia compartidas, p. ej. UBIGEO (SÍ se versiona)
  processed/<slug>/         Insumos intermedios .rds por dataset (NO se versiona)

datasets/<slug>/           Datasets YA publicados: <slug>.csv + diccionario.md
                            (SÍ se versiona — es lo que enlaza el catálogo)
```

## Requisitos

- [Quarto CLI](https://quarto.org/docs/get-started/) ≥ 1.5
- R con estos paquetes:

  ```r
  install.packages(c(
    "tidyverse", "xml2", "stringi", "fs", "yaml", "glue"
  ))
  ```

  (`tidyverse` ya incluye dplyr, stringr, readr, purrr, tibble, usados por
  los pipelines y por `datos-abiertos.qmd`).

## Uso del sitio

```bash
quarto preview     # previsualizar en local con recarga automática
quarto render       # renderizar el sitio estático (queda en _site/)
quarto publish gh-pages   # publicar en GitHub Pages
```

## Cómo actualizar el dataset de conflictos sociales

```bash
# 1. Coloca los .kml del mes en data/raw/conflictos-sociales/
#    (ver data/raw/conflictos-sociales/README.md)

# 2. Corre el pipeline
Rscript R/conflictos-sociales/01_procesar_conflictos.R
Rscript R/conflictos-sociales/02_publicar_conflictos.R

# 3. El paso 2 imprime un bloque YAML: pégalo/actualízalo en data/datasets.yml
#    (fecha_actualizacion, principalmente)

# 4. quarto render, y sube datasets/conflictos-sociales/ + data/datasets.yml
```

## Cómo agregar un dataset nuevo

Ver [`R/README.md`](R/README.md) — resumen: copia
`R/_plantilla_nuevo_dataset/` a `R/<slug>/`, completa los dos scripts
(procesar y publicar), y corre ambos. El segundo te da el bloque YAML listo
para pegar en `data/datasets.yml`. Si el dataset trae
Departamento/Provincia/Distrito, reutiliza
`R/00_utils/normalizar_ubigeo.R` en vez de reescribir ese cruce.

## Cómo agregar un post al blog

Crea una carpeta nueva en `posts/` con un `index.qmd`, con al menos
`title`, `date` y `categories` en el frontmatter. El listado en `blog.qmd`
lo recoge automáticamente.

## Ajustes pendientes antes de publicar

- Reemplazar `https://github.com/datopedia-pe/datopedia` por la URL real
  del repositorio (aparece en `_quarto.yml`, varias páginas, y en los
  parámetros por defecto de `publicar_dataset()`).
- Reemplazar `data/interim/ubigeos_2025.csv` (son solo 5 filas de ejemplo)
  por la tabla oficial completa de UBIGEO — ver
  `data/interim/README.md`.
- Correr el pipeline de conflictos sociales con los `.kml` reales: el CSV y
  el diccionario en `datasets/conflictos-sociales/` todavía no existen en
  este proyecto (no hay fuente cruda incluida), aunque el catálogo en
  `data/datasets.yml` ya está enlazado a dónde deben quedar.
- Confirmar `site-url` en `_quarto.yml` si el dominio final no es
  `datopedia.org`.
