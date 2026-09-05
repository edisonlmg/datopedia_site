# =============================================================================
# R/conflictos-sociales/01_procesar_conflictos.R
#
# Extrae y consolida el "Reporte de Conflictos Sociales" mensual de la
# Defensoría del Pueblo (un .kml por mes, exportado de su visor) en un solo
# dataset tabular, y le asigna el UBIGEO de departamento/provincia/distrito.
#
# Entrada:
#   data/raw/conflictos-sociales/*.kml
#     — cada archivo nombrado, p. ej. "Reporte de Conflictos Sociales -
#       Enero 2026.kml" (el mes/año se extrae del nombre del archivo).
#   data/interim/ubigeos_2025.csv
#     — tabla oficial de UBIGEO (ver data/interim/README.md).
#
# Salida:
#   data/processed/conflictos-sociales/data_conflictos.rds
#     — insumo intermedio para 02_publicar_conflictos.R.
#
# Correr desde la raíz del proyecto (donde vive _quarto.yml), p. ej.:
#   Rscript R/conflictos-sociales/01_procesar_conflictos.R
# =============================================================================

library(tidyverse)
library(xml2)
library(fs)

source("R/00_utils/normalizar_ubigeo.R")

# --- Configuración -----------------------------------------------------------

carpeta_kml <- path("data/raw/conflictos-sociales/")
archivo_ubigeos <- path("data/interim/ubigeos_2025.csv")
archivo_conflictos_rds <- path("data/processed/conflictos-sociales/data_conflictos.rds")

meses <- c("Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto",
           "Setiembre","Septiembre","Octubre","Noviembre","Diciembre")

# --- Función: extraer mes y año del nombre del archivo -----------------------
extraer_mes_anio <- function(nombre_archivo) {
  base <- tools::file_path_sans_ext(basename(nombre_archivo))
  patron_meses <- paste(meses, collapse = "|")
  m <- regmatches(base, regexpr(paste0("(", patron_meses, ")\\s+(\\d{4})"), base, ignore.case = TRUE))
  if (length(m) == 0 || nchar(m) == 0) {
    return(c(Mes = NA_character_, Anio = NA_character_))
  }
  partes <- strsplit(trimws(m), "\\s+")[[1]]
  c(Mes = partes[1], Anio = partes[2])
}

# --- Función: extraer todos los placemarks de un KML como data.frame --------
extraer_kml <- function(kml_path) {
  doc <- read_xml(kml_path)
  ns  <- xml_ns(doc)  # namespace por defecto: http://www.opengis.net/kml/2.2

  placemarks <- xml_find_all(doc, ".//d1:Placemark", ns)

  extraer_placemark <- function(pm) {
    nombre    <- xml_text(xml_find_first(pm, ".//d1:name", ns))
    direccion <- xml_text(xml_find_first(pm, ".//d1:address", ns))  # sin lat/long, solo dirección de texto

    data_nodes <- xml_find_all(pm, ".//d1:ExtendedData/d1:Data", ns)
    campos <- setNames(
      sapply(data_nodes, function(d) xml_text(xml_find_first(d, ".//d1:value", ns))),
      sapply(data_nodes, function(d) xml_attr(d, "name"))
    )

    as.list(c(
      "Denominación del caso" = nombre,
      "Dirección (texto)" = direccion,
      campos
    ))
  }

  lista_casos <- lapply(placemarks, extraer_placemark)
  if (length(lista_casos) == 0) return(NULL)

  # Unificar en data.frame (por si algún placemark tuviera campos distintos)
  todas_cols <- unique(unlist(lapply(lista_casos, names)))
  filas <- lapply(lista_casos, function(x) {
    x_completo <- setNames(as.list(rep(NA, length(todas_cols))), todas_cols)
    x_completo[names(x)] <- x
    as.data.frame(x_completo, stringsAsFactors = FALSE, check.names = FALSE)
  })
  df <- do.call(rbind, filas)

  # El mapa repite los mismos casos en varias capas (Todos / Activos / Socioambientales),
  # por eso hay más placemarks que casos reales dentro de UN MISMO archivo.
  # Deduplicamos por nombre de caso dentro de este KML.
  df <- df[!duplicated(df[["Denominación del caso"]]), ]

  mes_anio <- extraer_mes_anio(kml_path)
  mes <- unname(mes_anio["Mes"])
  mes <- recode(mes, "Septiembre" = "Setiembre")

  df$Mes  <- match(
    mes,
    c(
      "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
      "Julio", "Agosto", "Setiembre", "Octubre",
      "Noviembre", "Diciembre"
    )
  )

  df$Anio <- as.integer(unname(mes_anio["Anio"]))

  df
}

