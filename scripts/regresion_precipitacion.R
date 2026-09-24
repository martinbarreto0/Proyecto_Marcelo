# Actividad 1 - Regresion lineal sobre precipitacion acumulada diaria
# Bloque 1: carga, uniones y preparacion de la tabla de analisis

.libPaths(c("r_packages", .libPaths()))

library(tidyverse)
library(lubridate)

# Carpetas para resultados reproducibles del analisis.
# Se mantiene un unico script y se separan las salidas por etapa.
dir.create("outputs/exploracion/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/exploracion/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_simple/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_simple/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_multiple/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_multiple/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_logaritmico/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/modelo_logaritmico/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/comparacion_modelos/graficos", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/comparacion_modelos/reportes", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/resumen_final", recursive = TRUE, showWarnings = FALSE)

# Cargar las tres fuentes de datos
inia <- read_csv("data/INIA.csv", show_col_types = FALSE)

estaciones <- read_csv(
  "data/EstacionAgr.csv",
  show_col_types = FALSE
)

departamentos <- read_delim(
  "data/Departamentos.csv",
  delim = ";",
  show_col_types = FALSE
)

# Incorporar a cada observacion su estacion y departamento
datos <- inia %>%
  left_join(estaciones, by = "EstacionAgr") %>%
  left_join(departamentos, by = "DepartamentoCodigo") %>%
  mutate(
    Fecha = make_date(Anio, Mes, Dia)
  )

# Tabla especifica para esta actividad.
# No se incluyen PrecipEfectiva ni Llovio porque se derivan de PrecipAcum.
# Se usa Heliofania y no RadSolar, ya que la segunda se calcula a partir de la primera.
analisis <- datos %>%
  transmute(
    Fecha,
    estacion = EstacionAgr,
    departamento = DepartamentoDescripcion,
    anio = Anio,
    mes = factor(Mes),
    precipitacion = PrecipAcum,
    hr_media = HRMed,
    heliofania = `Heliofania(hrs)`,
    recorrido_viento = RecorridoViento,
    temp_aire_media = TempAireMedia
  )

glimpse(analisis)

cat("Registros totales:", nrow(analisis), "\n")
cat("Estaciones sin departamento asignado:",
    sum(is.na(analisis$departamento)), "\n")

# Revision de faltantes solicitada antes de modelar
faltantes <- analisis %>%
  summarise(
    across(
      everything(),
      ~ sum(is.na(.x))
    )
  )

print(faltantes)

faltantes_largo <- faltantes %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "cantidad_faltantes"
  )

write_csv(
  faltantes_largo,
  "outputs/exploracion/reportes/faltantes_regresion.csv"
)

# Bloque 2: exploracion de la variable respuesta y de la relacion principal
resumen_precipitacion <- analisis %>%
  summarise(
    registros_con_precipitacion = sum(!is.na(precipitacion)),
    dias_sin_lluvia = sum(precipitacion == 0, na.rm = TRUE),
    proporcion_sin_lluvia = mean(precipitacion == 0, na.rm = TRUE),
    precipitacion_media = mean(precipitacion, na.rm = TRUE),
    precipitacion_mediana = median(precipitacion, na.rm = TRUE),
    precipitacion_maxima = max(precipitacion, na.rm = TRUE)
  )

print(resumen_precipitacion, width = Inf)

write_csv(
  resumen_precipitacion,
  "outputs/exploracion/reportes/resumen_precipitacion.csv"
)

# Histograma de precipitacion acumulada diaria
grafico_distribucion <- ggplot(
  analisis %>% drop_na(precipitacion),
  aes(x = precipitacion)
) +
  geom_histogram(binwidth = 1, boundary = 0) +
  labs(
    title = "Distribucion de la precipitacion acumulada diaria",
    x = "Precipitacion acumulada (mm)",
    y = "Cantidad de dias"
  ) +
  theme_minimal()

print(grafico_distribucion)

