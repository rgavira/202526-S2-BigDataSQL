-- ── CONSULTA 1 ───────────────────────────────────────────────
-- Distribución de hogares por grupo socioeconómico y tarifa
-- Fuente: PostgreSQL únicamente (sin JOIN)
-- ─────────────────────────────────────────────────────────────
SELECT
    acorn_grouped,
    stdortou,
    COUNT(*) AS num_hogares
FROM postgres.public.informations_households
GROUP BY acorn_grouped, stdortou
ORDER BY acorn_grouped, stdortou;


-- ── CONSULTA 2 ───────────────────────────────────────────────
-- Consumo medio diario por grupo socioeconómico
-- Fuente: JOIN federado PostgreSQL + MinIO
-- ─────────────────────────────────────────────────────────────
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


-- ── CONSULTA 3 ───────────────────────────────────────────────
-- Efecto de la tarifa ToU vs Estándar sobre el consumo
-- Fuente: JOIN federado PostgreSQL + MinIO
-- ─────────────────────────────────────────────────────────────
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


-- ── CONSULTA 4 ───────────────────────────────────────────────
-- Top 10 hogares con mayor consumo total acumulado
-- Fuente: JOIN federado PostgreSQL + MinIO
-- ─────────────────────────────────────────────────────────────
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


-- ── CONSULTA 5 ───────────────────────────────────────────────
-- Evolución mensual del consumo medio (estacionalidad)
-- Fuente: MinIO únicamente (sin JOIN)
-- ─────────────────────────────────────────────────────────────
SELECT
    date_trunc('month', d.day)   AS mes,
    ROUND(AVG(d.energy_mean), 4) AS kwh_medio_dia,
    ROUND(AVG(d.energy_max),  4) AS pico_kwh
FROM hive.london.daily_dataset d
GROUP BY date_trunc('month', d.day)
ORDER BY mes;


-- ── CONSULTA 6 ───────────────────────────────────────────────
-- Búsqueda de hogares con consumo anómalamente alto (> 1.5 kWh/día medio)
-- Resultado: 0 filas — umbral por encima del máximo real del dataset
-- Fuente: JOIN federado PostgreSQL + MinIO
-- ─────────────────────────────────────────────────────────────
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


-- ── CONSULTA 7 ───────────────────────────────────────────────
-- Consumo y variabilidad por grupo socioeconómico y tarifa combinados
-- Fuente: JOIN federado PostgreSQL + MinIO
-- ─────────────────────────────────────────────────────────────
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
