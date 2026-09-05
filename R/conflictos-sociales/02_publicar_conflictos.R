# =============================================================================
# R/conflictos-sociales/02_publicar_conflictos.R
#
# Toma el .rds generado por 01_procesar_conflictos.R, documenta cada columna
# y lo publica en datasets/conflictos-sociales/ (CSV + diccionario.md),
# usando la utilidad compartida R/00_utils/publicar_dataset.R.
#
# Al final imprime el bloque YAML para pegar en data/datasets.yml.
#
# Correr desde la raíz del proyecto, después de 01_procesar_conflictos.R:
#   Rscript R/conflictos-sociales/02_publicar_conflictos.R
# =============================================================================

library(dplyr)

source("R/00_utils/publicar_dataset.R")

conflictos <- readRDS("data/processed/conflictos-sociales/data_conflictos.rds")

# -----------------------------------------------------------------------------
# Diccionario de datos: descripción de cada columna del dataset publicado.
# Se usa tanto para generar datasets/conflictos-sociales/diccionario.md como
# para que publicar_dataset() avise si falta documentar alguna columna nueva.
# -----------------------------------------------------------------------------
columnas <- list(
  ANIO                      = "Año del reporte mensual del que proviene el registro.",
  MES                       = "Mes del reporte mensual (1 = enero ... 12 = diciembre).",
  CASO                      = "Nombre/denominación del caso de conflicto social, tal como lo registra la Defensoría del Pueblo.",
  ESTADO                    = "Estado del caso al momento del reporte (p. ej. activo, latente, resuelto).",
  TIPO                      = "Tipo de conflicto social (p. ej. socioambiental, laboral, comunal, etc.).",
  ACTIVIDAD                 = "Actividad económica u origen del conflicto (p. ej. minería, hidrocarburos), cuando aplica.",
  FASE_CASO_ACTIVO          = "Fase del caso, solo para casos activos (p. ej. diálogo, escalamiento, crisis).",
  EMPRESA                   = "Empresa involucrada en el conflicto, cuando el caso identifica una.",
  MOMENTO_DIALOGO           = "Momento del diálogo entre las partes, si existe un espacio de diálogo.",
  MECANISMO_DIALOGO         = "Mecanismo o instancia de diálogo empleado.",
  HECHO_VIOLENCIA           = "Indica si el caso registró al menos un hecho de violencia.",
  PARTICIPACION_DP_DIALOGO  = "Indica si la Defensoría del Pueblo participó en el espacio de diálogo.",
  DIALOGO_POST_CRISIS       = "Indica si hubo diálogo después de un hecho de violencia (crisis).",
  COMPETENCIA_GOBIERNO      = "Nivel(es) de gobierno con la principal competencia sobre el caso.",
  PRESENCIA_DP              = "Indica si la Defensoría del Pueblo tiene presencia directa en el caso.",
  MULTIRREGION_NACIONAL     = "Indica si el caso es multirregional o de alcance nacional (no puntual a un distrito).",
  PAIS                      = "País del caso (todos los casos de este dataset corresponden a Perú).",
  DEPARTAMENTO              = "Nombre del departamento donde ocurre el caso, tal como lo reporta la Defensoría.",
  UBIGEO_DEPARTAMENTO       = "Código UBIGEO (INEI) del departamento, asignado por cruce de nombre.",
  PROVINCIA                 = "Nombre de la provincia donde ocurre el caso.",
  UBIGEO_PROVINCIA          = "Código UBIGEO (INEI) de la provincia, asignado por cruce de nombre.",
  DISTRITO                  = "Nombre del distrito donde ocurre el caso, cuando el caso es puntual a un distrito.",
  UBIGEO_DISTRITO           = "Código UBIGEO (INEI) del distrito, asignado por cruce de nombre.",
  LOCALIDAD                 = "Localidad o centro poblado específico, cuando el reporte lo indica.",
  OTROS_LUGARES             = "Otros lugares involucrados en el caso, cuando aplica.",
  DIRECCION                 = "Dirección en texto libre indicada en el KML (el reporte no trae coordenadas por caso).",
  ARCHIVO_ORIGEN            = "Nombre del archivo KML mensual del que se extrajo el registro."
)

publicar_dataset(
  df                  = conflictos,
  slug                = "conflictos-sociales",
  nombre              = "Conflictos sociales registrados por la Defensoría del Pueblo",
  descripcion         = "Casos de conflicto social reportados mensualmente por la Defensoría del Pueblo, consolidados a partir de los KML de su visor y con UBIGEO de departamento, provincia y distrito asignado por cruce de nombre.",
  categoria           = "Conflictividad social",
  formato             = "csv",
  fuente_original     = "Reporte mensual de Conflictos Sociales (KML del visor de la Defensoría del Pueblo)",
  fecha_actualizacion = format(Sys.Date(), "%Y-%m"),
  columnas            = columnas
)
