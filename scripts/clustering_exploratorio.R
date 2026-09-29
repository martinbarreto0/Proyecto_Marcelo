# Actividad 2 - Clustering exploratorio de dias agroclimaticos
# Pregunta: ¿Que tipos de dias agroclimaticos se observan en La Estanzuela?
# Cada fila sera un dia. No existe variable objetivo: k-means agrupa por similitud.

# GUIA: <- asigna; %>% encadena transformaciones; ~ define una formula;
# + agrega capas a un grafico; == compara igualdad; $ extrae una columna.
# | significa "o" logico; ! niega una condicion; / divide; .x representa el
# valor actual dentro de map_dbl(); [ , "sil_width"] selecciona una columna
# de una matriz; :: no se necesita porque los paquetes se cargan con library().
.libPaths(c("r_packages", .libPaths()))

library(tidyverse)
library(lubridate)
library(cluster)

# Todas las salidas se separan por etapa, pero este es el unico script de clustering.
dir.create("outputs/clustering/exploracion/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/exploracion/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/seleccion_k/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/seleccion_k/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/modelo_final/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/modelo_final/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/clustering/resumen_final", recursive = TRUE, showWarnings = FALSE)

# BLOQUE 1 - Definir la estacion y las variables de trabajo.
estacion_elegida <- "La Estanzuela"
# read_csv() importa el archivo separado por comas. show_col_types = FALSE solo
# evita que readr imprima los tipos de columna en consola.
inia <- read_csv("data/INIA.csv", show_col_types = FALSE)

# transmute() conserva y renombra solamente columnas relevantes.
datos_cluster <- inia %>%
  filter(EstacionAgr == estacion_elegida) %>%
  transmute(
    Fecha = make_date(Anio, Mes, Dia),
    anio = Anio,
    mes = factor(Mes, levels = 1:12),
    estacion = EstacionAgr,
    temp_aire_media = TempAireMedia,
    hr_media = HRMed,
    heliofania = `Heliofania(hrs)`,
    precipitacion = PrecipAcum,
    recorrido_viento = RecorridoViento
  )

cat("Estacion:", estacion_elegida, "\n")
cat("Registros originales:", nrow(datos_cluster), "\n")
cat("Periodo:", format(min(datos_cluster$Fecha)), "a", format(max(datos_cluster$Fecha), "%Y-%m-%d"), "\n")

# BLOQUE 2 - Calidad, faltantes y transformacion de precipitacion.
# La HR debe estar entre 0 y 100. El operador | significa "o".
# if_else(condicion, valor_si_verdadero, valor_si_falso) reemplaza solo los invalidos.
datos_cluster <- datos_cluster %>%
  mutate(
    hr_media_invalida = hr_media < 0 | hr_media > 100,
    hr_media = if_else(hr_media_invalida, NA_real_, hr_media)
  )

faltantes <- datos_cluster %>%
# across() repite el mismo conteo para las cinco variables; is.na() devuelve TRUE
# para un faltante y sum() cuenta esos TRUE.
  summarise(
    across(
      c(temp_aire_media, hr_media, heliofania, precipitacion, recorrido_viento),
      ~ sum(is.na(.x))
    ),
    humedad_invalida = sum(hr_media_invalida)
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "cantidad"
  )

print(faltantes)
# write_csv() guarda una tabla sin modificar el objeto que sigue en memoria.
write_csv(faltantes, "outputs/clustering/exploracion/reportes/faltantes_y_validacion.csv")

# drop_na() deja solo observaciones completas. log1p(x) es log(1 + x), por lo
# que admite los dias sin lluvia y reduce la influencia de las lluvias extremas.
datos_cluster_completos <- datos_cluster %>%
  drop_na(temp_aire_media, hr_media, heliofania, precipitacion, recorrido_viento) %>%
  mutate(log_precipitacion = log1p(precipitacion))

registros_excluidos <- tibble(
  registros_originales = nrow(datos_cluster),
  registros_utilizados = nrow(datos_cluster_completos),
  registros_excluidos = nrow(datos_cluster) - nrow(datos_cluster_completos)
)

print(registros_excluidos)
write_csv(registros_excluidos, "outputs/clustering/exploracion/reportes/registros_utilizados.csv")

# Fecha y mes se conservan para interpretar, pero no entran en el calculo de distancias.
variables_cluster <- datos_cluster_completos %>%
  select(temp_aire_media, hr_media, heliofania, log_precipitacion, recorrido_viento)

