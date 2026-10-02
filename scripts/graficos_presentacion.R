# Grafico adicional para la diapositiva de resultados de clustering.
#
# Este script crea una proyeccion PCA de los cinco predictores que se usaron
# en k-means. La PCA reduce esas cinco dimensiones a dos ejes para poder
# visualizar los dias y sus clusters en un plano.

# Se prioriza la biblioteca local del proyecto, donde ya estan instalados los
# paquetes utilizados por los analisis principales.
.libPaths(c("r_packages", .libPaths()))

library(dplyr)
library(ggplot2)
library(readr)

# Crear la carpeta destinada exclusivamente a los recursos de la presentacion.
dir.create("outputs/presentacion", recursive = TRUE, showWarnings = FALSE)

# Leer las asignaciones finales. Este archivo contiene solo los dias completos
# de La Estanzuela y la etiqueta de cluster ya obtenida en el analisis principal.
datos_clusters <- read_csv(
  "outputs/clustering/modelo_final/reportes/asignacion_clusters.csv",
  show_col_types = FALSE
)

# Seleccionar exactamente las cinco variables usadas por k-means. La version
# logaritmica de precipitacion se conserva porque fue la variable usada para
# calcular los clusters originales.
variables_pca <- datos_clusters %>%
  select(temp_aire_media, hr_media, heliofania, log_precipitacion, recorrido_viento)

# prcomp() calcula los componentes principales. center = TRUE centra cada
# variable y scale. = TRUE la estandariza para que las unidades no dominen
# la proyeccion.
modelo_pca <- prcomp(variables_pca, center = TRUE, scale. = TRUE)

# Convertir los dos primeros componentes a una tabla y agregar la etiqueta de
# cluster para colorear los puntos en el grafico.
proyeccion_pca <- as.data.frame(modelo_pca$x[, 1:2]) %>%
  rename(componente_1 = PC1, componente_2 = PC2) %>%
  mutate(cluster = factor(datos_clusters$cluster))

# Porcentaje de variabilidad representada por cada eje. Se usa en las etiquetas
# para que la diapositiva indique cuanta informacion resume la proyeccion.
varianza_explicada <- summary(modelo_pca)$importance[2, 1:2] * 100

# Visualizacion solicitada para la diapositiva: los cinco predictores se
# proyectan en dos componentes principales y los colores identifican el cluster.
grafico_pca <- ggplot(proyeccion_pca,
                      aes(x = componente_1, y = componente_2, color = cluster)) +
  geom_point(alpha = 0.35, size = 1.5) +
  labs(
    title = "Clusters en una proyeccion PCA",
    subtitle = "La PCA resume los cinco predictores usados por k-means en dos ejes",
    x = sprintf("Componente principal 1 (%.1f%%)", varianza_explicada[1]),
    y = sprintf("Componente principal 2 (%.1f%%)", varianza_explicada[2]),
    color = "Cluster"
  ) +
  theme_minimal(base_size = 13)

print(grafico_pca)

# Guardar el PNG que se debe insertar en el recuadro "Visualizacion de clusters"
# de la diapositiva 8.
ggsave(
  "outputs/presentacion/proyeccion_pca_clusters.png",
  grafico_pca,
  width = 10,
  height = 6,
  dpi = 300
)

# Guardar un CSV auxiliar con la varianza de los dos componentes. Es util para
# citar correctamente los porcentajes que aparecen en los ejes del grafico.
write_csv(
  tibble(
    componente = c("PC1", "PC2"),
    porcentaje_varianza_explicada = varianza_explicada
  ),
  "outputs/presentacion/varianza_explicada_pca.csv"
)

# Grafico adicional para la diapositiva de sensibilidad. Compara la compacidad
# promedio del modelo principal con la alternativa que excluye el 1% de dias con
# mayor recorrido de viento. Valores similares respaldan que el resultado no
# depende de unos pocos dias extremos.
sensibilidad_viento <- read_csv(
  "outputs/clustering/modelo_final/reportes/sensibilidad_extremos_viento.csv",
  show_col_types = FALSE
) %>%
  mutate(
    escenario = case_when(
      modelo == "principal" ~ "Modelo principal",
      modelo == "sin_1_por_ciento_viento_mayor" ~ "Sin 1% de mayor viento",
      TRUE ~ modelo
    )
  )

grafico_sensibilidad <- ggplot(
  sensibilidad_viento,
  aes(x = escenario, y = withinss_por_registro, fill = escenario)
) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(
    aes(label = sprintf("%.3f", withinss_por_registro)),
    vjust = -0.4,
    size = 5
  ) +
  labs(
    title = "Sensibilidad a los extremos de viento",
    subtitle = "Compacidad interna por registro con y sin el 1% de mayor viento",
    x = NULL,
    y = "Withinss por registro"
  ) +
  expand_limits(y = 4) +
  theme_minimal(base_size = 13)

print(grafico_sensibilidad)

ggsave(
  "outputs/presentacion/sensibilidad_extremos_viento.png",
  grafico_sensibilidad,
  width = 8,
  height = 5,
  dpi = 300
)
