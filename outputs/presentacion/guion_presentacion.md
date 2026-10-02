# Guion de presentación: regresión y clustering agroclimático

**Duración objetivo:** 24 minutos.  
**Integrantes:** Alejandra Ramírez, Martin Barreto, Gabriela Flores y Katerin Gonzalez.  
**Idea central:** a partir de registros diarios de estaciones de INIA, primero analizamos la asociación de la precipitación acumulada con otras variables meteorológicas y luego identificamos perfiles de días agroclimáticos en La Estanzuela.

## Distribución y control de tiempo

| Persona | Diapositivas | Tiempo objetivo | Acumulado |
|---|---:|---:|---:|
| Alejandra | 1 a 3 | 5 min 30 s | 5 min 30 s |
| Martin | 4 a 7 | 6 min 30 s | 12 min |
| Gabriela | 8 a 10 | 6 min | 18 min |
| Katerin | 11 a 14 | 6 min | 24 min |

El texto está pensado como una guía para hablar con naturalidad, no para leer literalmente. Las frases entre comillas pueden usarse tal cual; los números y las ideas resaltadas son los elementos que conviene no omitir. Si se dispone de menos tiempo, se puede resumir la explicación de los gráficos, pero deben mantenerse las conclusiones y las limitaciones.

---

## Alejandra Ramírez — apertura, objetivos y datos (5 min 30 s)

### Diapositiva 1 — Portada (0 min 45 s)

**Qué decir**

> Buenos días/tardes. Somos Alejandra Ramírez, Martin Barreto, Gabriela Flores y Katerin Gonzalez. En este trabajo analizamos datos agroclimáticos diarios de INIA con dos enfoques complementarios: regresión y clustering. La regresión nos permite estudiar cómo se asocia la precipitación acumulada con otras variables meteorológicas; el clustering nos permite reconocer tipos de días similares sin definirlos previamente.

> La pregunta que guía todo el trabajo es cómo extraer información útil de registros meteorológicos reales, teniendo en cuenta que contienen días sin lluvia, eventos extremos y algunos valores que fue necesario validar.

**Transición**

> Primero vamos a explicar por qué usamos dos enfoques y qué aporta cada uno.

### Diapositiva 2 — Objetivos y enfoques utilizados (2 min 15 s)

**Qué decir**

> La primera actividad fue una **regresión supervisada**. Aquí ya conocemos la variable que queremos analizar: la precipitación acumulada diaria, o *PrecipAcum*. La pregunta fue: ¿cómo se asocia esa precipitación con la humedad relativa media, la heliofanía, el recorrido del viento, la temperatura media, el mes y la estación?

> Partimos de un modelo simple, con precipitación y humedad, como punto de referencia. Después incorporamos más variables en un modelo múltiple y también usamos una transformación logarítmica para tratar la fuerte asimetría de la precipitación.

> La segunda actividad fue un **clustering no supervisado**. En este caso no tenemos una variable objetivo. Queremos que los datos formen grupos por similitud. La pregunta fue: ¿qué tipos de días agroclimáticos pueden identificarse en La Estanzuela considerando temperatura, humedad, heliofanía, precipitación y viento?

> Es importante distinguirlos: la regresión explica o estima una variable concreta; el clustering describe perfiles. Ninguno de los dos métodos, por sí solo, demuestra causalidad.

**Señalar en pantalla**

- En la columna de regresión, remarcar “variable objetivo: precipitación acumulada”.
- En la columna de clustering, remarcar “grupos por similitud” y “sin variable objetivo”.

**Transición**

> Para que los resultados sean interpretables, el primer paso fue preparar correctamente las bases y definir qué representa cada observación.

### Diapositiva 3 — Datos utilizados y variables (2 min 30 s)

**Qué decir**

> Usamos tres fuentes. La base INIA contiene las mediciones agroclimáticas diarias. La tabla EstacionAgr aporta el nombre y la ubicación de cada estación, y la tabla Departamento permite asociar el código con el nombre del departamento. Las unimos mediante sus códigos para disponer de una base integrada y legible.

