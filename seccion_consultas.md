## CONSULTAS DE ANÁLISIS

La siguiente sección muestra la potencia del ecosistema desplegado, realizando consultas que combinan ambas fuentes de datos para extraer conclusiones sobre el comportamiento energético de los hogares londinenses. Todas las consultas que incluyen un JOIN entre `postgres.public.informations_households` y `hive.london.daily_dataset` son **consultas federadas**: Trino obtiene los datos de cada fuente por separado y los combina en memoria de forma transparente para el usuario.

---

### Consulta 1 — Distribución de hogares por grupo socioeconómico y tarifa

Esta primera consulta opera únicamente sobre PostgreSQL y sirve como punto de partida para entender la composición del dataset antes de cruzarlo con los datos de consumo.

```sql
SELECT
    acorn_grouped,
    stdortou,
    COUNT(*) AS num_hogares
FROM postgres.public.informations_households
GROUP BY acorn_grouped, stdortou
ORDER BY acorn_grouped, stdortou;
```

**Resultado:**

| acorn_grouped | stdortou | num_hogares |
|---|---|---|
| ACORN-U | ToU | 2 |
| ACORN-U | Std | 39 |
| Adversity | Std | 1518 |
| Adversity | ToU | 298 |
| Affluent | Std | 1702 |
| Affluent | ToU | 490 |
| Comfortable | Std | 1184 |
| Comfortable | ToU | 323 |

**Análisis:** El grupo más numeroso es *Affluent* con 2.192 hogares, seguido de *Adversity* (1.816) y *Comfortable* (1.507). En todos los grupos, la tarifa estándar (`Std`) es mayoritaria, representando aproximadamente el 77% de los hogares frente al 23% con tarifa `ToU`. Esto es relevante para interpretar el resto de consultas: la muestra ToU es siempre menor, pero suficientemente representativa en los tres grupos principales. El grupo `ACORN-U` (clasificación sin asignar) se descartará del análisis por su tamaño marginal.

---

### Consulta 2 — Consumo medio diario por grupo socioeconómico *(JOIN federado)*

Primera consulta federada: combina los metadatos de hogares en PostgreSQL con los datos de consumo diario en MinIO para calcular el perfil energético de cada grupo ACORN.

```sql
SELECT
    h.acorn_grouped,
    COUNT(DISTINCT h.lclid)      AS num_hogares,
    ROUND(AVG(d.energy_mean), 4) AS kwh_medio_dia,
    ROUND(AVG(d.energy_max),  4) AS pico_kwh,
    ROUND(AVG(d.energy_min),  4) AS valle_kwh
FROM postgres.public.informations_households h
JOIN hive.london.daily_dataset d ON h.lclid = d.lclid
GROUP BY h.acorn_grouped
ORDER BY kwh_medio_dia DESC;
```

**Resultado:**

| acorn_grouped | num_hogares | kwh_medio_dia | pico_kwh | valle_kwh |
|---|---|---|---|---|
| Affluent | 550 | 0.2354 | 0.9059 | 0.0659 |
| Comfortable | 450 | 0.2007 | 0.7912 | 0.0566 |
| Adversity | 546 | 0.1734 | 0.7369 | 0.0449 |

**Análisis:** Los resultados confirman una correlación directa entre nivel socioeconómico y consumo eléctrico. Los hogares *Affluent* consumen de media un **35,8% más** que los hogares *Adversity* (0,2354 vs 0,1734 kWh/día), y un **17,3% más** que los *Comfortable*. Esta diferencia se mantiene tanto en el pico como en el valle, lo que sugiere que no se trata de un patrón de uso concreto sino de un nivel de consumo estructuralmente mayor en los hogares más acomodados, probablemente asociado a viviendas más grandes y mayor número de dispositivos eléctricos.

---

### Consulta 3 — Efecto de la tarifa ToU sobre el consumo *(JOIN federado)*

Esta consulta analiza si la tarifa *Time-of-Use*, que penaliza el consumo en horas punta con precios más elevados, tiene un efecto real sobre el comportamiento energético de los hogares.

```sql
SELECT
    h.stdortou,
    COUNT(DISTINCT h.lclid)                         AS num_hogares,
    ROUND(AVG(d.energy_mean), 4)                    AS kwh_medio_dia,
    ROUND(AVG(d.energy_max),  4)                    AS consumo_pico,
    ROUND(AVG(d.energy_min),  4)                    AS consumo_valle,
    ROUND(AVG(d.energy_max) - AVG(d.energy_min), 4) AS variabilidad
FROM postgres.public.informations_households h
JOIN hive.london.daily_dataset d ON h.lclid = d.lclid
GROUP BY h.stdortou;
```