ggsave(
  filename = "outputs/exploracion/graficos/distribucion_precipitacion.png",
  plot = grafico_distribucion,
  width = 10,
  height = 6,
  dpi = 300
)

# Preparar las observaciones completas para el modelo simple.
# Se registra cuantas observaciones quedan disponibles antes de eliminar faltantes.
precipitacion_humedad <- analisis %>%
  drop_na(
    precipitacion,
    hr_media
  )

cat(
  "Registros disponibles para precipitacion y humedad:",
  nrow(precipitacion_humedad),
  "\n"
)

# Precipitacion y humedad relativa media
grafico_precipitacion_humedad <- ggplot(
  precipitacion_humedad,
  aes(
    x = hr_media,
    y = precipitacion
  )
) +
  geom_point(alpha = 0.25) +
  labs(
    title = "Precipitacion acumulada y humedad relativa media",
    x = "Humedad relativa media (%)",
    y = "Precipitacion acumulada (mm)"
  ) +
  theme_minimal()

print(grafico_precipitacion_humedad)

ggsave(
  filename = "outputs/exploracion/graficos/precipitacion_humedad.png",
  plot = grafico_precipitacion_humedad,
  width = 10,
  height = 6,
  dpi = 300
)

correlacion_precipitacion_humedad <- cor(
  precipitacion_humedad$precipitacion,
  precipitacion_humedad$hr_media
)

cat(
  "Correlacion entre precipitacion y humedad relativa media:",
  round(correlacion_precipitacion_humedad, 3),
  "\n"
)

correlacion <- tibble(
  variable_1 = "precipitacion",
  variable_2 = "hr_media",
  correlacion = correlacion_precipitacion_humedad
)

write_csv(
  correlacion,
  "outputs/exploracion/reportes/correlacion_precipitacion_humedad.csv"
)

# Bloque 2b: exploracion por grupos y por las variables explicativas seleccionadas
exploracion_completa <- analisis %>%
  drop_na(precipitacion)

resumen_por_mes <- exploracion_completa %>%
  group_by(mes) %>%
  summarise(
    registros = n(),
    precipitacion_media = mean(precipitacion),
    precipitacion_mediana = median(precipitacion),
    proporcion_dias_lluviosos = mean(precipitacion > 0),
    .groups = "drop"
  )

resumen_por_estacion <- exploracion_completa %>%
  group_by(estacion, departamento) %>%
  summarise(
    registros = n(),
    precipitacion_media = mean(precipitacion),
    precipitacion_mediana = median(precipitacion),
    proporcion_dias_lluviosos = mean(precipitacion > 0),
    .groups = "drop"
  )

write_csv(
  resumen_por_mes,
  "outputs/exploracion/reportes/resumen_precipitacion_por_mes.csv"
)

write_csv(
  resumen_por_estacion,
  "outputs/exploracion/reportes/resumen_precipitacion_por_estacion.csv"
)

grafico_precipitacion_mes <- ggplot(
  exploracion_completa,
  aes(
    x = mes,
    y = precipitacion
  )
) +
  geom_boxplot(outlier.alpha = 0.20) +
  labs(
    title = "Precipitacion acumulada por mes",
    x = "Mes",
    y = "Precipitacion acumulada (mm)"
  ) +
  theme_minimal()

print(grafico_precipitacion_mes)

ggsave(
  filename = "outputs/exploracion/graficos/precipitacion_por_mes.png",
  plot = grafico_precipitacion_mes,
  width = 10,
  height = 6,
  dpi = 300
)

grafico_precipitacion_estacion <- ggplot(
  exploracion_completa,
  aes(
    x = estacion,
    y = precipitacion
  )
) +
  geom_boxplot(outlier.alpha = 0.20) +
  labs(
    title = "Precipitacion acumulada por estacion",
    x = "Estacion",
    y = "Precipitacion acumulada (mm)"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 30, hjust = 1)
  )

print(grafico_precipitacion_estacion)