# --- Procesar todos los KML de la carpeta y apilar ---------------------------
archivos_kml <- list.files(carpeta_kml, pattern = "\\.kml$", full.names = TRUE, ignore.case = TRUE)
cat("Archivos KML encontrados:", length(archivos_kml), "\n")
print(basename(archivos_kml))

if (length(archivos_kml) == 0) {
  stop(
    "No se encontraron .kml en ", carpeta_kml, ". ",
    "Coloca ahí los reportes mensuales (ver data/raw/conflictos-sociales/README.md)."
  )
}

resultados <- lapply(archivos_kml, function(f) {
  cat("Procesando:", basename(f), "... ")
  res <- tryCatch(extraer_kml(f), error = function(e) {
    cat("ERROR:", conditionMessage(e), "\n")
    NULL
  })
  if (!is.null(res)) cat(nrow(res), "casos únicos\n")
  res
})

resultados <- Filter(Negate(is.null), resultados)

# Unificar columnas entre archivos (por si algún mes trajera campos distintos) y apilar
todas_cols <- unique(unlist(lapply(resultados, names)))
resultados_completos <- lapply(resultados, function(df) {
  faltantes <- setdiff(todas_cols, names(df))
  for (col in faltantes) df[[col]] <- NA
  df[todas_cols]
})
conflictos_consolidado <- do.call(rbind, resultados_completos)
rownames(conflictos_consolidado) <- NULL
conflictos_consolidado <- as_tibble(conflictos_consolidado) %>%
  # El KML trae "" (no NA) cuando un campo viene vacío (p. ej. casos
  # multirregión sin Provincia/Distrito puntual). Se homologa a NA real
  # para que los diagnósticos y el cruce de UBIGEO no lo traten como dato.
  mutate(across(where(is.character), ~ na_if(str_trim(.x), "")))

cat("\nTotal de filas apiladas (todos los meses):", nrow(conflictos_consolidado), "\n")

# -----------------------------------------------------------------------------
# Nombres de columna en formato "variable": mayúsculas, sin tildes ni
# caracteres especiales, sin espacios (guion bajo). Los nombres largos u
# oscuros del KML original se resumen en una variable clara y corta.
# any_of() evita error si algún mes no trae todas las columnas.
# -----------------------------------------------------------------------------
nombres_nuevos <- c(
  ANIO                       = "Anio",
  MES                        = "Mes",
  CASO                       = "Denominación del caso",
  ESTADO                     = "Estado",
  TIPO                       = "Tipo",
  ACTIVIDAD                  = "Actividad",
  FASE_CASO_ACTIVO           = "Fases (casos activos)",
  EMPRESA                    = "Empresa involucrada",
  MOMENTO_DIALOGO            = "Momento del diálogo",
  MECANISMO_DIALOGO          = "Mecanismo del diálogo",
  HECHO_VIOLENCIA            = "Al menos tuvieron un hecho de violencia",
  PARTICIPACION_DP_DIALOGO   = "Participación de la DP en el espacio de diálogo",
  DIALOGO_POST_CRISIS        = "Diálogo después de hecho de violencia (crisis)",
  COMPETENCIA_GOBIERNO       = "Principal competencias por nivel de gobierno",
  PRESENCIA_DP               = "Presencia de la Defensoria del Pueblo",
  MULTIRREGION_NACIONAL      = "Multiregión o nacional",
  PAIS                       = "País",
  DEPARTAMENTO               = "Dpto.",
  PROVINCIA                  = "Provincia",
  DISTRITO                   = "Distrito",
  LOCALIDAD                  = "Localidad",
  OTROS_LUGARES              = "Otros lugares involucrados",
  DIRECCION                  = "Dirección (texto)",
  ARCHIVO_ORIGEN             = "Archivo origen"
)

