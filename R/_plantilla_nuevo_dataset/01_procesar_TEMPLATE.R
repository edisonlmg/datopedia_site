# =============================================================================
# R/_plantilla_nuevo_dataset/01_procesar_TEMPLATE.R
#
# PLANTILLA — copiar esta carpeta a R/<slug-del-dataset>/ y renombrar este
# archivo a 01_procesar_<dataset>.R. No se ejecuta como parte del sitio: es
# el punto de partida para el siguiente dataset a liberar.
#
# Convención de todo pipeline de dataset en Datopedia (dos pasos):
#   01_procesar_<dataset>.R   Fuente(s) cruda(s) -> data.frame limpio y
#                             documentado -> guardado como .rds intermedio
#                             en data/processed/<slug>/.
#   02_publicar_<dataset>.R   Lee el .rds, documenta columnas y llama a
#                             publicar_dataset() (R/00_utils/publicar_dataset.R)
#                             para generar el CSV + diccionario.md en
#                             datasets/<slug>/, y el bloque YAML para
#                             data/datasets.yml.
#
# Por qué dos pasos y no uno: el procesamiento (parsear PDFs/Excel/KML,
# cruces, limpieza) suele ser lento y es el que más se repite al iterar;
# separarlo de la publicación permite ajustar la documentación o el catálogo
# sin tener que reprocesar la fuente cruda cada vez.
#
# Correr desde la raíz del proyecto:
#   Rscript R/<slug-del-dataset>/01_procesar_<dataset>.R
# =============================================================================

library(tidyverse)
library(fs)

# Si el dataset necesita UBIGEO de departamento/provincia/distrito, reutiliza
# la utilidad compartida en vez de reescribir el cruce:
# source("R/00_utils/normalizar_ubigeo.R")

# --- Configuración -----------------------------------------------------------
# Reemplaza "TEMPLATE" por el slug real (el mismo que usarás en
# datasets.yml y en datasets/<slug>/).

carpeta_raw <- path("data/raw/TEMPLATE/")
archivo_procesado_rds <- path("data/processed/TEMPLATE/data_TEMPLATE.rds")

# --- 1. Leer la(s) fuente(s) cruda(s) -----------------------------------------
# Ejemplos según el tipo de fuente:
#   - PDF con tablas:  usar {pdftools} o {tabulizer} para extraer texto/tablas.
#   - Excel de reporte físico (con celdas combinadas, encabezados repetidos):
#     usar {readxl} + limpieza manual del rango útil.
#   - KML: ver R/conflictos-sociales/01_procesar_conflictos.R como referencia
#     completa de extracción de Placemarks con {xml2}.

# datos_crudos <- ...

# --- 2. Limpiar y estandarizar -------------------------------------------------
# - Nombres de columna en MAYÚSCULAS_CON_GUION_BAJO, sin tildes ni espacios.
# - Homologar "" a NA real (as.na si la fuente usa cadenas vacías).
# - Si hay geografía en texto libre, cruzar contra UBIGEO con
#   cargar_ubigeo() + cruzar_ubigeo() (ver R/00_utils/normalizar_ubigeo.R).

# dataset_limpio <- datos_crudos %>%
#   ...

# --- 3. Exportar insumo intermedio --------------------------------------------
# dir.create(dirname(archivo_procesado_rds), recursive = TRUE, showWarnings = FALSE)
# saveRDS(dataset_limpio, archivo_procesado_rds)
#
# cat("\nArchivo generado:", as.character(archivo_procesado_rds), "\n")
# cat("Siguiente paso: Rscript R/TEMPLATE/02_publicar_TEMPLATE.R\n")
