# =============================================================================
# 00_utils/normalizar_ubigeo.R
#
# Lógica compartida para cruzar cualquier dataset que traiga nombres de
# Departamento/Provincia/Distrito en texto libre contra la tabla oficial de
# UBIGEO (data/interim/ubigeos_2025.csv), y asignarle el código UBIGEO en
# cada nivel.
#
# Se extrajo del pipeline de conflictos sociales para reutilizarla en
# cualquier dataset nuevo que necesite el mismo cruce (el propio script
# original ya lo señalaba: "misma lógica de normalización/homónimos usada
# para el dataset de población").
#
# Uso típico dentro de un 01_procesar_<dataset>.R:
#
#   source("R/00_utils/normalizar_ubigeo.R")
#
#   ubigeo <- cargar_ubigeo("data/interim/ubigeos_2025.csv")
#
#   resultado <- cruzar_ubigeo(
#     df                       = mi_dataset,
#     ubigeo                   = ubigeo,
#     col_departamento         = "DEPARTAMENTO",
#     col_provincia            = "PROVINCIA",
#     col_distrito              = "DISTRITO",
#     crosswalk_departamentos  = mi_crosswalk_departamentos,   # opcional
#     crosswalk_provincias     = mi_crosswalk_provincias,      # opcional
#     crosswalk_distritos      = mi_crosswalk_distritos        # opcional
#   )
#
#   mi_dataset <- resultado$data
#   resultado$sin_ubigeo_distrito   # diagnóstico: distritos que no cruzaron
#
# Cada dataset define SUS PROPIOS crosswalks (variantes de escritura que le
# son propias, p. ej. "Surco" -> "Santiago de Surco" en conflictos sociales)
# y se los pasa a cruzar_ubigeo(); el caso especial de "Provincia
# Constitucional del Callao" (una sola provincia por departamento) es
# genérico y se resuelve automáticamente para cualquier dataset.
# =============================================================================

library(dplyr)
library(stringr)
library(stringi)
library(readr)
library(tibble)

#' Normaliza un texto para usarlo como llave de cruce geográfico:
#' mayúsculas, sin tildes/diéresis/ñ, sin paréntesis ni puntuación, sin
#' espacios dobles.
normalizar <- function(x) {
  x %>%
    str_trim() %>%
    str_to_upper() %>%
    stri_trans_general("Latin-ASCII") %>%
    str_replace_all("\\([^)]*\\)", " ") %>%
    str_replace_all("[._-]", " ") %>%
    str_replace_all("[^A-Z0-9 ]", " ") %>%
    str_squish()
}

#' Carga la tabla oficial de UBIGEO y le agrega las llaves normalizadas
#' (dep_key/prov_key/dist_key) que usa cruzar_ubigeo(). Aplica el caso
#' especial del Callao (una sola provincia) de una vez para toda la tabla.
#'
#' @param path Ruta al CSV de ubigeos, con columnas
#'   DEPARTAMENTO_NOMBRE, PROVINCIA_NOMBRE, DISTRITO_NOMBRE (texto) y
#'   DEPARTAMENTO, PROVINCIA, UBIGEO (códigos, como texto para no perder ceros).
cargar_ubigeo <- function(path) {
  ubigeo <- read_csv(
    path,
    locale = locale(encoding = "UTF-8"),
    col_types = cols(.default = "c")
  ) %>%
    mutate(across(
      c(DEPARTAMENTO_NOMBRE, PROVINCIA_NOMBRE, DISTRITO_NOMBRE),
      str_trim
    )) %>%
    mutate(
      dep_key  = normalizar(DEPARTAMENTO_NOMBRE),
      prov_key = normalizar(PROVINCIA_NOMBRE),
      dist_key = normalizar(DISTRITO_NOMBRE)
    ) %>%
    mutate(prov_key = if_else(dep_key == "CALLAO", "CALLAO", prov_key))

  ubigeo
}

