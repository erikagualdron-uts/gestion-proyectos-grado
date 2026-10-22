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

## Despliegue en Clever Cloud
Tipo de app: Java + WAR (Tomcat 9, Java 21). Variables propias: `CC_JAVA_VERSION=21` y `CC_PRE_BUILD_HOOK="jar cf app.war -C webapp ."` (arma el WAR sin Maven). `clevercloud/war.json` declara el contenedor. Para publicar: `clever deploy`.

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

## Correos institucionales
Estudiantes: `@uts.edu.co`. Docentes, coordinador y administrador: `@correo.uts.edu.co`.

## Usuarios de prueba (solo para demostración)
Cargar `sql/datos_prueba.sql`. Contraseña de todas las cuentas: `Prueba2026*`.

| Rol | Correo |
|---|---|
| Coordinador | coordinador.prueba@correo.uts.edu.co |
| Docente 1 (director del proyecto de prueba) | docente1.prueba@correo.uts.edu.co |
| Docente 2 (evaluador del proyecto de prueba) | docente2.prueba@correo.uts.edu.co |
| Estudiante (aprobada, nivel Tecnológico) | estudiante.prueba@uts.edu.co |
| Estudiante (cuenta pendiente) | pendiente.prueba@uts.edu.co |

## Ramas
`main` (estable) y `develop` (trabajo).