ggsave(
  filename = "outputs/exploracion/graficos/precipitacion_por_estacion.png",
  plot = grafico_precipitacion_estacion,
  width = 10,
  height = 6,
  dpi = 300
)

relaciones_predictores <- exploracion_completa %>%
  select(
    precipitacion,
    hr_media,
    heliofania,
    recorrido_viento,
    temp_aire_media
  ) %>%
  pivot_longer(
    cols = -precipitacion,
    names_to = "predictor",
    values_to = "valor_predictor"
  ) %>%
  drop_na(valor_predictor)

grafico_relaciones_predictores <- ggplot(
  relaciones_predictores,
  aes(
    x = valor_predictor,
    y = precipitacion
  )
) +
  geom_point(alpha = 0.15) +
  facet_wrap(
    ~ predictor,
    scales = "free_x"
  ) +
  labs(
    title = "Precipitacion y variables explicativas seleccionadas",
    x = "Valor de la variable explicativa",
    y = "Precipitacion acumulada (mm)"
  ) +
  theme_minimal()

print(grafico_relaciones_predictores)

ggsave(
  filename = "outputs/exploracion/graficos/relaciones_con_predictores.png",
  plot = grafico_relaciones_predictores,
  width = 12,
  height = 8,
  dpi = 300
)

# Bloque 3: regresion lineal simple
# La respuesta es la precipitacion acumulada diaria y la explicativa es la HR media.
modelo_simple <- lm(
  precipitacion ~ hr_media,
  data = precipitacion_humedad
)

print(summary(modelo_simple))

coeficientes_modelo_simple <- tibble(
  termino = names(coef(modelo_simple)),
  estimacion = as.numeric(coef(modelo_simple))
)

write_csv(
  coeficientes_modelo_simple,
  "outputs/modelo_simple/reportes/coeficientes_modelo_simple.csv"
)

resumen_modelo_simple <- summary(modelo_simple)
r2_simple <- resumen_modelo_simple$r.squared

cat("R cuadrado del modelo simple:", round(r2_simple, 3), "\n")

# Predicciones y residuos sobre los datos utilizados para ajustar este primer modelo
precipitacion_humedad <- precipitacion_humedad %>%
  mutate(
    precipitacion_predicha = predict(
      modelo_simple,
      newdata = precipitacion_humedad
    ),
    residuo = precipitacion - precipitacion_predicha
  )

metricas_ajuste_simple <- precipitacion_humedad %>%
  summarise(
    MAE = mean(abs(residuo)),
    RMSE = sqrt(mean(residuo^2)),
    R2 = r2_simple
  )

print(metricas_ajuste_simple)

write_csv(
  metricas_ajuste_simple,
  "outputs/modelo_simple/reportes/metricas_ajuste_modelo_simple.csv"
)

grafico_recta_simple <- ggplot(
  precipitacion_humedad,
  aes(
    x = hr_media,
    y = precipitacion
  )
) +
  geom_point(alpha = 0.20) +
  geom_smooth(
    method = "lm",
    se = FALSE,
    color = "blue"
  ) +
  labs(
    title = "Regresion lineal: precipitacion y humedad relativa media",
    x = "Humedad relativa media (%)",
    y = "Precipitacion acumulada (mm)"
  ) +
  theme_minimal()

print(grafico_recta_simple)

ggsave(
  filename = "outputs/modelo_simple/graficos/regresion_simple_precipitacion_humedad.png",
  plot = grafico_recta_simple,
  width = 10,
  height = 6,
  dpi = 300
)

grafico_residuos_simple <- ggplot(
  precipitacion_humedad,
  aes(
    x = precipitacion_predicha,
    y = residuo
  )
) +
  geom_point(alpha = 0.20) +
  geom_hline(
    yintercept = 0,
    color = "red"
  ) +
  labs(
    title = "Residuos del modelo simple",
    x = "Precipitacion predicha (mm)",
    y = "Residuo (mm)"
  ) +
  theme_minimal()

