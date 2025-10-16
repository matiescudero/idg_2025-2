##################
## 1. Librerías ##
##################

library(DBI)
library(RPostgres)
library(sf)
library(ggplot2)

##########################
## 2. Configuración BD ##
#########################

db_host = "localhost"
db_port = 5434
db_name = "test_censo_v"
db_user = "postgres"
db_password = "postgres"

# Establecer conexión usando RPostgres
con = dbConnect(
  Postgres(),
  dbname   = db_name,
  host     = db_host,
  port     = db_port,
  user     = db_user,
  password = db_password
)

## Consulta SQL ##

sql_indicadores = "

SELECT
z.geocodigo::double precision AS geocodigo,
c.nom_comuna,

-- Porcentaje de migrantes
ROUND(
  COUNT(*) FILTER (WHERE p.p12 NOT IN (1, 2, 98, 99)) * 100.0
  / NULLIF(COUNT(*), 0),
  2) AS ptje_migrantes,

-- Porcentaje de personas con escolaridad mayor a 16 años
ROUND(
  COUNT(*) FILTER (WHERE p.escolaridad >= 16) * 100.0
  / NULLIF(COUNT(*) FILTER (WHERE p.escolaridad IS NOT NULL), 0),
  2) AS ptje_esc_mayor_16

FROM public.personas   AS p
JOIN public.hogares    AS h ON p.hogar_ref_id    = h.hogar_ref_id
JOIN public.viviendas  AS v ON h.vivienda_ref_id = v.vivienda_ref_id
JOIN public.zonas      AS z ON v.zonaloc_ref_id  = z.zonaloc_ref_id
JOIN public.comunas    AS c ON z.codigo_comuna   = c.codigo_comuna

GROUP BY z.geocodigo, c.nom_comuna
ORDER BY ptje_esc_mayor_16 DESC;

"

# Ejecutar la consulta 
df_indicadores = st_read(con, query = sql_indicadores)