resumen_variables <- variables_cluster %>%
# pivot_longer() permite aplicar el mismo resumen a todas las columnas. quantile()
# calcula percentiles; .01 y .99 equivalen a los percentiles 1 y 99.
  pivot_longer(cols = everything(), names_to = "variable", values_to = "valor") %>%
  group_by(variable) %>%
  summarise(
    registros = n(), minimo = min(valor), p01 = quantile(valor, .01),
    media = mean(valor), mediana = median(valor), p99 = quantile(valor, .99),
    maximo = max(valor), desviacion = sd(valor), .groups = "drop"
  )

print(resumen_variables)
write_csv(resumen_variables, "outputs/clustering/exploracion/reportes/resumen_variables.csv")

# Se registran extremos en vez de eliminarlos automaticamente.
extremos_precipitacion <- datos_cluster_completos %>%
  arrange(desc(precipitacion)) %>%
  select(Fecha, precipitacion, temp_aire_media, hr_media, heliofania, recorrido_viento) %>%
  slice_head(n = 10)

extremos_viento <- datos_cluster_completos %>%
  arrange(desc(recorrido_viento)) %>%
  select(Fecha, recorrido_viento, precipitacion, temp_aire_media, hr_media, heliofania) %>%
  slice_head(n = 10)

write_csv(extremos_precipitacion, "outputs/clustering/exploracion/reportes/extremos_precipitacion.csv")
write_csv(extremos_viento, "outputs/clustering/exploracion/reportes/extremos_viento.csv")

variables_largas <- variables_cluster %>%
  pivot_longer(cols = everything(), names_to = "variable", values_to = "valor")

# ggplot() define los datos y aes() indica el eje x. Cada + agrega una capa.
# facet_wrap() crea un panel por variable y scales = "free" adapta su escala.
grafico_distribuciones <- ggplot(variables_largas, aes(x = valor)) +
  geom_histogram(bins = 30) +
  facet_wrap(~ variable, scales = "free") +
  labs(title = "Distribuciones de variables de clustering", x = "Valor", y = "Frecuencia") +
  theme_minimal()

# print() fuerza la visualizacion al ejecutar con Rscript; ggsave() escribe el PNG.
print(grafico_distribuciones)
ggsave("outputs/clustering/exploracion/graficos/distribuciones_variables.png",
       grafico_distribuciones, width = 12, height = 8, dpi = 300)

# Este grafico en escala original documenta por que se utilizo la transformacion logaritmica.
grafico_precipitacion <- ggplot(datos_cluster_completos, aes(x = precipitacion)) +
  geom_histogram(bins = 30) +
  labs(title = "Distribucion de precipitacion diaria", x = "Precipitacion (mm)", y = "Frecuencia") +
  theme_minimal()

print(grafico_precipitacion)
ggsave("outputs/clustering/exploracion/graficos/distribucion_precipitacion_original.png",
       grafico_precipitacion, width = 10, height = 6, dpi = 300)

# BLOQUE 3 - Estandarizacion y seleccion de k.
# scale() deja cada columna aproximadamente con media 0 y desviacion estandar 1.
# Asi el viento no pesa mas que otras variables solo por usar numeros grandes.
variables_escaladas <- scale(variables_cluster)

verificacion_escalado <- tibble(
  variable = colnames(variables_escaladas),
  media = colMeans(variables_escaladas),
  desviacion = apply(variables_escaladas, 2, sd)
)

print(verificacion_escalado)
write_csv(verificacion_escalado, "outputs/clustering/seleccion_k/reportes/verificacion_escalado.csv")

# Metodo del codo: tot.withinss mide variabilidad interna; disminuye al crecer k.
# nstart = 25 prueba multiples inicializaciones y set.seed() permite repetir resultados.
resultados_codo <- tibble(k = 1:10) %>%
# map_dbl() ejecuta el bloque para cada k y devuelve un vector numerico. .x es el
# valor de k actual, usado como cantidad de centros en kmeans().
  mutate(
    withinss = map_dbl(
      k,
      ~ {
        set.seed(123)
        modelo <- kmeans(variables_escaladas, centers = .x, nstart = 25, iter.max = 100)
        modelo$tot.withinss
      }
    )
  )

print(resultados_codo)
write_csv(resultados_codo, "outputs/clustering/seleccion_k/reportes/metodo_codo.csv")

