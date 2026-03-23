-- postgres/init.sql
-- Se ejecuta solo la primera vez que se inicializa el volumen de Postgres.

-- ── Metastore de Hive ─────────────────────────────────────────────────────
CREATE DATABASE metastore_db;
GRANT ALL PRIVILEGES ON DATABASE metastore_db TO demo;

-- ── Datos de hogares (ejercicio 1) ────────────────────────────────────────
CREATE DATABASE london_db;
GRANT ALL PRIVILEGES ON DATABASE london_db TO demo;

\connect london_db

CREATE TABLE informations_households (
    lclid         VARCHAR(20)  PRIMARY KEY,
    stdortou      VARCHAR(10),
    acorn         VARCHAR(20),
    acorn_grouped VARCHAR(30),
    file          VARCHAR(20)
);

\copy informations_households(lclid, stdortou, acorn, acorn_grouped, file) FROM '/docker-entrypoint-initdb.d/data/informations_households.csv' WITH (FORMAT csv, HEADER true)
