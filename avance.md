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


## Miércoles – Plantilla, seguridad y acceso (RF-01 a RF-07)
**Implementado**
- Plantilla común: `cabecera.jsp`, `menu.jsp`, `pie.jsp`, `mensaje.jsp` y `css/estilos.css` (Bootstrap 5, Montserrat/Inter, paleta de `DISENO.md`).
- `seguridad.jsp`: sesión, cuenta vigente (aprobada y activa), rol (`rolesPermitidos`), token CSRF por sesión y páginas de proceso solo POST. `web.xml` prohíbe scriptlets.
- Registro de estudiante con validación en navegador y en servidor; contraseña con hash y sal (SHA2); cuenta en estado Pendiente; evento en historial.
- Inicio de sesión con mensajes para cuenta pendiente, rechazada o inactiva, y casilla "Mantener sesión activa" (`sesion_persistente`, el token se guarda solo como hash).
- Cierre de sesión (borra la sesión recordada), menú lateral y tarjetas de inicio según el rol, campana con contador, página de acceso denegado y de error.
- `sql/datos_prueba.sql`: un usuario por rol, una cuenta pendiente, dos ideas, una propuesta aprobada y un proyecto en Fase 2.

**Pantallas:** `index.jsp` (login), `registro.jsp`, `inicio.jsp`, `acceso_denegado.jsp`, `error.jsp`.
**Procesos:** `login_proc.jsp`, `registro_proc.jsp`, `cerrar_sesion.jsp`.
**Requerimientos:** RF-01, RF-02, RF-03, RF-05, RF-06, RF-07 (RF-04 se hace en el módulo de usuarios); RNF-01 a RNF-06, RNF-19.

**Problemas resueltos**
- El conector MySQL 8 ignora los alias de columna con JSTL (`r.nombre AS rol` llegaba como `nombre`): se añadió `useOldAliasMetadataBehavior=true` a la URL de conexión.
- El formulario POST se leía en ISO-8859-1: `fmt:requestEncoding` en `seguridad.jsp`.

**Decisiones**
- Correos: estudiantes `@uts.edu.co` (el registro solo acepta este dominio); docentes, coordinador y administrador `@correo.uts.edu.co` (los crea el administrador).
- Los menús y tarjetas siguen la tabla 5.2 del PDF; las imágenes de `docs/referencia/` se usan solo como referencia de diseño. El estudiante llega a seguimiento, historial, PQRS e informe desde Propuesta Banco.
- Las opciones de menú de módulos aún no construidos llevan a la página "Página no disponible" (aceptado).

**Pruebas hechas en el despliegue (con peticiones HTTP):** login de administrador, coordinador, estudiante y docente; clave incorrecta; cuenta pendiente; POST sin token CSRF; acceso sin sesión; sesión recordada y cierre de sesión; validaciones del registro. **Sin probar aún:** acceso denegado por rol (aún no hay páginas restringidas por rol; se prueba con el módulo de usuarios).

## Jueves – Módulo 1: Usuarios, aprobación de cuentas y perfil (RF-08 a RF-16)
**Implementado**
- **Usuarios** (administrador): tarjetas de resumen, búsqueda por nombre, correo o documento, filtros por rol y estado, tabla con paginación (5, 10 o 20 por página), ventana de detalle (ojo) y edición (lápiz).
- **Crear y editar usuarios**: administradores, coordinadores y docentes con contraseña inicial (hash y sal); el administrador puede cambiar documento y correo y restablecer la contraseña; inactivar y reactivar (borrado lógico, se conserva el historial). No se puede inactivar la propia cuenta ni dejar el sistema sin administrador activo.
- **Solicitudes de cuenta**: lista de estudiantes pendientes; aprobar exige el nivel (Tecnológico o Profesional); rechazar exige observación y confirmación y no asigna nivel.
- **Mi perfil** (todos los roles): nombre y tipo de documento editables; documento, correo, rol y nivel visibles y bloqueados; foto por enlace (cambiar o eliminar, imagen por defecto); cambio de contraseña.
- Aviso en el inicio del administrador con las solicitudes pendientes.
- Todo cambio queda en `historial_version` (registro, creación, edición, inactivación, aprobación o rechazo, perfil, contraseña).

**Pantallas:** `usuarios/usuarios.jsp`, `usuarios/usuario_form.jsp`, `usuarios/cuentas_pendientes.jsp`, `perfil/perfil.jsp`.
**Procesos:** `usuario_proc.jsp`, `cuenta_decision_proc.jsp`, `perfil_proc.jsp`. **Fragmento nuevo:** `paginacion.jsp`; scripts `tablas.js`.
**Requerimientos:** RF-04, RF-08, RF-09, RF-10, RF-11, RF-12, RF-13, RF-14, RF-15, RF-16. **Historias:** HU-03, HU-04, HU-05, HU-06, HU-07.

**Problemas resueltos**
- `fmt:formatNumber` devolvía "2.0" y rompía el cálculo de páginas; el total se calcula con EL y `fn:substringBefore`.
- Los datos de la sesión (nombre, foto, rol, nivel) se refrescan desde la base en cada página, así un cambio hecho por el administrador se ve de inmediato.

**Pruebas hechas en el despliegue (peticiones HTTP):** crear usuario con dominio incorrecto, rol inválido, claves distintas y duplicado; crear, editar (documento, correo, rol y contraseña), inactivar y reactivar; login del inactivo; aprobar sin nivel y rechazar sin observación; aprobar y rechazar; volver a decidir una cuenta ya gestionada; login de aprobado y rechazado; **acceso denegado por rol** (estudiante y docente a páginas del administrador, y a sus procesos); POST sin token y sin sesión; perfil (validaciones, foto, enlace no válido, quitar foto, documento y correo no modificables por POST, cambio de contraseña); nombres con HTML se muestran escapados.
**Decisiones:** el estudiante rechazado no puede reactivarse desde la pantalla (solo se edita su información); el correo del personal debe ser `@correo.uts.edu.co` y el de estudiantes `@uts.edu.co`.