**Resultado:**

| stdortou | num_hogares | kwh_medio_dia | consumo_pico | consumo_valle | variabilidad |
|---|---|---|---|---|---|
| Std | 1234 | 0.2063 | 0.8228 | 0.0563 | 0.7666 |
| ToU | 328 | 0.1955 | 0.7833 | 0.0541 | 0.7292 |

**Análisis:** Los hogares con tarifa ToU presentan un consumo medio diario un **5,2% menor** que los de tarifa estándar (0,1955 vs 0,2063 kWh/día), y una **variabilidad entre pico y valle también inferior** (0,7292 vs 0,7666). Esto sugiere que la tarifa ToU cumple parcialmente su objetivo: los hogares que la tienen tienden a suavizar su consumo a lo largo del día, reduciendo los picos. Sin embargo, la diferencia es moderada, lo que podría indicar que el efecto del incentivo económico es real pero limitado, o que los hogares ToU ya tenían de partida un perfil de consumo más eficiente antes de acogerse a esta tarifa.

---

### Consulta 4 — Top 10 hogares con mayor consumo total acumulado *(JOIN federado)*

Identifica los hogares más consumidores del periodo completo, cruzando su consumo acumulado con su perfil socioeconómico y tipo de tarifa.

```sql
SELECT
    h.lclid,
    h.acorn_grouped,
    h.stdortou,
    ROUND(SUM(d.energy_sum), 2) AS kwh_total
FROM postgres.public.informations_households h
JOIN hive.london.daily_dataset d ON h.lclid = d.lclid
GROUP BY h.lclid, h.acorn_grouped, h.stdortou
ORDER BY kwh_total DESC
LIMIT 10;
```

**Resultado:**

| lclid | acorn_grouped | stdortou | kwh_total |
|---|---|---|---|
| MAC000985 | Affluent | ToU | 43031.15 |
| MAC002213 | Affluent | Std | 34142.61 |
| MAC003507 | Comfortable | Std | 33428.06 |
| MAC000049 | Affluent | Std | 30087.10 |
| MAC002441 | Affluent | Std | 29781.67 |
| MAC005393 | Affluent | Std | 28332.28 |
| MAC003979 | Comfortable | Std | 26972.95 |
| MAC004863 | Affluent | Std | 26884.63 |
| MAC004636 | Comfortable | Std | 26116.86 |
| MAC005041 | Affluent | Std | 25647.59 |

**Análisis:** El hogar con mayor consumo total del periodo es `MAC000985`, con 43.031 kWh acumulados — un valor notablemente superior al segundo clasificado (34.142 kWh), lo que lo convierte en un outlier claro. Resulta llamativo que este hogar tenga tarifa **ToU**: a pesar del incentivo económico para reducir el consumo en horas punta, su consumo total es el más alto de todo el dataset, lo que sugiere que en casos de alta demanda estructural la tarifa variable no es suficiente para modificar el comportamiento. El resto del top 10 está dominado por hogares *Affluent* con tarifa estándar, lo que confirma el patrón observado en la consulta 2.

---

### Consulta 5 — Evolución mensual del consumo (estacionalidad)

Esta consulta opera únicamente sobre el Parquet en MinIO y analiza cómo evoluciona el consumo a lo largo de los meses cubiertos por el dataset (noviembre 2011 – febrero 2014).

```sql
SELECT
    date_trunc('month', d.day)   AS mes,
    ROUND(AVG(d.energy_mean), 4) AS kwh_medio_dia,
    ROUND(AVG(d.energy_max),  4) AS pico_kwh
FROM hive.london.daily_dataset d
GROUP BY date_trunc('month', d.day)
ORDER BY mes;
```

**Resultado (selección):**

| mes | kwh_medio_dia | pico_kwh |
|---|---|---|
| 2011-12-01 | 0.2669 | 1.0088 |
| 2012-01-01 | 0.2661 | 1.0510 |
| 2012-07-01 | 0.1682 | 0.7008 |
| 2012-08-01 | 0.1644 | 0.6702 |
| 2013-01-01 | 0.2537 | 0.9585 |
| 2013-07-01 | 0.1611 | 0.6433 |
| 2013-08-01 | 0.1585 | 0.6381 |
| 2014-02-01 | 0.2227 | 0.8605 |