grafico_codo <- ggplot(resultados_codo, aes(x = k, y = withinss)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = 1:10) +
  labs(title = "Metodo del codo", x = "Cantidad de clusters (k)",
       y = "Variabilidad interna total") +
  theme_minimal()

print(grafico_codo)
ggsave("outputs/clustering/seleccion_k/graficos/metodo_codo.png",
       grafico_codo, width = 10, height = 6, dpi = 300)

# La matriz de distancias se calcula una sola vez y se reutiliza en silhouette.
distancias <- dist(variables_escaladas)

calcular_silhouette <- function(k, datos_escalados, distancias) {
# function() crea una funcion reutilizable; return implicito: la ultima expresion
# (mean) es el valor que devuelve la funcion.
  set.seed(123)
  modelo <- kmeans(datos_escalados, centers = k, nstart = 25, iter.max = 100)
  sil <- silhouette(modelo$cluster, distancias)
  mean(sil[, "sil_width"])
}

# k = 1 no permite medir separation entre grupos, por eso se comienza en 2.
comparacion_k <- tibble(k = 2:8) %>%
  mutate(silhouette = map_dbl(k, ~ calcular_silhouette(.x, variables_escaladas, distancias)))

print(comparacion_k)
write_csv(comparacion_k, "outputs/clustering/seleccion_k/reportes/silhouette_por_k.csv")

grafico_silhouette <- ggplot(comparacion_k, aes(x = k, y = silhouette)) +
  geom_line() + geom_point() +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Silhouette promedio segun k", x = "Cantidad de clusters (k)",
       y = "Silhouette promedio") +
  theme_minimal()

print(grafico_silhouette)
ggsave("outputs/clustering/seleccion_k/graficos/silhouette_por_k.png",
       grafico_silhouette, width = 10, height = 6, dpi = 300)

# Regla reproducible inicial: usar el mayor silhouette y luego contrastarlo con el codo.
k_elegido <- comparacion_k %>%
# slice_max() busca la fila con mayor silhouette; with_ties = FALSE evita empates.
  slice_max(silhouette, n = 1, with_ties = FALSE) %>%
  pull(k)

fila_k_elegido <- comparacion_k %>% filter(k == k_elegido)
cat("k elegido por silhouette promedio:", k_elegido, "\n")
write_csv(fila_k_elegido, "outputs/clustering/seleccion_k/reportes/k_elegido.csv")

# BLOQUE 4 - Modelo final y perfiles.
set.seed(123)
# kmeans() asigna cada fila al centroide mas cercano y recalcula centroides hasta
# estabilizarse. centers es k, nstart son inicializaciones e iter.max evita cortar
# una solucion antes de que converja.
modelo_final <- kmeans(variables_escaladas, centers = k_elegido, nstart = 25, iter.max = 100)

# factor() convierte los numeros de grupo en etiquetas sin orden numerico.
resultado_cluster <- datos_cluster_completos %>%
  mutate(cluster = factor(modelo_final$cluster))

write_csv(resultado_cluster, "outputs/clustering/modelo_final/reportes/asignacion_clusters.csv")

tamanos_clusters <- resultado_cluster %>%
# count() cuenta filas por cluster. Luego proporcion divide cada conteo entre el
# total: el operador / calcula dicha fraccion.
  count(cluster, name = "registros") %>%
  mutate(proporcion = registros / sum(registros))

print(tamanos_clusters)
write_csv(tamanos_clusters, "outputs/clustering/modelo_final/reportes/tamanos_clusters.csv")

# Perfil en unidades originales: C, %, horas, mm y km/dia.
perfil_clusters <- resultado_cluster %>%
  group_by(cluster) %>%
  summarise(
    registros = n(),
    proporcion = n() / nrow(resultado_cluster),
    temp_aire_media = mean(temp_aire_media),
    hr_media = mean(hr_media),
    heliofania = mean(heliofania),
    precipitacion_media = mean(precipitacion),
    proporcion_dias_lluviosos = mean(precipitacion > 0),
    recorrido_viento = mean(recorrido_viento),
    .groups = "drop"
  )

# Las etiquetas se asignan solo despues de revisar el perfil. No participan en k-means.
perfil_clusters <- perfil_clusters %>%
  mutate(
    tipo_dia = case_when(
      cluster == "1" ~ "humedo_lluvioso_poca_insolacion",
      cluster == "2" ~ "seco_soleado",
      TRUE ~ "perfil_por_interpretar"
    )
  )

