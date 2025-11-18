# Big Data – Sesión 2 Motores de SQL para Big Data

Este repositorio contiene el entorno de desarrollo para la **Sesión 2: Motores de SQL para Big Data**.

## 🚀 Características

- ⚡ **Trino**: Motor de consultas distribuido ultrarrápido para análisis interactivo.  
- 📁 Integración completa con **HDFS** y configuración sobre Docker.  
- 🗄️ Ejemplos prácticos y scripts para cargar datos y ejecutar queries.  
- 🔄 Entorno modular y fácil de extender para prácticas avanzadas.

## 📂 Estructura del Repositorio

```
📂 S2-BigDataSQL/
├── 📄 docker-compose.yml
├── 📄 dockerfile
├── 📂 mysql/
├── 📂 postgres/
├── 📂 trino-config/
```

## 🛠️ Requisitos

- **Docker** y **Docker Compose** instalados.  
- **RAM** recomendada: 8GB+  
- **Espacio en disco**: ~5GB

## ⚡ Instalación y Uso

1️⃣ Clona este repositorio:  
```sh
git clone https://github.com/<tu-org>/S2-BigDataSQL.git
cd S2-BigDataSQL
```

2️⃣ Inicia el entorno Trino:  
```sh
docker-compose up -d
```

3️⃣ Comprueba los contenedores:  
```sh
docker ps
```

4️⃣ Accede al contenedor de Trino:  
```sh
docker exec -it trino bash
```

5️⃣ Accede al CLI de Trino:  
```sh
docker exec -it trino trino

```

## 📌 Comandos Útiles


### 🔹 Trino
```sql
SHOW CATALOGS;
SHOW SCHEMAS FROM mysql;

```

## 📝 Notas

- Trino puede tardar unos segundos en inicializarse.  
- Si modificas los catálogos o configuraciones, reinicia los servicios:  
```sh
docker-compose down
docker-compose up -d
```

## 🐞 FAQ



**Trino no muestra el catálogo**  
Revisa la configuración del conector en `trino-config/catalog/mysql.properties`.

## 📖 Referencias

- [Documentación oficial de Trino](https://trino.io/docs/current/)  
- [Docker Hub – Trino Images](https://hub.docker.com/)