print(grafico_residuos_simple)

ggsave(
  filename = "outputs/modelo_simple/graficos/residuos_modelo_simple.png",
  plot = grafico_residuos_simple,
  width = 10,
  height = 6,
  dpi = 300
)

# Bloque 4: separar entrenamiento y evaluacion de forma cronologica
modelo_datos <- precipitacion_humedad %>%
  arrange(Fecha)

fechas_ordenadas <- modelo_datos %>%
  distinct(Fecha) %>%
  arrange(Fecha) %>%
  pull(Fecha)

corte <- floor(0.8 * length(fechas_ordenadas))
fecha_corte <- fechas_ordenadas[corte]

entrenamiento <- modelo_datos %>%
  filter(Fecha <= fecha_corte)

evaluacion <- modelo_datos %>%
  filter(Fecha > fecha_corte)

cat("Entrenamiento:", nrow(entrenamiento), "\n")
cat("Evaluacion:", nrow(evaluacion), "\n")

division_temporal <- tibble(
  conjunto = c("entrenamiento", "evaluacion"),
  registros = c(nrow(entrenamiento), nrow(evaluacion)),
  fecha_minima = c(min(entrenamiento$Fecha), min(evaluacion$Fecha)),
  fecha_maxima = c(max(entrenamiento$Fecha), max(evaluacion$Fecha))
)

write_csv(
  division_temporal,
  "outputs/modelo_simple/reportes/division_temporal.csv"
)

# El modelo se ajusta solamente con el conjunto de entrenamiento
modelo_simple_train <- lm(
  precipitacion ~ hr_media,
  data = entrenamiento
)

# Predicciones y residuos sobre datos no usados para el ajuste
evaluacion <- evaluacion %>%
  mutate(
    precipitacion_predicha = predict(
      modelo_simple_train,
      newdata = evaluacion
    ),
    residuo = precipitacion - precipitacion_predicha
  )

metricas_evaluacion_simple <- evaluacion %>%
  summarise(
    MAE = mean(abs(residuo)),
    RMSE = sqrt(mean(residuo^2))
  )

print(metricas_evaluacion_simple)

write_csv(
  metricas_evaluacion_simple,
  "outputs/modelo_simple/reportes/metricas_evaluacion_modelo_simple.csv"
)

# Comparar valores observados y predichos sobre el conjunto de evaluacion
grafico_observado_predicho <- ggplot(
  evaluacion,
  aes(
    x = precipitacion,
    y = precipitacion_predicha
  )
) +
  geom_point(alpha = 0.20) +
  geom_abline(
    slope = 1,
    intercept = 0,
    color = "red"
  ) +
  labs(
    title = "Precipitacion observada y predicha: conjunto de evaluacion",
    x = "Precipitacion observada (mm)",
    y = "Precipitacion predicha (mm)"
  ) +
  theme_minimal()

print(grafico_observado_predicho)

ggsave(
  filename = "outputs/modelo_simple/graficos/observado_predicho_evaluacion.png",
  plot = grafico_observado_predicho,
  width = 10,
  height = 6,
  dpi = 300
)

# Bloque 5: modelo de regresion lineal multiple
# Departamento no se incorpora porque cada estacion pertenece a un unico departamento.
datos_multiple <- analisis %>%
  drop_na(
    precipitacion,
    hr_media,
    heliofania,
    recorrido_viento,
    temp_aire_media,
    mes,
    estacion
  )

cat(
  "Registros disponibles para el modelo multiple:",
  nrow(datos_multiple),
  "\n"
)

# Revisar la relacion entre predictores numericos antes de incorporarlos juntos.
matriz_correlaciones_multiple <- datos_multiple %>%
  select(
    hr_media,
    heliofania,
    recorrido_viento,
    temp_aire_media
  ) %>%
  cor(use = "pairwise.complete.obs")

print(matriz_correlaciones_multiple)

correlaciones_multiple <- as.data.frame(matriz_correlaciones_multiple) %>%
  rownames_to_column("variable")