# Se agrega la etiqueta interpretativa a cada dia y se actualiza el archivo de asignacion.
resultado_cluster <- resultado_cluster %>%
  left_join(select(perfil_clusters, cluster, tipo_dia), by = "cluster")

write_csv(resultado_cluster, "outputs/clustering/modelo_final/reportes/asignacion_clusters.csv")

print(perfil_clusters)
write_csv(perfil_clusters, "outputs/clustering/modelo_final/reportes/perfil_clusters.csv")

# Los centroides estandarizados permiten comparar cuanto se aleja cada grupo de la media.
centroides_estandarizados <- as.data.frame(modelo_final$centers) %>%
  rownames_to_column("cluster")

write_csv(centroides_estandarizados,
          "outputs/clustering/modelo_final/reportes/centroides_estandarizados.csv")

centroides_largos <- centroides_estandarizados %>%
# El formato largo permite usar fill = cluster y mostrar ambos centroides en barras.
  pivot_longer(cols = -cluster, names_to = "variable", values_to = "centroide")

grafico_centroides <- ggplot(centroides_largos,
                             aes(x = variable, y = centroide, fill = cluster)) +
  geom_col(position = "dodge") +
  geom_hline(yintercept = 0) +
  labs(title = "Centroides estandarizados por cluster", x = "Variable",
       y = "Valor estandarizado", fill = "Cluster") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

print(grafico_centroides)
ggsave("outputs/clustering/modelo_final/graficos/centroides_estandarizados.png",
       grafico_centroides, width = 11, height = 6, dpi = 300)

# Estas proyecciones usan dos variables, aunque k-means calcula los grupos con las cinco.
grafico_temperatura_humedad <- ggplot(resultado_cluster,
                                      aes(x = temp_aire_media, y = hr_media, color = cluster)) +
  geom_point(alpha = 0.35) +
  labs(title = "Clusters: temperatura y humedad", x = "Temperatura media (C)",
       y = "Humedad relativa media (%)", color = "Cluster") +
  theme_minimal()

print(grafico_temperatura_humedad)
ggsave("outputs/clustering/modelo_final/graficos/temperatura_humedad_clusters.png",
       grafico_temperatura_humedad, width = 10, height = 6, dpi = 300)

grafico_heliofania_precipitacion <- ggplot(resultado_cluster,
                                            aes(x = heliofania, y = precipitacion, color = cluster)) +
  geom_point(alpha = 0.35) +
  labs(title = "Clusters: heliofania y precipitacion", x = "Heliofania (horas)",
       y = "Precipitacion acumulada (mm)", color = "Cluster") +
  theme_minimal()

print(grafico_heliofania_precipitacion)
ggsave("outputs/clustering/modelo_final/graficos/heliofania_precipitacion_clusters.png",
       grafico_heliofania_precipitacion, width = 10, height = 6, dpi = 300)

# mes no entra a k-means; se usa luego para investigar estacionalidad.
grafico_temporal <- ggplot(resultado_cluster,
                           aes(x = Fecha, y = temp_aire_media, color = cluster)) +
  geom_point(alpha = 0.50) +
  labs(title = "Clusters a lo largo del tiempo", x = "Fecha",
       y = "Temperatura media (C)", color = "Cluster") +
  theme_minimal()

print(grafico_temporal)
ggsave("outputs/clustering/modelo_final/graficos/clusters_en_el_tiempo.png",
       grafico_temporal, width = 12, height = 6, dpi = 300)

clusters_por_mes <- resultado_cluster %>%
# count() calcula cantidad por combinacion mes-cluster; group_by(mes) hace que
# sum(registros) sea el total de cada mes y no el total de toda la serie.
  count(mes, cluster, name = "registros") %>%
  group_by(mes) %>%
  mutate(proporcion = registros / sum(registros)) %>%
  ungroup()

write_csv(clusters_por_mes, "outputs/clustering/modelo_final/reportes/clusters_por_mes.csv")

grafico_clusters_mes <- ggplot(clusters_por_mes,
                               aes(x = mes, y = proporcion, fill = cluster)) +
  geom_col() +
  labs(title = "Proporcion de clusters por mes", x = "Mes", y = "Proporcion",
       fill = "Cluster") +
  theme_minimal()

print(grafico_clusters_mes)
ggsave("outputs/clustering/modelo_final/graficos/proporcion_clusters_por_mes.png",
       grafico_clusters_mes, width = 10, height = 6, dpi = 300)

