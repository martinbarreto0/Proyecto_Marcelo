# Actividad 1 - Regresion sobre precipitacion acumulada diaria

## Pregunta de analisis

¿Como se asocia la precipitacion acumulada diaria con la humedad relativa media, la heliofania, el recorrido del viento, la temperatura media del aire, el mes y la estacion?

## Datos y preparacion

- Se integraron los registros diarios de INIA con las tablas de estaciones y departamentos.
- La base integrada contiene 21.402 registros diarios de seis estaciones.
- Se excluyeron 3 registros sin precipitacion. Para los modelos multiple y logaritmico quedaron 20.470 observaciones completas.
- El 73,8% de los dias no tuvo lluvia; la precipitacion media fue 3,46 mm y la mediana fue 0 mm.
- No se usaron `PrecipEfectiva` ni `Llovio`, porque se derivan directamente de `PrecipAcum`. Tampoco se incluyo `RadSolar` junto con heliofania, porque deriva de ella.

## Modelos evaluados

Se aplico una separacion cronologica por fechas, usando aproximadamente el 80% inicial para entrenamiento y el periodo posterior para evaluacion. Las metricas se calcularon sobre el mismo conjunto de evaluacion para los tres modelos.

| Modelo | MAE (mm) | RMSE (mm) |
|---|---:|---:|
| Simple: precipitacion ~ humedad | 5.49 | 11.04 |
| Multiple | 5.06 | 10.44 |
| Logaritmico: log(1 + precipitacion) | 3.55 | 11.16 |

## Interpretacion

- El modelo multiple mejora al modelo simple en MAE y RMSE, por lo que las variables adicionales aportan informacion util.
- El modelo logaritmico obtiene el menor MAE: representa mejor el comportamiento habitual, dominado por dias secos o con lluvia baja.
- El modelo multiple obtiene el menor RMSE: es preferible si se desea penalizar con mayor fuerza los errores grandes.
- Los graficos de residuos y de observado frente a predicho muestran que ningun modelo reproduce adecuadamente los picos de precipitacion.

## Limitaciones

- La gran cantidad de ceros, la asimetria y los eventos extremos dificultan el ajuste de un modelo lineal.
- Los predictores se registran durante el mismo dia que la precipitacion; por ello el analisis describe asociaciones y no constituye un pronostico previo al evento.
- Los modelos lineales en escala original pueden producir predicciones negativas. En el modelo logaritmico se limitaron a cero luego de volver a milimetros.
- La heliofania de Las Brujas se estima mediante un modelo desde diciembre de 2020, segun los metadatos, lo que agrega una diferencia de medicion respecto de otras observaciones.
- Las diferencias entre estaciones, datos faltantes y posibles dependencias entre dias consecutivos no quedan modeladas por completo.

## Conclusion

No existe un unico modelo mejor para todos los objetivos. El modelo logaritmico es el recomendado si se prioriza el error absoluto habitual; el modelo multiple en escala original es preferible si se priorizan los errores grandes mediante RMSE. En ambos casos, los resultados deben interpretarse como asociaciones meteorologicas diarias y con cautela ante episodios de lluvia intensa.