write_csv(
  correlaciones_multiple,
  "outputs/modelo_multiple/reportes/correlaciones_predictores.csv"
)

# Ajuste con todas las observaciones completas, para interpretar coeficientes y residuos.
modelo_multiple <- lm(
  precipitacion ~ hr_media + heliofania + recorrido_viento +
    temp_aire_media + mes + estacion,
  data = datos_multiple
)

print(summary(modelo_multiple))

coeficientes_modelo_multiple <- summary(modelo_multiple)$coefficients %>%
  as.data.frame() %>%
  rownames_to_column("termino")

write_csv(
  coeficientes_modelo_multiple,
  "outputs/modelo_multiple/reportes/coeficientes_modelo_multiple.csv"
)

resumen_modelo_multiple <- summary(modelo_multiple)

datos_multiple <- datos_multiple %>%
  mutate(
    precipitacion_predicha = predict(
      modelo_multiple,
      newdata = datos_multiple
    ),
    residuo = precipitacion - precipitacion_predicha
  )

metricas_ajuste_multiple <- datos_multiple %>%
  summarise(
    MAE = mean(abs(residuo)),
    RMSE = sqrt(mean(residuo^2)),
    R2 = resumen_modelo_multiple$r.squared
  )

print(metricas_ajuste_multiple)

write_csv(
  metricas_ajuste_multiple,
  "outputs/modelo_multiple/reportes/metricas_ajuste_modelo_multiple.csv"
)

grafico_residuos_multiple <- ggplot(
  datos_multiple,
  aes(
    x = precipitacion_predicha,
    y = residuo
  )
) +
  geom_point(alpha = 0.20) +
  geom_hline(
    yintercept = 0,
    color = "red"
  ) +
  labs(
    title = "Residuos del modelo multiple",
    x = "Precipitacion predicha (mm)",
    y = "Residuo (mm)"
  ) +
  theme_minimal()

print(grafico_residuos_multiple)

ggsave(
  filename = "outputs/modelo_multiple/graficos/residuos_modelo_multiple.png",
  plot = grafico_residuos_multiple,
  width = 10,
  height = 6,
  dpi = 300
)

# Division temporal sobre las mismas observaciones para comparar ambos modelos.
datos_multiple_ordenados <- datos_multiple %>%
  arrange(Fecha)

fechas_multiple <- datos_multiple_ordenados %>%
  distinct(Fecha) %>%
  arrange(Fecha) %>%
  pull(Fecha)

corte_multiple <- floor(0.8 * length(fechas_multiple))
fecha_corte_multiple <- fechas_multiple[corte_multiple]

entrenamiento_multiple <- datos_multiple_ordenados %>%
  filter(Fecha <= fecha_corte_multiple)

evaluacion_multiple <- datos_multiple_ordenados %>%
  filter(Fecha > fecha_corte_multiple)

modelo_simple_comparable <- lm(
  precipitacion ~ hr_media,
  data = entrenamiento_multiple
)

modelo_multiple_train <- lm(
  precipitacion ~ hr_media + heliofania + recorrido_viento +
    temp_aire_media + mes + estacion,
  data = entrenamiento_multiple
)

evaluacion_multiple <- evaluacion_multiple %>%
  mutate(
    prediccion_simple = predict(
      modelo_simple_comparable,
      newdata = evaluacion_multiple
    ),
    prediccion_multiple = predict(
      modelo_multiple_train,
      newdata = evaluacion_multiple
    )
  )

metricas_comparacion <- bind_rows(
  evaluacion_multiple %>%
    summarise(
      modelo = "simple",
      MAE = mean(abs(precipitacion - prediccion_simple)),
      RMSE = sqrt(mean((precipitacion - prediccion_simple)^2))
    ),
  evaluacion_multiple %>%
    summarise(
      modelo = "multiple",
      MAE = mean(abs(precipitacion - prediccion_multiple)),
      RMSE = sqrt(mean((precipitacion - prediccion_multiple)^2))
    )
)

