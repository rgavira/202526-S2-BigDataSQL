-- mysql/init.sql
-- Se ejecuta solo la primera vez que se inicializa el volumen de MySQL.

-- Crear base de datos (por si acaso)
CREATE DATABASE IF NOT EXISTS ventas_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Dar permisos al usuario 'demo' por si no viniera perfecto del entrypoint
GRANT ALL PRIVILEGES ON ventas_db.* TO 'demo'@'%';
FLUSH PRIVILEGES;