# BLOQUE 5 - Sensibilidad a extremos de viento.
# Se repite el ajuste sin el 1% mayor. El modelo principal conserva todos los eventos.
umbral_viento_p99 <- quantile(datos_cluster_completos$recorrido_viento, 0.99)
# filter() conserva el 99% inferior de viento para esta comprobacion alternativa.
datos_sensibilidad <- datos_cluster_completos %>%
  filter(recorrido_viento <= umbral_viento_p99)

variables_sensibilidad <- datos_sensibilidad %>%
  select(temp_aire_media, hr_media, heliofania, log_precipitacion, recorrido_viento) %>%
  scale()

set.seed(123)
modelo_sensibilidad <- kmeans(variables_sensibilidad, centers = k_elegido, nstart = 25, iter.max = 100)

sensibilidad_extremos <- tibble(
  modelo = c("principal", "sin_1_por_ciento_viento_mayor"),
  registros = c(nrow(datos_cluster_completos), nrow(datos_sensibilidad)),
  k = c(k_elegido, k_elegido),
  withinss_por_registro = c(
    modelo_final$tot.withinss / nrow(datos_cluster_completos),
    modelo_sensibilidad$tot.withinss / nrow(datos_sensibilidad)
  )
)

write_csv(sensibilidad_extremos,
          "outputs/clustering/modelo_final/reportes/sensibilidad_extremos_viento.csv")

# BLOQUE 6 - Informe final. sprintf() inserta valores calculados en texto.
perfil_1 <- perfil_clusters %>% filter(cluster == "1")
perfil_2 <- perfil_clusters %>% filter(cluster == "2")

lineas_informe <- c(
# c() concatena textos en un vector; sprintf() inserta valores donde aparecen %s
# (texto o entero) y %.3f (numero con tres decimales).
  "# Actividad 2 - Clustering exploratorio de dias agroclimaticos",
  "",
  "## Pregunta",
  "¿Que tipos de dias agroclimaticos se pueden identificar en La Estanzuela?",
  "",
  "## Datos y variables",
  sprintf("- Cada observacion es un dia de %s.", estacion_elegida),
  sprintf("- Registros originales: %s; registros completos: %s.",
          nrow(datos_cluster), nrow(datos_cluster_completos)),
  "- Variables: temperatura media, humedad relativa media, heliofania, log(1 + precipitacion) y viento.",
  "- Fecha y mes se reservaron para interpretar, no para calcular distancias.",
  "",
  "## Metodo",
  "- Se corrigieron humedades fuera de 0-100% como faltantes y se uso log(1 + precipitacion).",
  "- Las variables se estandarizaron antes de aplicar k-means.",
  "- Se evaluo el codo para k = 1 a 10 y silhouette para k = 2 a 8.",
  sprintf("- Se eligio k = %s por mayor silhouette promedio (%.3f).",
          k_elegido, fila_k_elegido$silhouette),
  "- Este silhouette indica una separacion moderada: los perfiles son utiles, pero no son grupos perfectamente aislados.",
  "",
  "## Perfiles encontrados",
  sprintf("- Cluster 1 (%s): %.1f%% de los dias; mayor humedad (%.1f%%), menor heliofania (%.1f h) y mayor precipitacion media (%.2f mm).",
          perfil_1$tipo_dia, 100 * perfil_1$proporcion, perfil_1$hr_media,
          perfil_1$heliofania, perfil_1$precipitacion_media),
  sprintf("- Cluster 2 (%s): %.1f%% de los dias; menor humedad (%.1f%%), mayor heliofania (%.1f h) y baja precipitacion media (%.2f mm).",
          perfil_2$tipo_dia, 100 * perfil_2$proporcion, perfil_2$hr_media,
          perfil_2$heliofania, perfil_2$precipitacion_media),
  "",
  "## Interpretacion y limites",
  "- perfil_clusters.csv y centroides_estandarizados.csv documentan las etiquetas asignadas despues de caracterizar los grupos.",
  "- Los clusters representan similitud, no categorias verdaderas ni causalidad.",
  "- k-means depende de distancia, escala, valores extremos e inicializacion.",
  "- Se incluyo sensibilidad sin el 1% de mayor viento; el modelo principal conserva todos los eventos."
)

writeLines(lineas_informe, "outputs/clustering/resumen_final/informe_clustering.md", useBytes = TRUE)