print(metricas_comparacion)

write_csv(
  metricas_comparacion,
  "outputs/comparacion_modelos/reportes/metricas_modelos.csv"
)

grafico_multiple_observado_predicho <- ggplot(
  evaluacion_multiple,
  aes(
    x = precipitacion,
    y = prediccion_multiple
  )
) +
  geom_point(alpha = 0.20) +
  geom_abline(
    slope = 1,
    intercept = 0,
    color = "red"
  ) +
  labs(
    title = "Modelo multiple: precipitacion observada y predicha",
    x = "Precipitacion observada (mm)",
    y = "Precipitacion predicha (mm)"
  ) +
  theme_minimal()

print(grafico_multiple_observado_predicho)

ggsave(
  filename = "outputs/modelo_multiple/graficos/observado_predicho_evaluacion.png",
  plot = grafico_multiple_observado_predicho,
  width = 10,
  height = 6,
  dpi = 300
)

# Bloque 6: modelo lineal con respuesta transformada.
# log1p equivale a log(1 + precipitacion), por lo que admite dias sin lluvia.
datos_logaritmicos <- datos_multiple %>%
  mutate(
    log_precipitacion = log1p(precipitacion)
  )

modelo_logaritmico <- lm(
  log_precipitacion ~ hr_media + heliofania + recorrido_viento +
    temp_aire_media + mes + estacion,
  data = datos_logaritmicos
)

print(summary(modelo_logaritmico))

coeficientes_modelo_logaritmico <- summary(modelo_logaritmico)$coefficients %>%
  as.data.frame() %>%
  rownames_to_column("termino")

write_csv(
  coeficientes_modelo_logaritmico,
  "outputs/modelo_logaritmico/reportes/coeficientes_modelo_logaritmico.csv"
)

datos_logaritmicos <- datos_logaritmicos %>%
  mutate(
    log_precipitacion_predicha = predict(
      modelo_logaritmico,
      newdata = datos_logaritmicos
    ),
    residuo_logaritmico = log_precipitacion - log_precipitacion_predicha
  )

grafico_residuos_logaritmico <- ggplot(
  datos_logaritmicos,
  aes(
    x = log_precipitacion_predicha,
    y = residuo_logaritmico
  )
) +
  geom_point(alpha = 0.20) +
  geom_hline(
    yintercept = 0,
    color = "red"
  ) +
  labs(
    title = "Residuos del modelo logaritmico",
    x = "log(1 + precipitacion) predicha",
    y = "Residuo en escala logaritmica"
  ) +
  theme_minimal()

print(grafico_residuos_logaritmico)

ggsave(
  filename = "outputs/modelo_logaritmico/graficos/residuos_modelo_logaritmico.png",
  plot = grafico_residuos_logaritmico,
  width = 10,
  height = 6,
  dpi = 300
)

# Se usa la misma division temporal del modelo multiple para una comparacion justa.
entrenamiento_logaritmico <- entrenamiento_multiple %>%
  mutate(
    log_precipitacion = log1p(precipitacion)
  )

modelo_logaritmico_train <- lm(
  log_precipitacion ~ hr_media + heliofania + recorrido_viento +
    temp_aire_media + mes + estacion,
  data = entrenamiento_logaritmico
)

evaluacion_logaritmica <- evaluacion_multiple %>%
  mutate(
    log_precipitacion_predicha = predict(
      modelo_logaritmico_train,
      newdata = evaluacion_multiple
    ),
    # La escala original se recupera antes de calcular las metricas.
    # pmax evita valores negativos de precipitacion, que no son fisicamente posibles.
    precipitacion_predicha = pmax(
      0,
      expm1(log_precipitacion_predicha)
    )
  )

metricas_logaritmicas <- evaluacion_logaritmica %>%
  summarise(
    modelo = "logaritmico",
    MAE = mean(abs(precipitacion - precipitacion_predicha)),
    RMSE = sqrt(mean((precipitacion - precipitacion_predicha)^2))
  )

