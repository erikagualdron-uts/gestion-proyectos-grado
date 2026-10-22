# Sistema de Gestión de Proyectos de Grado

Aplicación web de las UTS para gestionar los proyectos de grado: banco de ideas, propuestas, fases, entrega de documentos por enlace, revisión y calificación, PQRS, notificaciones e informes.

- **Estudiante:** Erika Viviana Gualdrón Parra · Tecnología en Desarrollo de Sistemas Informáticos · Programación JAVA.
- **Tecnología:** JSP + JSTL, Apache Tomcat, MySQL 8. Sin Maven ni clases .java.
- **Despliegue:** Clever Cloud. **Código:** GitHub.

## Estructura
```
docs/      documentación, diseño de referencia y capturas
sql/       schema.sql (15 tablas) y datos_iniciales.sql
webapp/    aplicación web (raíz del WAR)
```
Detalle de carpetas en la sección 9 del documento del sistema (`docs/`).

## Base de datos
1. Crear una base MySQL 8 vacía.
2. Ejecutar `sql/schema.sql` y luego `sql/datos_iniciales.sql`.

## Variables de entorno
La conexión nunca está escrita en el código; se leen estas variables (las define Clever Cloud al enlazar el add-on MySQL):

| Variable | Contenido |
|---|---|
| `MYSQL_ADDON_HOST` | Servidor |
| `MYSQL_ADDON_PORT` | Puerto |
| `MYSQL_ADDON_DB` | Nombre de la base |
| `MYSQL_ADDON_USER` | Usuario |
| `MYSQL_ADDON_PASSWORD` | Contraseña |

## Usuario inicial
`sql/datos_iniciales.sql` crea un administrador **solo para pruebas**: `admin@correo.uts.edu.co` (la contraseña de prueba está en el script; cámbiala tras el primer ingreso). Los usuarios de demostración por rol irán en `sql/datos_prueba.sql` (solo para pruebas, sin datos reales).

## Ramas
`main` (estable) y `develop` (trabajo).