> Para la regresión trabajamos con **21.402 registros diarios de seis estaciones**. Cada fila representa una combinación de estación y día. La variable a analizar es *PrecipAcum*, en milímetros. Como variables explicativas usamos humedad relativa media, temperatura media del aire, heliofanía en horas, recorrido del viento, mes y estación.

> No incluimos *PrecipEfectiva* ni *Llovio*, porque se derivan directamente de la precipitación acumulada y generarían una comparación artificial. Tampoco usamos radiación solar junto con heliofanía porque está derivada de ella. En la regresión, mes y estación ayudan a representar diferencias temporales y geográficas.

> Para clustering utilizamos solamente los días de **La Estanzuela**, y cada fila representa un día. En esa actividad dejamos fecha y mes para interpretar los grupos después, pero no los usamos para calcular distancias entre días.

**Pausa breve para verificar comprensión**

> Entonces, las dos actividades comparten datos meteorológicos, pero cambian la unidad analizada y la pregunta: estación-día para la regresión y día de La Estanzuela para clustering.

**Entrega a Martin**

> Con los datos integrados, Martin va a mostrar cómo se exploraron y cómo se construyeron los modelos de regresión.

---

## Martin Barreto — exploración y regresión (6 min 30 s)

### Diapositiva 4 — Preparación y exploración de los datos (1 min 30 s)

**Qué decir**

> Antes de ajustar modelos, convertimos la fecha al formato adecuado, revisamos los faltantes y seleccionamos las variables consistentes con la pregunta. La exploración mostró una característica decisiva: **el 73,8 % de los días no tuvo lluvia**.

> Por eso la distribución de la precipitación está muy concentrada en cero y es asimétrica. La media fue **3,46 milímetros**, mientras que la mediana fue **0 milímetros**. Esto anticipa que un modelo lineal tendrá dificultad para representar a la vez los muchos días secos y los pocos eventos de lluvia intensa.

> Esta exploración no fue un paso decorativo: fue la razón para comparar un modelo en escala original con otro que usa una transformación logarítmica.

**Señalar en pantalla**

- El flujo: integración, fecha, selección y exploración.
- Los tres valores destacados: 73,8 %, 3,46 mm y mediana 0 mm.

**Transición**

> Como referencia inicial, comenzamos con la relación más simple: precipitación y humedad media.

### Diapositiva 5 — Regresión lineal simple (2 min)

**Qué decir**

> El primer modelo fue una regresión lineal simple: precipitación acumulada en función de humedad relativa media. En el gráfico, cada punto es una observación diaria; la línea resume la tendencia promedio estimada.

> La pendiente positiva indica que, en promedio, al aumentar la humedad también aumenta la precipitación estimada. Sin embargo, la nube de puntos es muy dispersa. El coeficiente de determinación fue **R² = 0,041**, es decir, la humedad por sí sola explica una fracción muy pequeña de la variabilidad observada.

> Al evaluarlo sobre el período posterior reservado para prueba, el error absoluto medio, MAE, fue **5,49 mm** y el RMSE fue **11,04 mm**. El RMSE es mayor porque penaliza con más fuerza los errores grandes, especialmente los días de lluvia intensa.

> Este modelo es útil como referencia y para mostrar que hay una asociación positiva, pero es insuficiente para describir toda la complejidad de la precipitación diaria.

**Precisión importante**

> Como las variables se midieron durante el mismo día, esto describe asociaciones del día; no es un pronóstico antes de que ocurra la lluvia ni prueba que una variable cause a la otra.

**Transición**

> Por eso incorporamos información meteorológica adicional y comparamos dos formas de modelar la precipitación.

### Diapositiva 6 — Regresión múltiple y modelo logarítmico (1 min 45 s)

**Qué decir**

> En el modelo múltiple agregamos humedad, heliofanía, viento, temperatura, mes y estación. Para evaluar de forma más realista, separamos cronológicamente las fechas: aproximadamente el 80 % inicial se usó para entrenar y el período posterior para evaluar. Así evitamos evaluar el modelo con información del mismo período usado para ajustarlo.

