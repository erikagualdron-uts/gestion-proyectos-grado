# Avance del proyecto

## Miércoles – Base del proyecto (terminado)
**Implementado**
- Repositorio GitHub `erikagualdron-uts/gestion-proyectos-grado` (público) con ramas `main` y `develop`.
- Estructura de carpetas del PDF (sección 9.1), `.gitignore` y `README.md`.
- `sql/schema.sql` (15 tablas) y `sql/datos_iniciales.sql` (roles, fases, enlaces, administrador de prueba).
- Base MySQL 8 en Clever Cloud (`gestion-proyectos-grado-db`, plan DEV) con el script cargado.
- Aplicación Tomcat 9 + JSTL 1.2 en Clever Cloud, enlazada al MySQL.
- `conexion.jsp` lee las credenciales de variables de entorno; `index.jsp` mínima que comprueba la conexión.

**Despliegue**
- Clever Cloud no construye WAR sin Maven: `CC_PRE_BUILD_HOOK="jar cf app.war -C webapp ."` genera el WAR y `clevercloud/war.json` lo declara (contenedor TOMCAT9, Java 21).
- URL: https://app-44af3d7a-a088-4a3a-ad4a-086d8ad44fe6.cleverapps.io/

**Problemas resueltos**
- Tomcat 10 usa `jakarta` y no es compatible con JSTL 1.2 ni con el XAMPP local (8.5): se eligió Tomcat 9.
- En los atributos JSP, `&amp;` llegaba literal a la URL JDBC; se usa `&`.
- El script del PDF usaba `CREATE DATABASE`/`USE gestion_grado`; se quitó porque Clever Cloud asigna el nombre de la base.

**Pendiente de este bloque:** plantilla común, seguridad, registro, login, logout y menú por rol (RF-01 a RF-07).