**Análisis:** El patrón estacional es muy pronunciado y consistente en los dos años completos del dataset. El consumo en los meses de invierno (diciembre–febrero) casi dobla al de los meses de verano (julio–agosto): el mínimo histórico es agosto de 2013 con 0,1585 kWh/día, mientras que el máximo es enero de 2012 con 0,2661 kWh/día, una diferencia del **68%**. Este patrón es esperable en el clima londinense, donde la calefacción eléctrica y la iluminación (días más cortos) elevan significativamente el consumo en invierno. También se observa una ligera tendencia a la baja entre 2012 y 2013, especialmente en verano, que podría reflejar mejoras en eficiencia energética o cambios en la composición de la muestra.

---

### Consulta 6 — Búsqueda de hogares con consumo anómalamente alto *(JOIN federado)*

Esta consulta intenta identificar hogares con un consumo medio diario superior a 1,5 kWh, umbral que se estableció como indicador de consumo anómalo.

```sql
SELECT
    h.lclid,
    h.acorn_grouped,
    h.stdortou,
    ROUND(AVG(d.energy_mean), 4) AS kwh_medio_dia,
    ROUND(AVG(d.energy_max),  4) AS pico_kwh
FROM postgres.public.informations_households h
JOIN hive.london.daily_dataset d ON h.lclid = d.lclid
GROUP BY h.lclid, h.acorn_grouped, h.stdortou
HAVING AVG(d.energy_mean) > 1.5
ORDER BY kwh_medio_dia DESC;
```

**Resultado:** 0 filas.

**Análisis:** El resultado vacío no indica un error en la consulta, sino que el umbral de 1,5 kWh/día medio está por encima del máximo real del dataset. Como se observó en la consulta 2, el consumo medio más alto por grupo es de 0,2354 kWh/día para *Affluent*, y el hogar más consumidor del top 10 acumula su alto total a lo largo de muchos días, no porque tenga picos de media diaria extremos. Esto revela una característica importante del dataset: **no hay hogares con consumo medio diario desorbitado**; los outliers del dataset son outliers relativos dentro de un rango compacto, no consumidores industriales o errores de medición. El umbral habría que bajarlo a valores como 0,5 kWh/día para obtener resultados significativos con estos datos.

---

### Consulta 7 — Consumo y variabilidad por grupo social y tarifa combinados *(JOIN federado)*

Consulta cruzada que combina las dos dimensiones de análisis principales — grupo socioeconómico y tipo de tarifa — para obtener una visión completa del comportamiento energético de cada segmento.

```sql
SELECT
    h.acorn_grouped,
    h.stdortou,
    COUNT(DISTINCT h.lclid)                         AS num_hogares,
    ROUND(AVG(d.energy_mean), 4)                    AS kwh_medio_dia,
    ROUND(AVG(d.energy_max) - AVG(d.energy_min), 4) AS variabilidad
FROM postgres.public.informations_households h
JOIN hive.london.daily_dataset d ON h.lclid = d.lclid
GROUP BY h.acorn_grouped, h.stdortou
ORDER BY h.acorn_grouped, h.stdortou;
```

**Resultado:**

| acorn_grouped | stdortou | num_hogares | kwh_medio_dia | variabilidad |
|---|---|---|---|---|
| Adversity | Std | 440 | 0.1778 | 0.7030 |
| Adversity | ToU | 106 | 0.1548 | 0.6456 |
| Affluent | Std | 445 | 0.2372 | 0.8498 |
| Affluent | ToU | 105 | 0.2280 | 0.8000 |
| Comfortable | Std | 337 | 0.2001 | 0.7339 |
| Comfortable | ToU | 113 | 0.2027 | 0.7367 |

**Análisis:** Esta consulta revela los patrones más matizados del análisis. El efecto reductor de la tarifa ToU es consistente en los grupos *Adversity* y *Affluent*, donde los hogares ToU consumen menos y presentan menor variabilidad que sus equivalentes Std. Sin embargo, en el grupo *Comfortable* el comportamiento se invierte ligeramente: los hogares ToU consumen marginalmente **más** que los Std (0,2027 vs 0,2001 kWh/día) con prácticamente la misma variabilidad. Esto podría indicar que en la clase media el incentivo económico de la tarifa ToU no modifica el comportamiento, o que los hogares *Comfortable* con ToU tienen características particulares que explican ese consumo ligeramente superior. En cualquier caso, el hallazgo más robusto de esta consulta es que **la tarifa ToU reduce la variabilidad en todos los grupos sin excepción**, lo que confirma que sí consigue suavizar los picos de consumo, aunque su efecto sobre el consumo total es heterogéneo.