#' Cruza un dataset contra la tabla de UBIGEO por nombre de
#' Departamento/Provincia/Distrito y le agrega UBIGEO_DEPARTAMENTO,
#' UBIGEO_PROVINCIA y UBIGEO_DISTRITO.
#'
#' @param df Dataset a cruzar. Debe tener columnas de texto con los nombres
#'   de departamento/provincia/distrito (los nombres de columna se indican
#'   con col_departamento/col_provincia/col_distrito).
#' @param ubigeo Tabla cargada con cargar_ubigeo().
#' @param col_departamento,col_provincia,col_distrito Nombres de columna en
#'   `df` (como string) que traen esos campos.
#' @param crosswalk_departamentos tibble opcional con columnas
#'   dep_key_conf, dep_key_ubi — variantes de escritura de departamento
#'   propias de este dataset.
#' @param crosswalk_provincias tibble opcional con columnas
#'   dep_key, prov_key_conf, prov_key_ubi — variantes de provincia, acotadas
#'   a un departamento para no confundir homónimos entre departamentos.
#' @param crosswalk_distritos tibble opcional con columnas
#'   dep_key, prov_key, dist_key_conf, dist_key_ubi — variantes de distrito,
#'   acotadas a dep+prov para no confundir homónimos (p. ej. dos distritos
#'   llamados "Surco" en provincias distintas).
#'
#' @return list(data = df con columnas UBIGEO_* agregadas y sin columnas de
#'   llave residuales, sin_ubigeo_distrito = tibble de diagnóstico con los
#'   distritos que no cruzaron y una sugerencia si aparece un dep+distrito
#'   compatible en la tabla oficial).
cruzar_ubigeo <- function(df,
                           ubigeo,
                           col_departamento = "DEPARTAMENTO",
                           col_provincia = "PROVINCIA",
                           col_distrito = "DISTRITO",
                           crosswalk_departamentos = NULL,
                           crosswalk_provincias = NULL,
                           crosswalk_distritos = NULL) {

  df <- df %>%
    mutate(
      dep_key  = normalizar(.data[[col_departamento]]),
      prov_key = normalizar(.data[[col_provincia]]),
      dist_key = normalizar(.data[[col_distrito]])
    ) %>%
    mutate(prov_key = if_else(dep_key == "CALLAO", "CALLAO", prov_key))

  if (!is.null(crosswalk_departamentos)) {
    df <- df %>%
      left_join(crosswalk_departamentos, by = c("dep_key" = "dep_key_conf")) %>%
      mutate(dep_key = coalesce(dep_key_ubi, dep_key)) %>%
      select(-dep_key_ubi)
  }
  if (!is.null(crosswalk_provincias)) {
    df <- df %>%
      left_join(crosswalk_provincias, by = c("dep_key", "prov_key" = "prov_key_conf")) %>%
      mutate(prov_key = coalesce(prov_key_ubi, prov_key)) %>%
      select(-prov_key_ubi)
  }
  if (!is.null(crosswalk_distritos)) {
    df <- df %>%
      left_join(crosswalk_distritos, by = c("dep_key", "prov_key", "dist_key" = "dist_key_conf")) %>%
      mutate(dist_key = coalesce(dist_key_ubi, dist_key)) %>%
      select(-dist_key_ubi)
  }

  ubigeo_departamento <- ubigeo %>%
    distinct(dep_key, .keep_all = TRUE) %>%
    select(dep_key, UBIGEO_DEPARTAMENTO = DEPARTAMENTO)

  ubigeo_provincia <- ubigeo %>%
    distinct(dep_key, prov_key, .keep_all = TRUE) %>%
    mutate(UBIGEO_PROVINCIA = paste0(DEPARTAMENTO, PROVINCIA)) %>%
    select(dep_key, prov_key, UBIGEO_PROVINCIA)

  ubigeo_distrito <- ubigeo %>%
    select(dep_key, prov_key, dist_key, UBIGEO_DISTRITO = UBIGEO)

  df <- df %>%
    left_join(ubigeo_departamento, by = "dep_key") %>%
    left_join(ubigeo_provincia, by = c("dep_key", "prov_key")) %>%
    left_join(ubigeo_distrito, by = c("dep_key", "prov_key", "dist_key"))

  col_dep_original <- col_departamento
  col_dist_original <- col_distrito

  cat("\nCasos sin UBIGEO_DEPARTAMENTO:", sum(is.na(df$UBIGEO_DEPARTAMENTO)), "\n")
  cat("Casos sin UBIGEO_PROVINCIA (excluye provincia vacía en la fuente):",
      sum(is.na(df$UBIGEO_PROVINCIA) & !is.na(df$prov_key)), "\n")
  cat("Casos sin UBIGEO_DISTRITO (excluye distrito vacío en la fuente):",
      sum(is.na(df$UBIGEO_DISTRITO) & !is.na(df$dist_key)), "\n")

  sin_ubigeo_distrito <- df %>%
    filter(is.na(UBIGEO_DISTRITO) & !is.na(dist_key)) %>%
    distinct(.data[[col_dep_original]], .data[[col_provincia]], .data[[col_dist_original]],
             dep_key, dist_key)

  if (nrow(sin_ubigeo_distrito) > 0) {
    cat("Distritos sin UBIGEO (revisar: puede ser variante de nombre nueva o\n")
    cat("la provincia indicada en la fuente no es la oficial de ese distrito):\n")

    sin_ubigeo_distrito <- sin_ubigeo_distrito %>%
      left_join(
        ubigeo %>% distinct(dep_key, dist_key, .keep_all = TRUE) %>%
          select(dep_key, dist_key, PROVINCIA_SUGERIDA = PROVINCIA_NOMBRE, UBIGEO_SUGERIDO = UBIGEO),
        by = c("dep_key", "dist_key")
      ) %>%
      select(-dep_key, -dist_key)

    print(sin_ubigeo_distrito)
  }

  df <- df %>% select(-dep_key, -prov_key, -dist_key)

  list(data = df, sin_ubigeo_distrito = sin_ubigeo_distrito)
}