> El modelo múltiple mejoró al simple: obtuvo **MAE de 5,06 mm** y **RMSE de 10,44 mm**. Por lo tanto, las variables adicionales aportan información útil y, entre los modelos comparados, este fue el que tuvo menor RMSE.

> También ajustamos un modelo con logaritmo de uno más la precipitación, *log(1 + PrecipAcum)*. El uno permite transformar también los días con cero lluvia. Luego volvimos las predicciones a milímetros. Este modelo obtuvo el menor MAE: **3,55 mm**, aunque su RMSE fue **11,16 mm**.

> La diferencia entre las métricas es importante. El modelo logarítmico representa mejor el error habitual de días secos o con lluvia baja; el múltiple en escala original penaliza menos los errores extremos y tiene mejor RMSE. No hay un único ganador: la elección depende de qué error se quiere priorizar.

**Señalar en pantalla**

- La tabla comparativa: simple como referencia; múltiple con menor RMSE; logarítmico con menor MAE.

**Transición**

> Los promedios de error ayudan, pero los gráficos permiten ver en qué situaciones fallan los modelos.

### Diapositiva 7 — Predicciones y análisis de residuos (1 min 15 s)

**Qué decir**

> En el gráfico de observado versus predicho, la diagonal representa una predicción perfecta. Los puntos cercanos a esa línea indican días bien estimados; los puntos alejados muestran error. Vemos que los días de precipitación alta se alejan más de la diagonal, por lo que los picos de lluvia siguen siendo difíciles de representar.

> El gráfico de residuos muestra ese mismo comportamiento desde otra perspectiva: un residuo es el valor observado menos el estimado. Si fuera positivo, el modelo subestimó; si fuera negativo, sobrestimó. Esperamos una nube sin patrón marcado alrededor de cero, pero los extremos concentran errores mayores.

> La conclusión de regresión es clara: agregar variables mejora el modelo simple, pero los eventos intensos y la gran cantidad de ceros siguen siendo el principal desafío.

**Entrega a Gabriela**

> Mientras la regresión se concentró en explicar la precipitación, Gabriela va a pasar a una pregunta distinta: reconocer perfiles completos de días agroclimáticos.

---

## Gabriela Flores — metodología y resultados del clustering (6 min)

### Diapositiva 8 — Clustering: preparación y metodología (2 min)

**Qué decir**

> Para el clustering nos concentramos en una sola estación, **La Estanzuela**, para que los grupos describan días comparables dentro de un mismo contexto. Teníamos 3.729 registros originales y quedaron **3.725 días completos** para el análisis.

> Usamos cinco variables: temperatura media, humedad relativa media, heliofanía, precipitación acumulada y recorrido del viento. La precipitación también se transformó con *log(1 + precipitación)* porque tiene muchos ceros y algunos valores muy altos.

> Detectamos dos valores de humedad superiores a 100 %, físicamente inválidos. Los marcamos como faltantes antes de completar el análisis. Fecha y mes no se usaron para calcular los grupos; se reservaron para interpretarlos después, evitando que el calendario determine artificialmente la similitud.

> Como k-means agrupa por distancias, estandarizamos todas las variables: así una variable medida en una escala grande no domina a las demás. Ejecutamos el algoritmo con 25 inicializaciones y hasta 100 iteraciones, para reducir la dependencia de una única solución inicial.

**Punto metodológico para enfatizar**

> En clustering los nombres de los grupos se asignan después de mirar sus características. El número 1 o 2 no implica mejor, peor, más o menos intensidad.

**Transición**

> El siguiente paso fue decidir cuántos grupos resumían mejor los datos sin forzar una separación inexistente.

### Diapositiva 9 — Selección del número de clusters y resultados (2 min 15 s)

**Qué decir**

> Probamos distintos valores de *k*. El gráfico del codo observa cómo disminuye la variabilidad interna al agregar grupos. Como esa medida siempre tiende a bajar, la usamos como apoyo y no como único criterio.

