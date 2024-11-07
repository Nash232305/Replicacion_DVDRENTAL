# DVD Rental - Proyecto de Inteligencia de Negocios

## Descripción

Este proyecto implementa una solución básica de inteligencia de negocios que abarca desde la configuración de una replicación de base de datos en **PostgreSQL** hasta la visualización de datos en **Tableau**. El objetivo principal es permitir a los usuarios explorar datos relacionados con el alquiler de películas, ofreciendo soporte en la toma de decisiones a través de análisis visuales y tableros interactivos.

---

## Características principales

1. **Base de Datos Relacional (PostgreSQL)**:
   - Replicación configurada en modo **Hot-Standby** para garantizar alta disponibilidad y recuperación ante fallos.
   - Uso de **procedimientos almacenados** para gestionar transacciones como:
     - Inserción de clientes.
     - Registro de alquileres.
     - Registro de devoluciones.

2. **Modelo Multidimensional (Esquema Estrella)**:
   - Creación de tablas de hechos y dimensiones para el análisis de datos.
   - Procedimientos para la carga de datos desde el sistema transaccional al modelo analítico.

3. **Visualización de Datos (Tableau)**:
   - Conexión directa a PostgreSQL.
   - Gráficos interactivos como:
     - Monto total de alquileres por categoría.
     - Rentabilidad por sucursal y mes.
     - Top 10 actores con más alquileres.
     - Mapa geográfico de ingresos por ciudad.
   - Dashboard consolidado para análisis integral.

---

## Instalación y Configuración

### 1. Configuración de la Base de Datos:
#### Servidor Primario:
- Instalar PostgreSQL.
- Configurar los archivos `postgresql.conf` y `pg_hba.conf`.
- Crear el usuario de replicación y permisos necesarios.

#### Réplica (Hot-Standby):
- Instalar la segunda instancia de PostgreSQL desde binarios.
- Configurar replicación mediante `pg_basebackup`.

Para más detalles, consulta la [guía completa de instalación](./Replicacion.pdf).

---

### 2. Configuración de Tableau:
- Conectar Tableau a la base de datos **dvdrental**.
- Configurar relaciones entre tablas y vistas según el modelo estrella.
- Crear visualizaciones y dashboards interactivos.

---

## Estructura del Proyecto

- **`Script proyecto bd2 PY2.sql`**: Script SQL con la configuración y creación de tablas y vistas.
- **`Tableau.twbx`**: Archivo de Tableau con las visualizaciones y dashboards.
- **`Replicacion.pdf`**: Documentación detallada de la instalación y configuración del entorno.
- **`dvdrental.tar`**: Backup de la base de datos original para replicación.

---

## Resultados

El proyecto ofrece una solución robusta para analizar datos de alquiler de películas, con resultados como:
- Identificación de las categorías más rentables.
- Seguimiento del desempeño de sucursales y actores.
- Insights geográficos sobre ingresos.

---

¡Gracias por visitar este repositorio! Si tienes preguntas o sugerencias, no dudes en contactarme.
