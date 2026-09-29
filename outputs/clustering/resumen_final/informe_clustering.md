# Actividad 2 - Clustering exploratorio de dias agroclimaticos

## Pregunta
¿Que tipos de dias agroclimaticos se pueden identificar en La Estanzuela?

## Datos y variables
- Cada observacion es un dia de La Estanzuela.
- Registros originales: 3729; registros completos: 3725.
- Variables: temperatura media, humedad relativa media, heliofania, log(1 + precipitacion) y viento.
- Fecha y mes se reservaron para interpretar, no para calcular distancias.

## Metodo
- Se corrigieron humedades fuera de 0-100% como faltantes y se uso log(1 + precipitacion).
- Las variables se estandarizaron antes de aplicar k-means.
- Se evaluo el codo para k = 1 a 10 y silhouette para k = 2 a 8.
- Se eligio k = 2 por mayor silhouette promedio (0.294).
- Este silhouette indica una separacion moderada: los perfiles son utiles, pero no son grupos perfectamente aislados.

## Perfiles encontrados
- Cluster 1 (humedo_lluvioso_poca_insolacion): 30.8% de los dias; mayor humedad (87.3%), menor heliofania (2.5 h) y mayor precipitacion media (8.86 mm).
- Cluster 2 (seco_soleado): 69.2% de los dias; menor humedad (72.1%), mayor heliofania (9.6 h) y baja precipitacion media (0.33 mm).

## Interpretacion y limites
- perfil_clusters.csv y centroides_estandarizados.csv documentan las etiquetas asignadas despues de caracterizar los grupos.
- Los clusters representan similitud, no categorias verdaderas ni causalidad.
- k-means depende de distancia, escala, valores extremos e inicializacion.
- Se incluyo sensibilidad sin el 1% de mayor viento; el modelo principal conserva todos los eventos.