print(metricas_logaritmicas)

metricas_comparacion <- bind_rows(
  metricas_comparacion,
  metricas_logaritmicas
)

write_csv(
  metricas_comparacion,
  "outputs/comparacion_modelos/reportes/metricas_modelos.csv"
)

write_csv(
  metricas_logaritmicas,
  "outputs/modelo_logaritmico/reportes/metricas_evaluacion_modelo_logaritmico.csv"
)

grafico_logaritmico_observado_predicho <- ggplot(
  evaluacion_logaritmica,
  aes(
    x = precipitacion,
    y = precipitacion_predicha
  )
) +
  geom_point(alpha = 0.20) +
  geom_abline(
    slope = 1,
    intercept = 0,
    color = "red"
  ) +
  labs(
    title = "Modelo logaritmico: precipitacion observada y predicha",
    x = "Precipitacion observada (mm)",
    y = "Precipitacion predicha (mm)"
  ) +
  theme_minimal()

print(grafico_logaritmico_observado_predicho)

ggsave(
  filename = "outputs/modelo_logaritmico/graficos/observado_predicho_evaluacion.png",
  plot = grafico_logaritmico_observado_predicho,
  width = 10,
  height = 6,
  dpi = 300
)

# Bloque 7: comparacion temporal entre observado y predicho.
# Hay varias estaciones por fecha, por lo que se utiliza el promedio diario
# entre estaciones del conjunto de evaluacion para construir una serie legible.
comparacion_temporal_multiple <- evaluacion_multiple %>%
  group_by(Fecha) %>%
  summarise(
    precipitacion_observada = mean(precipitacion),
    precipitacion_predicha = mean(prediccion_multiple),
    .groups = "drop"
  )

write_csv(
  comparacion_temporal_multiple,
  "outputs/modelo_multiple/reportes/comparacion_temporal_evaluacion.csv"
)

comparacion_temporal_larga <- comparacion_temporal_multiple %>%
  pivot_longer(
    cols = c(
      precipitacion_observada,
      precipitacion_predicha
    ),
    names_to = "serie",
    values_to = "precipitacion"
  )

grafico_temporal_multiple <- ggplot(
  comparacion_temporal_larga,
  aes(
    x = Fecha,
    y = precipitacion,
    color = serie
  )
) +
  geom_line() +
  labs(
    title = "Precipitacion diaria observada y predicha: modelo multiple",
    subtitle = "Promedio diario entre estaciones en el conjunto de evaluacion",
    x = "Fecha",
    y = "Precipitacion acumulada promedio (mm)",
    color = "Serie"
  ) +
  theme_minimal()

print(grafico_temporal_multiple)

ggsave(
  filename = "outputs/modelo_multiple/graficos/comparacion_temporal_evaluacion.png",
  plot = grafico_temporal_multiple,
  width = 12,
  height = 6,
  dpi = 300
)

# Bloque 8: resumen final reproducible de la actividad
metricas_largas <- metricas_comparacion %>%
  pivot_longer(
    cols = c(MAE, RMSE),
    names_to = "metrica",
    values_to = "valor"
  )

grafico_comparacion_metricas <- ggplot(
  metricas_largas,
  aes(
    x = modelo,
    y = valor,
    fill = modelo
  )
) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ metrica, scales = "free_y") +
  labs(
    title = "Comparacion de modelos en el conjunto de evaluacion",
    x = "Modelo",
    y = "Error (mm)"
  ) +
  theme_minimal()

print(grafico_comparacion_metricas)

ggsave(
  filename = "outputs/comparacion_modelos/graficos/comparacion_mae_rmse.png",
  plot = grafico_comparacion_metricas,
  width = 10,
  height = 6,
  dpi = 300
)

fila_simple <- metricas_comparacion %>%
  filter(modelo == "simple")