> La decisión principal se tomó con el coeficiente de silueta, que resume cohesión dentro de cada grupo y separación respecto de los demás. Evaluamos de 2 a 8 grupos y elegimos **k = 2**, porque tuvo la mayor silueta promedio, aproximadamente **0,294**.

> Ese valor indica una separación moderada: hay una estructura interpretable, pero no dos conjuntos totalmente aislados. Por eso hablaremos de perfiles de similitud y no de categorías meteorológicas rígidas.

> La proyección PCA muestra los datos en dos componentes principales para visualizarlos. Los dos componentes explican cerca de **64,2 %** de la variabilidad: 39,0 % el primero y 25,2 % el segundo. Allí se observa una tendencia a separarse, pero también una zona de solapamiento. Importante: la PCA sirve para visualizar; los clusters fueron calculados con las cinco variables estandarizadas, no con esta gráfica reducida.

> La tabla de la derecha adelanta el contraste: el cluster 1 tiene mayor humedad y precipitación; el cluster 2, más heliofanía y menor precipitación.

**Señalar en pantalla**

- Primero, silueta y el valor k = 2.
- Luego, PCA como apoyo visual, no como método de agrupamiento.
- Por último, la tabla de medias.

**Transición**

> Con k definido, podemos traducir los números a perfiles de días fáciles de interpretar.

### Diapositiva 10 — Resultados del clustering (1 min 45 s)

**Qué decir**

> El **cluster 1** reúne el **30,8 % de los días**. Su perfil tiene humedad media de **87,3 %**, heliofanía de solo **2,5 horas** y precipitación media de **8,86 mm**. Por esas características lo denominamos perfil **húmedo y lluvioso, con poca insolación**.

> El **cluster 2** contiene el **69,2 % de los días**. Tiene humedad menor, **72,1 %**, mucha más heliofanía, **9,6 horas**, y precipitación media baja, **0,33 mm**. Lo llamamos perfil **seco y soleado**.

> El gráfico de centroides estandarizados ayuda a comparar ambos perfiles en una misma escala. Las barras no son unidades originales: muestran si cada cluster está por encima o por debajo del promedio de la variable. Confirma el contraste entre humedad y precipitación frente a heliofanía.

> De todos modos, el solapamiento visto antes nos recuerda que estos nombres son resúmenes útiles, no fronteras absolutas entre tipos de clima.

**Entrega a Katerin**

> Katerin va a cerrar mostrando cómo cambian estos perfiles a lo largo del año, qué validaciones hicimos y cuáles son las conclusiones responsables del trabajo.

---

## Katerin Gonzalez — sensibilidad, límites y cierre (6 min)

### Diapositiva 11 — Análisis temporal, sensibilidad y limitaciones (1 min 45 s)

**Qué decir**

> Después de formar los clusters, usamos el mes para interpretar su distribución. El gráfico inferior muestra que las proporciones cambian a lo largo del año: no todos los meses presentan la misma presencia relativa de los perfiles. Esta lectura es descriptiva; el mes no participó en las distancias ni en la asignación de grupos.

> También hicimos un análisis de sensibilidad porque algunos recorridos de viento eran muy altos y podían influir en k-means. Comparamos el resultado principal, con los 3.725 días, con otro que excluye el 1 % de mayor viento, quedando 3.687 días. La variabilidad interna por registro cambió muy poco: de **3,698** a **3,705**. Por eso consideramos que los perfiles principales son estables frente a esos extremos y mantenemos el modelo principal con todos los eventos.

> Sin embargo, hay límites. Existen faltantes e inconsistencias; k-means depende de las variables, de la escala y del número de grupos elegido; y los patrones dependen de este conjunto de datos. Por eso los resultados deben validarse antes de usarlos como categorías meteorológicas definitivas.

**Transición**

> Estos límites no son errores que ocultamos: fueron parte del análisis y definieron las decisiones que tomamos.

### Diapositiva 12 — Limitaciones y problemas encontrados (2 min)

**Qué decir**

> El primer problema fue que había muchos días sin lluvia: **73,8 %** de los registros de regresión tenían precipitación igual a cero. Esto hace que la distribución sea muy asimétrica y explica por qué aplicamos una transformación logarítmica y comparamos métricas distintas.

