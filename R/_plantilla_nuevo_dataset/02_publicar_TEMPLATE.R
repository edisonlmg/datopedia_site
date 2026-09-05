# =============================================================================
# R/_plantilla_nuevo_dataset/02_publicar_TEMPLATE.R
#
# PLANTILLA — copiar junto con 01_procesar_TEMPLATE.R a R/<slug>/ y renombrar
# a 02_publicar_<dataset>.R.
#
# Lee el .rds de 01_procesar_<dataset>.R, documenta cada columna y llama a
# publicar_dataset(), que:
#   1. Escribe datasets/<slug>/<slug>.csv
#   2. Genera datasets/<slug>/diccionario.md a partir de `columnas`
#   3. Imprime el bloque YAML para pegar en data/datasets.yml
#
# Correr desde la raíz del proyecto, después de 01_procesar_<dataset>.R:
#   Rscript R/<slug-del-dataset>/02_publicar_<dataset>.R
# =============================================================================

library(dplyr)

source("R/00_utils/publicar_dataset.R")

dataset <- readRDS("data/processed/TEMPLATE/data_TEMPLATE.rds")

# -----------------------------------------------------------------------------
# Diccionario de datos: una entrada por columna. publicar_dataset() avisa en
# consola si `dataset` trae columnas que falten aquí, para que ninguna quede
# sin documentar en el catálogo público.
# -----------------------------------------------------------------------------
columnas <- list(
  # MI_COLUMNA = "Qué significa esta columna, en una frase clara."
)

publicar_dataset(
  df                  = dataset,
  slug                = "TEMPLATE",                 # minúsculas y guiones, p. ej. "presupuesto-participativo"
  nombre              = "Nombre legible para el catálogo",
  descripcion         = "Una o dos frases: qué es este dataset y de qué fuente no estructurada sale.",
  categoria           = "Categoría para el filtro del catálogo (p. ej. Presupuesto, Inversión pública)",
  formato             = "csv",                       # csv | xlsx | kml | geojson
  fuente_original     = "Descripción de la fuente original (informe PDF, Excel, visor KML, etc.)",
  fecha_actualizacion = format(Sys.Date(), "%Y-%m"),
  columnas            = columnas
)