fila_multiple <- metricas_comparacion %>%
  filter(modelo == "multiple")

fila_logaritmica <- metricas_comparacion %>%
  filter(modelo == "logaritmico")

lineas_informe <- c(
  "# Actividad 1 - Regresion sobre precipitacion acumulada diaria",
  "",
  "## Pregunta de analisis",
  "",
  "¿Como se asocia la precipitacion acumulada diaria con la humedad relativa media, la heliofania, el recorrido del viento, la temperatura media del aire, el mes y la estacion?",
  "",
  "## Datos y preparacion",
  "",
  "- Se integraron los registros diarios de INIA con las tablas de estaciones y departamentos.",
  "- La base integrada contiene 21.402 registros diarios de seis estaciones.",
  "- Se excluyeron 3 registros sin precipitacion. Para los modelos multiple y logaritmico quedaron 20.470 observaciones completas.",
  "- El 73,8% de los dias no tuvo lluvia; la precipitacion media fue 3,46 mm y la mediana fue 0 mm.",
  "- No se usaron `PrecipEfectiva` ni `Llovio`, porque se derivan directamente de `PrecipAcum`. Tampoco se incluyo `RadSolar` junto con heliofania, porque deriva de ella.",
  "",
  "## Modelos evaluados",
  "",
  "Se aplico una separacion cronologica por fechas, usando aproximadamente el 80% inicial para entrenamiento y el periodo posterior para evaluacion. Las metricas se calcularon sobre el mismo conjunto de evaluacion para los tres modelos.",
  "",
  "| Modelo | MAE (mm) | RMSE (mm) |",
  "|---|---:|---:|",
  sprintf("| Simple: precipitacion ~ humedad | %.2f | %.2f |", fila_simple$MAE, fila_simple$RMSE),
  sprintf("| Multiple | %.2f | %.2f |", fila_multiple$MAE, fila_multiple$RMSE),
  sprintf("| Logaritmico: log(1 + precipitacion) | %.2f | %.2f |", fila_logaritmica$MAE, fila_logaritmica$RMSE),
  "",
  "## Interpretacion",
  "",
  "- El modelo multiple mejora al modelo simple en MAE y RMSE, por lo que las variables adicionales aportan informacion util.",
  "- El modelo logaritmico obtiene el menor MAE: representa mejor el comportamiento habitual, dominado por dias secos o con lluvia baja.",
  "- El modelo multiple obtiene el menor RMSE: es preferible si se desea penalizar con mayor fuerza los errores grandes.",
  "- Los graficos de residuos y de observado frente a predicho muestran que ningun modelo reproduce adecuadamente los picos de precipitacion.",
  "",
  "## Limitaciones",
  "",
  "- La gran cantidad de ceros, la asimetria y los eventos extremos dificultan el ajuste de un modelo lineal.",
  "- Los predictores se registran durante el mismo dia que la precipitacion; por ello el analisis describe asociaciones y no constituye un pronostico previo al evento.",
  "- Los modelos lineales en escala original pueden producir predicciones negativas. En el modelo logaritmico se limitaron a cero luego de volver a milimetros.",
  "- La heliofania de Las Brujas se estima mediante un modelo desde diciembre de 2020, segun los metadatos, lo que agrega una diferencia de medicion respecto de otras observaciones.",
  "- Las diferencias entre estaciones, datos faltantes y posibles dependencias entre dias consecutivos no quedan modeladas por completo.",
  "",
  "## Conclusion",
  "",
  "No existe un unico modelo mejor para todos los objetivos. El modelo logaritmico es el recomendado si se prioriza el error absoluto habitual; el modelo multiple en escala original es preferible si se priorizan los errores grandes mediante RMSE. En ambos casos, los resultados deben interpretarse como asociaciones meteorologicas diarias y con cautela ante episodios de lluvia intensa."
)

writeLines(
  lineas_informe,
  "outputs/resumen_final/informe_regresion.md",
  useBytes = TRUE
)
