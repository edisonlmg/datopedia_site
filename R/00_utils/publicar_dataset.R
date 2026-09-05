# =============================================================================
# 00_utils/publicar_dataset.R
#
# Paso final común a todo pipeline de dataset: toma un data.frame ya
# procesado y lo "publica" — lo deja listo para el catálogo de Datos
# Abiertos del sitio:
#
#   1. Escribe el CSV final en datasets/<slug>/<slug>.csv
#   2. Genera datasets/<slug>/diccionario.md a partir de las descripciones
#      de columna que le pases (una lista con nombre = columna, valor =
#      descripción) + el tipo de dato y el % de vacíos, calculados del
#      propio data.frame.
#   3. Imprime en consola el bloque YAML listo para pegar en
#      data/datasets.yml (no lo escribe solo, para no arriesgar el
#      formato/comentarios del archivo — se revisa y se pega a mano).
#
# Uso típico en un 02_publicar_<dataset>.R:
#
#   source("R/00_utils/publicar_dataset.R")
#
#   publicar_dataset(
#     df                  = mi_dataset,
#     slug                = "mi-dataset",
#     nombre              = "Nombre legible del dataset",
#     descripcion         = "Una o dos frases sobre qué es y de dónde sale.",
#     categoria           = "Categoría para el filtro del catálogo",
#     formato             = "csv",
#     fuente_original     = "De dónde salió originalmente (PDF/Excel/KML/...)",
#     fecha_actualizacion = "2026-09",
#     columnas            = list(
#       MI_COLUMNA = "Qué significa esta columna."
#     )
#   )
# =============================================================================

library(readr)
library(dplyr)
library(purrr)
library(glue)

#' @param df Data.frame ya procesado y listo para publicarse tal cual.
#' @param slug Identificador corto en minúsculas y con guiones, p. ej.
#'   "conflictos-sociales". Determina la carpeta datasets/<slug>/ y el
#'   nombre de archivo <slug>.csv (guiones -> guion bajo en el nombre de
#'   archivo, por convención de R: conflictos-sociales -> conflictos_sociales.csv).
#' @param nombre Nombre legible para el catálogo del sitio.
#' @param descripcion Descripción corta (1-2 frases) para el catálogo.
#' @param categoria Categoría para los botones de filtro del catálogo.
#' @param formato "csv" | "xlsx" | "kml" | "geojson".
#' @param fuente_original Descripción de la fuente no estructurada original.
#' @param fecha_actualizacion Texto libre, p. ej. "2026-09".
#' @param columnas Named list: nombre de columna -> descripción. Debe cubrir
#'   (idealmente) todas las columnas de `df`; las que falten se marcan como
#'   pendientes de documentar en el diccionario, para que no pasen
#'   desapercibidas.
#' @param repo Base del repositorio en GitHub, sin slash final. Se usa para
#'   armar las URLs del catálogo (raw + blob).
#' @param rama Rama del repositorio desde la que se sirven los archivos.
#' @param datasets_dir Carpeta raíz de datasets publicados (relativa al
#'   proyecto).
publicar_dataset <- function(df,
                              slug,
                              nombre,
                              descripcion,
                              categoria,
                              formato = "csv",
                              fuente_original,
                              fecha_actualizacion,
                              columnas = list(),
                              repo = "https://github.com/datopedia-pe/datopedia",
                              rama = "main",
                              datasets_dir = "datasets") {

  stopifnot(is.data.frame(df), nrow(df) > 0)

  archivo_slug <- gsub("-", "_", slug)
  carpeta <- file.path(datasets_dir, slug)
  dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

  # --- 1. CSV -------------------------------------------------------------
  archivo_csv <- file.path(carpeta, paste0(archivo_slug, ".csv"))
  write_excel_csv(df, archivo_csv, na = "")
  cat(glue("CSV escrito en: {archivo_csv} ({nrow(df)} filas x {ncol(df)} columnas)\n"))

  # --- 2. Diccionario de datos ---------------------------------------------
  sin_documentar <- setdiff(names(df), names(columnas))
  if (length(sin_documentar) > 0) {
    cat("Columnas sin descripción en `columnas` (quedarán como 'Pendiente de\n")
    cat("documentar' en el diccionario — complétalas en el script):\n")
    print(sin_documentar)
  }

  tipo_legible <- function(x) {
    dplyr::case_when(
      is.numeric(x)   ~ "numérico",
      is.integer(x)   ~ "entero",
      is.logical(x)   ~ "lógico (verdadero/falso)",
      inherits(x, "Date") ~ "fecha",
      TRUE            ~ "texto"
    )
  }

  filas_diccionario <- purrr::map_chr(names(df), function(col) {
    desc <- columnas[[col]]
    if (is.null(desc)) desc <- "_Pendiente de documentar._"
    tipo <- tipo_legible(df[[col]])
    pct_vacio <- round(100 * sum(is.na(df[[col]])) / nrow(df), 1)
    glue("| `{col}` | {tipo} | {desc} | {pct_vacio}% |")
  })

  diccionario_md <- glue(
    "# Diccionario de datos — {nombre}\n\n",
    "Fuente original: {fuente_original}\n\n",
    "Última actualización: {fecha_actualizacion}\n\n",
    "| Columna | Tipo | Descripción | % vacíos |\n",
    "|---|---|---|---|\n",
    "{paste(filas_diccionario, collapse = '\\n')}\n"
  )

  archivo_diccionario <- file.path(carpeta, "diccionario.md")
  writeLines(diccionario_md, archivo_diccionario, useBytes = TRUE)
  cat(glue("Diccionario escrito en: {archivo_diccionario}\n"))

  # --- 3. Bloque YAML para data/datasets.yml -------------------------------
  raw_base <- glue("https://raw.githubusercontent.com/{sub('https://github.com/', '', repo)}/{rama}")

  yaml_bloque <- glue(
    "\n  - id: {slug}\n",
    "    nombre: \"{nombre}\"\n",
    "    descripcion: >\n",
    "      {descripcion}\n",
    "    categoria: \"{categoria}\"\n",
    "    formato: {formato}\n",
    "    fuente_original: \"{fuente_original}\"\n",
    "    fecha_actualizacion: \"{fecha_actualizacion}\"\n",
    "    url_dataset: \"{raw_base}/{datasets_dir}/{slug}/{archivo_slug}.{formato}\"\n",
    "    url_diccionario: \"{repo}/blob/{rama}/{datasets_dir}/{slug}/diccionario.md\"\n",
    "    url_repo: \"{repo}/tree/{rama}/{datasets_dir}/{slug}\"\n"
  )

  cat("\n--- Pega este bloque en data/datasets.yml, bajo `datasets:` -------------\n")
  cat(yaml_bloque)
  cat("---------------------------------------------------------------------------\n")

  invisible(list(csv = archivo_csv, diccionario = archivo_diccionario, yaml = yaml_bloque))
}
