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

## Jueves – Módulo 2: Inicio, base documental, banco de ideas y propuestas (RF-17 a RF-28)
**Implementado**
- **Inicio** (RF-17, RF-18): tarjetas según el rol, tarjeta "Calendario académico" que abre el enlace externo, panel del proyecto del estudiante y aviso de solicitudes pendientes para el administrador.
- **Base documental** (RF-19, RF-20): tarjetas con los enlaces activos, que abren en otra pestaña; los que aún no tienen URL se muestran "por configurar". El administrador crea, edita, ordena (por número) y desactiva enlaces desde "Administrar enlaces".
- **Banco de ideas** (RF-23, RF-24): solo ideas aprobadas y disponibles, solo lectura, con búsqueda, paginación y ventana de detalle. El estudiante elige una idea (la idea queda no disponible) y el docente propone ideas.
- **Proponer idea** (docente, RF-21): título, descripción, objetivo y alcance obligatorios; queda pendiente.
- **Propuesta propia** (estudiante, RF-25): título, objetivo y alcance obligatorios; la descripción es opcional (si se omite se copia el título).
- **Segundo estudiante** (RF-26): se busca por número de documento y se valida que exista, tenga cuenta aprobada y activa, sea otra persona y no esté en otra propuesta activa. Se puede agregar, cambiar o quitar mientras la propuesta esté pendiente o aplazada.
- **Propuestas Banco** (RF-22, RF-27 y base de RF-29 a RF-32): tabla única de ideas de docentes y propuestas de estudiantes, con tarjetas de resumen, búsqueda, filtros por tipo y estado, paginación, ojo (detalle) y lápiz (gestionar). El coordinador aprueba, aplaza (observación obligatoria) o rechaza (observación y confirmación); docentes y administrador solo visualizan; el estudiante ve las suyas.
- **Al aprobar una propuesta** se crea el proyecto en la Fase 1 con sus seis fases, todo en una transacción; al **rechazar** una propuesta tomada del banco la idea vuelve a estar disponible.
- **Corregir y reenviar** (RF-28): una propuesta aplazada se edita y vuelve a Pendiente; el historial conserva la versión anterior y numera las versiones.
- **Avisos internos**: nueva idea o propuesta (coordinadores), decisiones (docente y estudiantes), idea elegida y compañero agregado. Se ven en el contador de la campana.
- Una propuesta activa por estudiante (pendiente, aplazada o aprobada); si se rechaza puede crear otra.

**Pantallas:** `base_documental.jsp`, `enlaces_admin.jsp`, `banco_ideas.jsp`, `idea_form.jsp`, `propuesta_form.jsp`, `propuestas_banco.jsp` (el detalle y la decisión son ventanas modales, no páginas aparte).
**Procesos:** `enlace_proc.jsp`, `idea_proc.jsp`, `propuesta_proc.jsp`.
**Requerimientos:** RF-17 a RF-28, y parte de RF-29 a RF-32. **Historias:** HU-08 a HU-19 (HU-10 incluida).

**Problemas resueltos**
- El conector MySQL devolvía el nombre real de la columna en vez del alias (ya resuelto en el módulo de acceso con `useOldAliasMetadataBehavior`).
- La restricción única `uq_propuesta_id_idea` impedía volver a elegir una idea de una propuesta rechazada: al rechazar se desliga la idea (queda registrada en el historial) y se libera.
- Los códigos `ID-000N` y `PG-000N` se generan a partir del id insertado (primero un código temporal y luego el definitivo) para evitar duplicados bajo concurrencia.

**Pruebas hechas en el despliegue (peticiones HTTP):** idea del docente con validación, decisión del coordinador (aplazar sin observación, aprobar, decidir de nuevo); el estudiante elige la idea y otro estudiante no puede elegirla; compañero inexistente, el mismo estudiante, ocupado y válido; aplazar, corregir y reenviar, aprobar y creación del proyecto con sus seis fases; rechazo con liberación de la idea; propuesta propia con compañero; una sola propuesta activa; accesos y procesos prohibidos por rol; administración de enlaces (URL, icono y orden inválidos, crear, editar, desactivar) y la tarjeta de calendario.
**Pendiente / decisiones:** la opción "ver seguimiento" en cada fila (RF-33) y la asignación de director y evaluador se hacen en el módulo 3. Las ideas de docentes aplazadas no se reenvían (solo las propuestas de estudiantes, RF-28).

### Ajustes posteriores al módulo 2
- El compañero agregado a una propuesta queda **fijo**: no se quita ni se cambia (formulario y servidor).
- Regla definida para los módulos siguientes: solo el **responsable** (quien postula) entrega documentos, corrige la propuesta y radica PQRS; el compañero solo visualiza. Si el responsable se inactiva, el proyecto no recibe documentos (no se transfiere la responsabilidad).
- Cuentas de prueba de docentes renombradas a `docente1.prueba` y `docente2.prueba` (ambas con rol Docente; un docente usa un solo correo y ve los módulos Director y Evaluador).
- Los seis enlaces de la base documental se precargarán cuando la estudiante los entregue.

### Estado al cierre de la sesión (22/10/2026)
- `main`: módulo de acceso (RF-01 a RF-07) y módulo 1 (usuarios, cuentas y perfil, RF-08 a RF-16), probados.
- `develop`: además, módulo 2 (RF-17 a RF-28), pendiente de que lo pruebe la estudiante antes de integrarlo a `main`.
- Siguiente: módulo 3 (tabla de solicitudes, asignación de director y evaluador, RF-29 a RF-37).