conflictos_consolidado <- conflictos_consolidado %>%
  rename(any_of(nombres_nuevos))

# -----------------------------------------------------------------------------
# Cruce de UBIGEO (departamento/provincia/distrito), usando la utilidad
# compartida en R/00_utils/normalizar_ubigeo.R.
#
# Crosswalks propios de este dataset: variantes de escritura detectadas en
# el reporte de conflictos frente a ubigeos_2025 (se amplía aquí si aparecen
# nuevas al incorporar más meses — el diagnóstico impreso por cruzar_ubigeo()
# avisa cuándo hace falta).
# -----------------------------------------------------------------------------
ubigeo <- cargar_ubigeo(archivo_ubigeos)

crosswalk_departamentos <- tribble(
  ~dep_key_conf,          ~dep_key_ubi,
  "LIMA METROPOLITANA",   "LIMA",
  "LIMA PROVINCIAS",      "LIMA"
)
crosswalk_provincias <- tribble(
  ~dep_key,   ~prov_key_conf, ~prov_key_ubi,
  "ANCASH",   "EL SANTA",     "SANTA"
)

# "Surco" es el nombre coloquial de "Santiago de Surco" (Lima, prov. Lima).
# OJO: existe un distrito oficial distinto llamado literalmente "Surco" en
# otra provincia de Lima (Huarochirí, UBIGEO 150732, verificado contra
# ubigeos_2025.csv) -> por eso el crosswalk va acotado a dep+prov exactos,
# para no confundir un homónimo real con el otro.
crosswalk_distritos_conf <- tribble(
  ~dep_key, ~prov_key, ~dist_key_conf, ~dist_key_ubi,
  "LIMA",   "LIMA",    "SURCO",        "SANTIAGO DE SURCO"
)

resultado_ubigeo <- cruzar_ubigeo(
  df = conflictos_consolidado,
  ubigeo = ubigeo,
  col_departamento = "DEPARTAMENTO",
  col_provincia = "PROVINCIA",
  col_distrito = "DISTRITO",
  crosswalk_departamentos = crosswalk_departamentos,
  crosswalk_provincias = crosswalk_provincias,
  crosswalk_distritos = crosswalk_distritos_conf
)

conflictos_consolidado <- resultado_ubigeo$data
# resultado_ubigeo$sin_ubigeo_distrito queda disponible para revisar en
# consola si el diagnóstico impreso arriba reporta distritos sin cruzar.

# -----------------------------------------------------------------------------
# Orden final de columnas
# -----------------------------------------------------------------------------
cols_orden <- c(
  "ANIO", "MES",
  "CASO",
  "ESTADO", "TIPO", "ACTIVIDAD", "FASE_CASO_ACTIVO",
  "EMPRESA",
  "MOMENTO_DIALOGO", "MECANISMO_DIALOGO",
  "HECHO_VIOLENCIA", "PARTICIPACION_DP_DIALOGO", "DIALOGO_POST_CRISIS",
  "COMPETENCIA_GOBIERNO", "PRESENCIA_DP",
  "MULTIRREGION_NACIONAL",
  "PAIS",
  "DEPARTAMENTO", "UBIGEO_DEPARTAMENTO",
  "PROVINCIA", "UBIGEO_PROVINCIA",
  "DISTRITO", "UBIGEO_DISTRITO",
  "LOCALIDAD", "OTROS_LUGARES", "DIRECCION",
  "ARCHIVO_ORIGEN"
)

conflictos_consolidado <- conflictos_consolidado %>%
  select(any_of(cols_orden), everything()) %>%
  arrange(CASO, ANIO, MES)

# -----------------------------------------------------------------------------
# Exportar (insumo intermedio — el CSV público lo genera 02_publicar_conflictos.R)
# -----------------------------------------------------------------------------
dir.create(dirname(archivo_conflictos_rds), recursive = TRUE, showWarnings = FALSE)
saveRDS(conflictos_consolidado, archivo_conflictos_rds)

cat("\nArchivo generado:", as.character(archivo_conflictos_rds), "\n")
cat("Dimensiones finales:", nrow(conflictos_consolidado), "filas x", ncol(conflictos_consolidado), "columnas\n")
cat("Siguiente paso: Rscript R/conflictos-sociales/02_publicar_conflictos.R\n")