> El segundo problema fueron las precipitaciones extremas. Son pocos casos, pero tienen gran impacto en el RMSE y explican por qué las predicciones de lluvia intensa siguen siendo las más difíciles. No los eliminamos: los mantuvimos porque son eventos reales y relevantes.

> En clustering encontramos dos humedades mayores a 100 %. Como no son físicamente válidas, las tratamos como faltantes antes de ejecutar el algoritmo. Es una corrección basada en validación de datos, no una modificación arbitraria.

> Por último, los valores extremos de recorrido de viento podían modificar las distancias. En vez de eliminarlos sin comprobación, hicimos el análisis de sensibilidad que acabamos de mostrar. Al observar estabilidad, conservamos los datos en el análisis principal.

> La enseñanza es que la preparación, la validación y las decisiones de modelado son tan importantes como ejecutar una función de regresión o de clustering.

**Transición**

> Con esos controles y limitaciones presentes, podemos sintetizar los principales resultados.

### Diapositiva 13 — Conclusiones (1 min 30 s)

**Qué decir**

> En regresión, agregar humedad, heliofanía, viento, temperatura, mes y estación mejoró el modelo simple. El modelo logarítmico tuvo el menor MAE, **3,55 mm**, por lo que funciona mejor para el error cotidiano; el modelo múltiple tuvo el menor RMSE, **10,44 mm**, por lo que se comporta mejor al penalizar errores grandes. Aun así, los episodios de lluvia intensa siguen siendo difíciles de representar.

> En clustering identificamos dos perfiles principales en La Estanzuela: uno húmedo y lluvioso, presente en el 30,8 % de los días, y otro seco y soleado, presente en el 69,2 %. El valor de silueta y la PCA muestran que existe estructura, pero con cierto solapamiento.

> La conclusión transversal es que preparar y comprender los datos fue tan importante como aplicar los modelos. Los resultados son útiles para describir y comparar patrones agroclimáticos, siempre con cautela respecto de causalidad, predicción y generalización.

**Transición al cierre**

> Muchas gracias por su atención. Quedamos disponibles para las preguntas.

### Diapositiva 14 — Gracias (0 min 45 s)

**Qué decir**

> Gracias. Si desean, podemos ampliar cómo se eligió el número de clusters, por qué el modelo logarítmico baja el MAE o cómo se organizaron los datos y las salidas reproducibles en R.

---

## Preguntas probables y respuestas breves

### ¿Por qué el modelo logarítmico tiene menor MAE pero no menor RMSE?

Porque la transformación da más peso relativo a los valores frecuentes y bajos, por lo que representa mejor el error habitual. Al volver a milímetros, los pocos eventos extremos pueden seguir generando errores grandes, que el RMSE penaliza de forma más intensa.

### ¿Por qué no se usaron `Llovio` o `PrecipEfectiva` en la regresión?

Porque se obtienen directamente de `PrecipAcum`. Usarlas para explicar la propia precipitación introduciría información derivada de la variable objetivo y haría la evaluación artificialmente optimista.

### ¿Por qué se usó k = 2 y no más grupos?

Se compararon opciones: el codo ayudó a observar la reducción de variabilidad interna y la silueta promedio fue máxima en k = 2, aproximadamente 0,294. Elegimos la opción con mejor soporte cuantitativo e interpretación clara, reconociendo que la separación es moderada.

### ¿Los clusters predicen el clima?

No. Son una clasificación descriptiva de días similares dentro de La Estanzuela. No reemplazan un modelo de pronóstico y no implican causalidad.

### ¿Por qué se separó el conjunto de regresión por tiempo?

Para evaluar con fechas posteriores a las usadas en el entrenamiento. Así se evita mezclar información del mismo período entre ajuste y evaluación, lo que ofrece una comparación más realista.

### ¿Qué se haría como continuación del trabajo?

Incorporar variables medidas antes del día objetivo para un pronóstico genuino, considerar modelos adecuados para muchos ceros y eventos extremos, y validar los clusters en otros períodos o estaciones.
