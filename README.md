# Sistema de Gestión de Proyectos de Grado

Aplicación web de las UTS para gestionar los proyectos de grado: banco de ideas, propuestas, seis fases con entrega de documentos por enlace, revisión y calificación, PQRS, notificaciones y panel de control.

- **Estudiante:** Erika Viviana Gualdrón Parra · Tecnología en Desarrollo de Sistemas Informáticos · Programación JAVA.
- **Tecnología:** JSP + JSTL 1.2 (core, fmt, functions, sql), Apache Tomcat 9, MySQL 8. Sin Maven ni clases `.java`; sin scriptlets.
- **Despliegue:** Clever Cloud (Java + WAR). **Código:** GitHub.
- **Única librería de navegador además de Bootstrap:** Chart.js (gráficos del Panel de control, desde CDN).

## Qué hace cada rol
| Rol | Qué puede hacer |
|---|---|
| **Administrador** | Crea coordinadores, docentes y administradores; aprueba o rechaza las cuentas de estudiantes (asignando nivel Tecnológico o Profesional); administra los enlaces de la base documental. |
| **Coordinador** | Decide sobre ideas de docentes y propuestas de estudiantes; asigna director y evaluador; valida el pago y decide como comité; resuelve PQRS; consulta el Panel de control. |
| **Estudiante** | Se registra (queda pendiente hasta que se apruebe); elige una idea del banco o propone una propia; puede agregar un compañero (solo consulta); el responsable entrega los documentos por enlace y radica PQRS. |
| **Docente** | Propone ideas; como director o evaluador de un proyecto, revisa y califica documentos. Nunca es director y evaluador del mismo proyecto. |

Las fases son: 1 Pago, 2 Propuesta I, 3 Propuesta II, 4 Informe I, 5 Informe II y 6 Revisión final (al aprobarse todas, el proyecto queda **listo para sustentación**).

## Estructura
```
docs/      documentación, diseño de referencia y capturas
sql/       schema.sql (tablas), datos_iniciales.sql y datos_prueba.sql
webapp/    aplicación web (raíz del WAR)
clevercloud/war.json   contenedor para Clever Cloud
```
Detalle de carpetas en la sección 9 del documento del sistema (`docs/`). El registro de lo construido, las decisiones y las diferencias con el documento del sistema está en `avance.md`.

## Instalación
1. Crear una base MySQL 8 vacía.
2. Ejecutar `sql/schema.sql` y luego `sql/datos_iniciales.sql` (administrador inicial y enlaces de la base documental).
3. Opcional, solo para demostración: ejecutar `sql/datos_prueba.sql` (un usuario por rol, ideas, una propuesta y un proyecto).
4. Definir las variables de entorno de la tabla siguiente y desplegar `webapp/` como WAR en Tomcat 9 (Java 17 o superior). Las librerías (`jstl-1.2.jar` y el conector de MySQL) ya están en `webapp/WEB-INF/lib`.

### Variables de entorno
La conexión nunca está escrita en el código; se leen estas variables (las define Clever Cloud al enlazar el add-on MySQL):

| Variable | Contenido |
|---|---|
| `MYSQL_ADDON_HOST` | Servidor |
| `MYSQL_ADDON_PORT` | Puerto |
| `MYSQL_ADDON_DB` | Nombre de la base |
| `MYSQL_ADDON_USER` | Usuario |
| `MYSQL_ADDON_PASSWORD` | Contraseña |

### Hora de Colombia
La conexión (`webapp/WEB-INF/includes/conexion.jsp`) fija la sesión de MySQL en la hora de Colombia (`-05:00`), porque el servidor de Clever Cloud trabaja en UTC. Si se instala en otro país, cambia ese valor en la URL de conexión.

## Despliegue en Clever Cloud
Tipo de app: Java + WAR (Tomcat 9, Java 21). Variables propias: `CC_JAVA_VERSION=21` y `CC_PRE_BUILD_HOOK="jar cf app.war -C webapp ."` (arma el WAR sin Maven). `clevercloud/war.json` declara el contenedor. Para publicar: `clever deploy` (publica la rama actual). Después de cada despliegue, la aplicación reinicia y se cierran las sesiones abiertas.

## Base documental
Seis tarjetas con enlaces externos: calendario académico, formatos institucionales, presentación de propuesta (F-DC-124), presentación de informe final (F-DC-125), reglamento de estímulos y reglamento de trabajos de grado.
- Los enlaces públicos de la UTS vienen en `sql/datos_iniciales.sql`.
- Los enlaces de **Dropbox** (formatos, propuesta e informe final) llevan una clave de acceso compartida y **no están en el repositorio**: el administrador los carga desde *Base documental → Administrar enlaces*.
- Los PDF de los formatos institucionales (`docs/F-DC-*.pdf`) son solo de referencia local y no se suben.

## Datos de demostración del despliegue
La base desplegada tiene un juego de datos de demostración: coordinadora y docentes con sus nombres reales, estudiantes totalmente inventados y documentos ficticios (los enlaces apuntan a PDF de ejemplo). Esas cuentas y sus contraseñas **no están en el repositorio**; se entregan aparte. Las cuentas de abajo son las genéricas de `sql/datos_prueba.sql`, para quien instale el sistema desde cero.

## Usuarios de prueba (solo para demostración, sin datos reales)
Contraseña de las cuentas de `sql/datos_prueba.sql`: `Prueba2026*`.

| Rol | Correo |
|---|---|
| Administrador (de `datos_iniciales.sql`) | admin@correo.uts.edu.co (la contraseña inicial está en el script; cámbiala tras el primer ingreso) |
| Coordinador | coordinador.prueba@correo.uts.edu.co |
| Docente 1 (director del proyecto de prueba) | docente1.prueba@correo.uts.edu.co |
| Docente 2 (evaluador del proyecto de prueba) | docente2.prueba@correo.uts.edu.co |
| Estudiante (cuenta aprobada, nivel Tecnológico) | estudiante.prueba@uts.edu.co |
| Estudiante (cuenta pendiente de aprobación) | pendiente.prueba@uts.edu.co |

Correos institucionales: estudiantes `@uts.edu.co`; docentes, coordinador y administrador `@correo.uts.edu.co`.

## Seguridad
- Contraseñas con hash y sal (SHA2 de MySQL); nunca en texto plano.
- Todas las consultas usan parámetros (`<sql:param>`) y las operaciones sobre varias tablas, transacciones.
- Cada página protegida verifica sesión y rol en el servidor (el menú nunca es la única barrera) y los formularios de modificación llevan token anti-CSRF.
- Todo texto ingresado por el usuario se muestra escapado (`<c:out>`).
- Los documentos se guardan solo como enlace (URL), nunca como archivo.

## Ramas
`main` (estable) y `develop` (trabajo).
