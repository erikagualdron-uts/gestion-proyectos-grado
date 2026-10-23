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
- Los menús y tarjetas siguen la tabla 5.2 del PDF; las imágenes de `docs/referencia/` se usan solo como referencia de diseño. El estudiante llega a seguimiento, historial, PQRS e informe desde "Mis propuestas" (en el menú del estudiante y en el título de la pantalla se usa "Mis propuestas" en lugar de "Propuesta Banco" por claridad; los demás roles ven "Propuestas Banco").
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

## Jueves – Módulo 3: Asignación de proyectos (RF-33 a RF-37)
**Implementado**
- **Asignación de director y evaluador** (coordinador, RF-34, RF-35): tabla de proyectos con tarjetas de resumen (proyectos, sin director, sin evaluador, completos), búsqueda por código, título, estudiante, director o evaluador, filtro por estado de asignación y paginación. El lápiz abre una ventana para elegir director y evaluador entre los docentes activos.
- **Reglas**: el director y el evaluador deben ser docentes distintos (en el navegador, en el servidor y con la restricción de la base de datos); solo se aceptan docentes activos con cuenta aprobada; solo se modifican proyectos en curso. Se puede reasignar o quitar un docente.
- **Trazabilidad y avisos**: cada cambio queda en el historial del proyecto; se avisa al docente asignado y a los estudiantes del proyecto.
- **Buscar estudiante** (RF-36): por documento, nombre, correo o código de propuesta; muestra su propuesta (o anteproyecto), estado, fase, director y evaluador, e indica si es compañero.
- **Información para el estudiante** (RF-37): el inicio muestra su director y su evaluador (o "Por asignar").
- **Seguimiento por fila** (RF-33): en Propuestas Banco y en las tablas de proyectos aparece la opción de ver el seguimiento (la pantalla de seguimiento se construye en el módulo 4).

**Pantallas:** `proyectos/asignacion.jsp` (la pantalla `buscar_estudiante.jsp` se eliminó después). **Proceso:** `asignacion_proc.jsp`.
**Requerimientos:** RF-33 (enlace), RF-34, RF-35, RF-36, RF-37. **Historias:** HU-20 y HU-21.

**Problemas resueltos**
- `es_responsable` (TINYINT(1)) llega como verdadero/falso y no se puede comparar con 0: se usa `not e.es_responsable`.

**Pruebas hechas en el despliegue (peticiones HTTP):** lista, filtros y búsqueda; mismo docente como director y evaluador; usuarios que no son docentes; docente inactivo (no aparece ni se acepta por POST directo); proyecto inexistente y datos no numéricos; guardar sin cambios; cambiar, quitar y restaurar la asignación; inicio del estudiante con director y evaluador; búsqueda de estudiantes (documento, nombre, código, sin resultados); accesos y procesos prohibidos para docente, estudiante y administrador.
**Pendiente:** la pantalla de seguimiento a la que enlazan los ojos (módulo 4).

## Jueves – Módulo 4: Fases, entregas, revisiones y módulos de docentes (RF-38 a RF-52)
**Reglas del flujo (definidas a partir del PDF)**
| Fase | Entrega | Decide |
|---|---|---|
| 1 Pago | Estudiante responsable (comprobante) | Coordinador (comité) |
| 2 Propuesta I | Estudiante responsable (anteproyecto) | Director |
| 3 Propuesta II | Se copia el documento aprobado en la fase 2 | El director aprueba el envío; luego evaluador y comité (avanza cuando ambos aprueban) |
| 4 Informe I | Estudiante responsable (informe) | Director |
| 5 Informe II | Se copia el informe aprobado en la fase 4 | Igual que la fase 3 |
| 6 Revisión final | Estudiante responsable (informe final) | Evaluador y comité (ambos) |
- Aplazado: el proyecto se queda en la fase, el responsable sube una nueva versión (v2, v3…) y la revisión vuelve a empezar; las versiones anteriores se conservan y la vigente queda marcada. En las fases 3 y 5 la nueva versión vuelve primero al director.
- Rechazado: exige observación y confirmación y cierra el proyecto. Fase 6 aprobada: el proyecto queda "Listo para sustentación".
- Rejilla de evaluación (la adjunta el evaluador) y Turnitin (lo adjunta el director en la fase 5): enlaces opcionales al calificar.
- Solo el responsable entrega; el compañero solo visualiza. Si el responsable está inactivo, el proyecto no recibe documentos.

**Implementado**
- **Seguimiento** (`proyectos/seguimiento.jsp`): línea de tiempo con las seis tarjetas (verdes las superadas y la actual con aro lima, grises las pendientes, roja la rechazada), detalle de la fase elegida con sus documentos y versiones (estado, quién entregó y enlace), tabla de revisiones, ventana "Detalles del proyecto", entrega por enlace del responsable y botón para calificar. Acceso: estudiantes del proyecto, director y evaluador asignados, coordinador y administrador.
- **Entrega por enlace** (`entrega_proc.jsp`): valida URL, crea nueva versión vigente, conserva las anteriores y avisa al revisor.
- **Calificar** (`revision_form.jsp`, `revision_proc.jsp`): crear, editar y consultar la revisión; observación obligatoria para aplazar o rechazar; la fase avanza, se devuelve o se cierra según las decisiones; avisos a estudiantes y siguientes revisores; historial de cada paso.
- **Docente Director y Docente Evaluador**: tabla con ID, descripción y estado (fase, estudiantes, "Por revisar"), ojo y lápiz, tarjetas de fase que filtran, búsqueda y paginación. Un docente solo ve los proyectos donde ocupa ese papel.

**Pantallas:** `proyectos/seguimiento.jsp`, `proyectos/revision_form.jsp`, `docente_director/docente_director.jsp`, `docente_evaluador/docente_evaluador.jsp`. **Procesos:** `entrega_proc.jsp`, `revision_proc.jsp`. **Fragmentos:** `fases.jsp`, `proyectos_docente.jsp`.
**Requerimientos:** RF-38 a RF-52 (RF-46 con confirmación en el navegador). **Historias:** HU-22 a HU-32.

**Pruebas hechas en el despliegue (peticiones HTTP):** ciclo completo de las seis fases hasta "Listo para sustentación" (con aplazados en las fases 1, 2 y 3, rejilla y Turnitin); compañero y otros roles que intentan entregar o calificar; enlaces inválidos; entrega mientras el documento está en revisión; evaluador y comité antes de que el director apruebe el envío (también por POST directo); documento cambiado o inexistente; rechazo que cierra el proyecto y bloqueo de nuevas entregas y decisiones; permisos del seguimiento por rol (estudiante ajeno, docente no asignado); tablas de Director y Evaluador con filtro por fase y búsqueda; historial de versiones y revisiones en la base.
**Pendiente / mejoras posibles:** que el coordinador vea en su asignación un indicador de proyectos "por validar".

### Ajuste de diseño (22/10/2026)
- En "Mis propuestas" el estudiante ya no ve las cuatro tarjetas de resumen (solo tiene una propuesta activa y el estado se ve en la tabla). Se conservan el buscador y el filtro de estado para cumplir RF-29 y RF-30. Los demás roles siguen viendo las tarjetas.
- En "Calificar documento" el revisor ve ahora la fase y su estado, el comentario de la entrega, un botón "Abrir documento" (sin repetir el nombre) y las observaciones que recibieron las versiones anteriores, para comprobar que se corrigieron. El orden de los botones de decisión (Rechazar, Aplazar, Aprobar) se mantiene igual en todas las pantallas por coherencia.
- **Rejilla de evaluación y formato F-DC-124:** el formato institucional trae la rejilla dentro del mismo documento (SI/NO por criterio, concepto final y firmas del director y del evaluador) y el informe de similitud en el Anexo A. En el sistema el evaluador adjunta el enlace de su copia diligenciada ("Rejilla de evaluación diligenciada (formato F-DC-124)"): **obligatorio para aprobar en la Fase 3** (si no la adjuntó ya para esa versión) y opcional en las demás fases y decisiones. Diferencias conocidas con el formato: admite hasta 3 estudiantes (el sistema, 2) y pide los datos del pago (LQ, banco, valor); el sistema solo pide el enlace del comprobante.
- En las fases 3 y 5, cuando el evaluador o el comité ya decidieron sobre una versión, la decisión del director queda cerrada (no se puede editar, ni en la pantalla ni en el servidor), para no dejar decisiones contradictorias. Además, el documento que el sistema copia a esas fases se describe como "aprobada en la Fase N y enviada por el director".
- Al aprobar la fase 6 el proyecto se muestra como **"Listo para sustentación"** (antes decía "Apto para graduación"): después de la revisión final lo que sigue es la sustentación del trabajo de grado. Es solo el texto visible: el valor interno en la base de datos sigue siendo `APTO_GRADUACION`.
- **Turnitin obligatorio (fase 5):** como evidencia del reporte de la herramienta antiplagio, el director debe adjuntar el enlace del informe de similitud en **cualquier decisión** (aprobar el envío, aplazar o rechazar), una vez por versión del informe. No se verifica el porcentaje: el sistema solo guarda el enlace.
- "Calificar documento": ahora muestra el progreso de la revisión de la versión (por ejemplo "Director: aprobó · Evaluador: pendiente · Comité: pendiente"), pone primero los enlaces de evidencia (rejilla o Turnitin) y después las observaciones, y el aviso de "Ya registraste una decisión" explica hasta cuándo se puede cambiar.

### Ajustes según los formatos institucionales F-DC-124, F-DC-125 y F-DC-129 (23/10/2026)
- **F-DC-124** es el formato del **anteproyecto** (fases 2 y 3, con su rejilla y el informe de similitud como Anexo A); **F-DC-125** es el formato del **informe de trabajo de grado** (fases 4 y 5); **F-DC-129** es la **rejilla de evaluación del informe** (fase 5).
- Los documentos se llaman ahora "Anteproyecto (F-DC-124)" e "Informe (F-DC-125)", para que el estudiante sepa qué formato usar.
- **Rejilla del evaluador:** obligatoria para aprobar en la **fase 3** (formato F-DC-124, sección de rejilla) y en la **fase 5** (formato F-DC-129), una vez por versión.
- **Fase 6 (Revisión final):** ya no tiene entrega ni revisión. Se alcanza sola cuando el evaluador y el comité aprueban la fase 5, y deja el proyecto **"Listo para sustentación"**. La tarjeta 6 se conserva como estado final.
- Decisión: el informe de similitud (Turnitin) se exige solo al director en la fase 5; en la fase 3 no se pide.
- En el seguimiento, el aviso final dice "Se aprobaron todas las fases del proyecto" y la tarjeta de la fase 6 muestra "Listo para sustentación" en lugar de "Aprobada".
- En el Inicio del estudiante, el panel "Tu proyecto" muestra "Todas las fases aprobadas" y la insignia "Listo para sustentación" cuando el proyecto terminó, y "Proyecto cerrado" cuando se rechazó.

## Jueves – Módulo 5: PQRS, notificaciones, historial e informe de estado (RF-53 a RF-62)
**Implementado**
- **PQRS** (RF-53 a RF-56): el estudiante **responsable** radica (prórroga, cambio de director, petición, queja, reclamo o sugerencia, con asunto y descripción). La **prórroga exige el enlace del soporte de pago**. El compañero solo consulta las PQRS del proyecto. El **coordinador** aprueba, aplaza o rechaza con respuesta (obligatoria al aplazar o rechazar); si aprueba un **cambio de director**, elige al nuevo director (docente activo, distinto del evaluador) y el sistema lo aplica al proyecto y avisa al nuevo director, al evaluador y al estudiante. El administrador consulta. Tabla con búsqueda, filtros por tipo y estado, tarjetas de resumen, paginación y ventanas de detalle y de gestión.
- **Notificaciones** (RF-57): listado de avisos internos con filtro "solo sin leer", marcar uno o todos como leídos y acceso al proyecto; la campana muestra el contador. Solo se pueden marcar los avisos propios.
- **Historial de versiones** (RF-58, RF-59): línea de tiempo por proyecto (entregas con su enlace, revisiones, decisiones, cambios de fase, asignaciones, PQRS) con filtro por tipo de evento y paginación; solo lectura. Coordinador y administrador ven todos los proyectos, el docente los suyos y el estudiante el propio.
- **Informe de estado** (RF-60, RF-62), **solo para el coordinador**: proyecto, fase, estado, director, evaluador y último movimiento, con filtros por texto, fase, estado, director y evaluador. Se puede **imprimir** (estilos de impresión que dejan solo el título y la tabla; permite guardar como PDF) (la exportación a Excel se quitó después por decisión de la estudiante).
- No hay informe de estado para el estudiante (decisión de la estudiante); se quitó de las descripciones.

**Pantallas:** `pqrs/pqrs.jsp` (el detalle y la gestión son ventanas modales), `pqrs/pqrs_form.jsp`, `notificaciones/notificaciones.jsp`, `historial/historial.jsp`, `informes/informe_coordinador.jsp`, `informes/informe_excel.jsp`. **Procesos:** `pqrs_proc.jsp`, `notificacion_proc.jsp`. **Fragmento:** `informe_filtros.jsp`.
**Requerimientos:** RF-53 a RF-60 y RF-62 (RF-61, informe del estudiante, descartado). **Historias:** HU-33 a HU-38.

**Problemas resueltos**
- La exportación fallaba con error 500 por el atributo `trimDirectiveWhitespaces` de la página; se probaron variantes con una sola diferencia cada una hasta aislarlo y se quitó.

**Pruebas hechas en el despliegue (peticiones HTTP):** compañero que intenta radicar; radicar con tipo inválido, asunto corto, prórroga sin soporte y soporte inválido; prórroga, cambio de director y queja válidos; visibilidad de PQRS por rol (responsable, compañero, otro estudiante, coordinador, administrador, docente sin acceso); resolver con y sin respuesta, resolver dos veces, cambio de director sin nuevo director, con el evaluador y con un docente válido (se aplica al proyecto); estudiante y docente que intentan resolver; avisos; notificaciones (marcar una, marcar todas, intentar marcar un aviso ajeno); historial por rol (estudiante propio, compañero, administrador, coordinador, otro estudiante y docente ajeno denegados); informe y sus filtros (incluidos filtros inválidos); exportación a Excel.

### Ajuste de PQRS (23/10/2026)
- En PQRS ya **no existe el estado "Aplazado"**: el coordinador solo **aprueba o rechaza** (la respuesta es obligatoria al rechazar). Motivo: en PQRS no hay flujo de corrección y reenvío, así que "aplazar" dejaba la solicitud sin salida. El valor sigue existiendo en la base (se usa en ideas, propuestas y documentos). Esto difiere de HU-34 del PDF ("aprueba, aplaza o rechaza").
- El estado vacío del listado distingue entre "Aún no hay PQRS radicadas" y "No hay PQRS que coincidan" con la búsqueda o los filtros.

### Panel de control (23/10/2026)
Reemplaza la pantalla "Informes de estado" (solo coordinador, `modulos/informes/informe_coordinador.jsp`), con dos pestañas:
- **Resumen:** 4 tarjetas y 5 gráficos con Chart.js (CDN, `js/graficos.js`): proyectos por fase, por estado, carga de docentes como director y evaluador, PQRS por tipo y estado, y actividad de los últimos 30 días. Los datos salen de consultas JSTL y se pasan al navegador en atributos `data-*`; el backend sigue siendo solo JSP + JSTL.
- **Proyectos:** tabla de estado con filtros por búsqueda, fase, estado, director y evaluador.
- **Decisión de la estudiante:** se quitó la exportación a Excel y no se implementa la pestaña de auditoría (sobrecargaba la pantalla); el historial por proyecto sigue disponible.
- Se actualizó `DISENO.md` (Chart.js autorizado solo en el Resumen).
- Problema resuelto: las barras invertidas en una expresión regular dentro de un atributo JSP rompían la compilación.

### Ajuste de PQRS: cambio de director (23/10/2026)
- Al gestionar una PQRS de cambio de director, la lista "Nuevo director" excluye al director actual y al evaluador del proyecto (además de la validación que ya existía en el servidor).

### Ajuste del rol Administrador (23/10/2026)
- El administrador ya **no tiene** Propuestas Banco, PQRS ni Historial de versiones (menú y acceso bloqueado en servidor): son tareas del coordinador y de los demás roles. Queda con Usuarios, Solicitudes de cuenta, Base documental y Mi perfil.
- Su inicio tiene tres tarjetas (Usuarios, Solicitudes de cuenta y Base documental) con avisos dentro: cuentas por aprobar (o "Al día") y enlaces sin configurar.

### Ajustes de Mi perfil (23/10/2026)
- El **tipo de documento** queda bloqueado junto con el número y el correo (solo el administrador los cambia desde Usuarios); el aviso es distinto para el administrador.
- Se quitó el campo "Rol" repetido (el rol sigue bajo el nombre), se aclaró el ejemplo de la foto y "Cambiar contraseña" pasó debajo de los datos, en una fila, con las reglas (8 a 64 caracteres).
- Nuevo diseño en dos columnas: a la izquierda una tarjeta de identidad solo de lectura (foto, nombre, rol, documento, correo y nivel, con aviso de bloqueo); a la derecha, "Datos personales" (nombre y foto) y "Cambiar contraseña".
- El documento del administrador inicial pasó de `0000000000` a `1000000000` (dato de prueba).

### Ajustes del formulario de usuarios (23/10/2026)
- Campos de formulario con fondo blanco y borde más marcado en todo el sistema (antes se confundían con los bloqueados).
- Nuevo/editar usuario: asteriscos en los obligatorios, ejemplos en nombre, documento y correo, explicación de cada rol que cambia al elegirlo y reglas de la contraseña.

### Ajustes del inicio del estudiante (23/10/2026)
- Se agregó PQRS al menú y una tarjeta de PQRS; se quitó la tarjeta "Mi perfil" (ya está en el menú); las cuatro tarjetas van en una fila.
- El panel "Tu proyecto" muestra una barra de seis pasos y "Fase X de 6"; con el proyecto terminado el título es "Listo para sustentación" (sin repetirlo en la etiqueta).
- El aviso de notificaciones sin leer pasó arriba, para todos los roles.

### Ajustes del banco de ideas (23/10/2026)
- Si el estudiante ya tiene una propuesta activa, desaparecen los botones "Elegir idea" (antes quedaban deshabilitados) y el aviso es informativo, con enlace a "Ver mi propuesta".
- La paginación se oculta cuando todas las ideas caben en una página.
- Se corrigió el texto de prueba de la idea ID-0004.

### Ajustes de Mis propuestas / Propuestas Banco (23/10/2026)
- Encabezado "Propuesta" (estudiante) o "Título" en lugar de "Descripción".
- Las propuestas aprobadas muestran bajo el estado la fase actual del proyecto ("Fase 4 · Informe I", "Listo para sustentación" o "Proyecto cerrado").
- Cuando hay compañero, la columna de integrantes indica quién es el responsable y quién el compañero.
- Los íconos de acciones tienen texto flotante; se quitó el botón PQRS de la pantalla del estudiante (está en el menú).

### Ajuste del detalle de propuesta (23/10/2026)
- La ventana de detalle muestra el estado como etiqueta de color, "Fecha de registro", la fase actual del proyecto y los integrantes con responsable y compañero.
- La observación del coordinador solo aparece si existe, destacada en amarillo (aplazada) o rojo (rechazada).
- Tiene pie con "Cerrar" y, si ya es proyecto, "Ver seguimiento".

### Ajustes del seguimiento terminado (23/10/2026)
- Con el proyecto listo para sustentación se quitó el aviso verde repetido; la fase 6 muestra un resumen (director, evaluador, fases aprobadas con su fecha y acceso al historial) y el mensaje se dirige al estudiante en segunda persona.
- La leyenda de colores solo aparece mientras haya fases pendientes.

### Mejoras del seguimiento (23/10/2026)
- Revisiones en orden cronológico (director, evaluador, comité), "Sin observaciones" en gris y la columna de documento solo cuando hay varios documentos (si no, "Versión").
- Columna "Subido por"; adjuntos indican "Adjunto del director/evaluador"; el comentario de los documentos copiados dice "Aprobado en la fase anterior" (el texto guardado no cambió).
- Fase aplazada o rechazada: la observación completa se muestra en un cuadro amarillo o rojo con su autor, y la etiqueta ya no la corta.
- Fase en revisión: línea "Falta la decisión de: ..." (coordinador, director, evaluador o comité según la fase).
- Mensaje de "sin documentos" según quién mira; "Detalles del proyecto" muestra la fase con su nombre y "Sin asignar" en todo el sistema.

### Retoques del seguimiento (23/10/2026)
- El subtítulo muestra el código y el título del proyecto; los botones superiores son más pequeños.
- Una fase aprobada sin documentos dice "Fase aprobada sin documentos registrados" (antes decía que esperaba el primer documento).
- Los datos de prueba incluyen un comprobante de pago aprobado en la Fase 1 de PG-0001.

### Detalles del proyecto (23/10/2026)
- En el seguimiento se quitaron los botones de historial y PQRS de la cabecera; el historial se abre desde "Detalles del proyecto".
- La ventana de detalles muestra el estado como etiqueta, "N de 6 fases aprobadas" con barra, el rol de quien mira (responsable, compañero, director o evaluador), estudiantes con responsable y compañero, director y evaluador con su correo institucional, fecha de inicio, último movimiento y, plegable, descripción, objetivo y alcance.

### Se quita la pantalla de Historial de versiones (23/10/2026)
- Decisión de la estudiante: se eliminó la pantalla `modulos/historial/historial.jsp` y todos sus accesos (tablas del coordinador y de los docentes, panel de control, seguimiento y detalles del proyecto). La tabla `historial_version` se conserva: sigue registrando los eventos (RNF-13) y alimenta el panel de control (último movimiento y actividad).
- Las versiones de los documentos siguen visibles en el seguimiento de cada fase (versión vigente y anteriores, con sus revisiones).

### Ajustes de la lista de PQRS (23/10/2026)
- Estados en femenino ("Aprobada", "Rechazada") en la tabla y el filtro.
- Para el estudiante: columnas Tipo y Fecha en lugar de Solicitante, sin tarjetas de resumen, sin paginación cuando hay 5 solicitudes o menos y una nota bajo el estado ("Sin respuesta aún" o "Respondida el ...").

### Detalle de PQRS (23/10/2026)
- La ventana muestra arriba el estado (etiqueta) y la respuesta con el color de la decisión, quién respondió y cuándo; si no hay respuesta, un aviso. El soporte es un enlace "Abrir soporte"; "Nuevo director" solo aparece en cambios de director; el solicitante se oculta al estudiante; se agregó el botón "Cerrar".

### Inicio del estudiante: tren de fases (23/10/2026)
- La barra de rayas se reemplazó por un tren de seis fases en miniatura (mismo diseño del seguimiento, con el nombre de cada fase); se quitó el botón PQRS y la etiqueta repetida del panel, el aviso de notificaciones pasó debajo del panel del proyecto y el saludo cambia según el momento (todo aprobado o fase aplazada).

### Notificaciones en la campana (23/10/2026)
- Decisión de la estudiante: las notificaciones se ven solo en un menú de la campana (ya no hay pantalla propia). Muestra los últimos 20 avisos con icono por categoría, lo no leído resaltado con un punto verde, y "Marcar todas como leídas".
- Al hacer clic en un aviso se marca como leído y se abre el módulo correcto (PQRS, propuestas, banco de ideas o seguimiento del proyecto). Se eliminó `modulos/notificaciones/notificaciones.jsp` y el aviso repetido del inicio.

### Secciones en la campana (23/10/2026)
- El menú de notificaciones separa "Nuevas" (resaltadas, arriba) de "Anteriores" (leídas, en gris y más compactas). Los avisos leídos no se borran; los más antiguos salen solos porque solo se muestran los últimos 20.

### Base documental con enlaces reales (23/10/2026)
- Se cargaron los seis enlaces (calendario académico y reglamentos de la UTS; formatos, propuesta F-DC-124 e informe F-DC-125 en Dropbox). El calendario académico ya aparece como tarjeta en el inicio.
- Para quien no administra, las tarjetas sin enlace dicen "Aún no disponible" y, si no hay ninguno, un aviso; las que tienen enlace muestran "Abrir". El enlace de cada tarjeta ahora se escapa con `c:out`.
- Los enlaces de Dropbox (con clave de acceso compartida) no están en `datos_iniciales.sql` para no publicarlos en el repositorio; se cargan desde "Administrar enlaces".

### Propuestas Banco del coordinador (23/10/2026)
- Las solicitudes pendientes salen primero; las tarjetas de resumen son filtros (clic para ver solo pendientes, aprobadas, aplazadas o rechazadas).
- Bajo cada título se indica la relación entre ideas y propuestas ("Propuesta desde la idea ID-0001", "Idea de docente · Elegida en PG-0001").
- El autor muestra al responsable en la primera línea y al compañero debajo; los iconos de acciones quedan alineados; el lápiz de lo ya decidido sale apagado con texto flotante "Ya decidida".

### Asignación de proyectos (23/10/2026)
- Los proyectos sin director o sin evaluador salen primero; las tarjetas de resumen filtran la tabla ("Completos" pasó a "Con director y evaluador").
- La fase usa el mismo lenguaje del resto del sistema (en curso, "Listo para sustentación", "Proyecto cerrado"); el lápiz de un proyecto terminado o cerrado sale apagado con texto flotante que explica por qué; "Buscar estudiante" pasó a "Consultar estudiante".

### Se quita "Buscar estudiante" (23/10/2026)
- Decisión de la estudiante: se eliminó la pantalla `proyectos/buscar_estudiante.jsp` y su botón en Asignación de proyectos. La consulta por estudiante (RF-36) se resuelve con el buscador de Asignación de proyectos (nombre o documento del estudiante, código, título, director o evaluador) y el de Propuestas Banco (nombre del estudiante).

### Búsqueda por documento en Propuestas Banco (23/10/2026)
- El coordinador puede buscar propuestas por el número de documento de los estudiantes, además de por código, título y nombre.

### Lista de PQRS del coordinador (23/10/2026)
- Las solicitudes pendientes salen primero; las tarjetas de resumen filtran la tabla; el tipo tiene su propia columna; bajo "Aprobada/Rechazada" se muestra la fecha de resolución y el lápiz de lo ya resuelto explica por qué está apagado. Subtítulo más corto.

### Ventana de asignación (23/10/2026)
- El docente elegido como director ya no se ofrece como evaluador (y al revés); cada docente muestra cuántos proyectos en curso dirige y evalúa; si el proyecto ya pasó de la Fase 1, un aviso explica que lo ya revisado queda a nombre de quien lo hizo y lo pendiente lo revisa la nueva persona (así funciona: los permisos de calificar dependen de la asignación vigente).

### Retoques del Panel de control (23/10/2026)
- El último movimiento ya muestra "PQRS resuelta" y demás acciones con su nombre (antes salía el código, como "RESOLVER").
- La actividad muestra los 30 días completos (con ceros), las barras son menos gruesas y la pestaña Proyectos junta director y evaluador en una columna "Docentes" y evita partir la etiqueta de estado.

### Ventanas de PQRS del coordinador (23/10/2026)
- En el detalle, "Nuevo director" solo aparece cuando ya existe. En "Resolver": se muestra el proyecto (código y título), el soporte como enlace solo si hay, el director actual y el evaluador del proyecto en los cambios de director, y cada docente de la lista con su carga ("dirige 1, evalúa 0").

### Impresión del Panel de control (23/10/2026)
- Los gráficos se imprimían desbordados y encimados porque el lienzo conserva su tamaño de pantalla; ahora, al imprimir, cada gráfico se reemplaza por una imagen ajustada a su tarjeta y se restaura al terminar.

### Panel de control: descarga en PDF (23/10/2026)
- El botón "Imprimir" del Panel de control se reemplazó por **Descargar PDF**: genera en el navegador (librería html2pdf.js por CDN) un PDF horizontal de la pestaña que se está viendo, con título y fecha, sin controles ni filtros. Motivo: la impresión del navegador desbordaba los gráficos.
- No se envía nada al servidor; el backend sigue siendo solo JSP + JSTL.
- Ajuste: la primera versión sacaba los gráficos fuera de sus tarjetas (la librería reacomoda el contenido al ancho de la hoja y los gráficos conservaban su tamaño de pantalla). Ahora el área se fija a un ancho de 1000 px mientras se genera el PDF y los gráficos se redibujan a ese ancho.

### Se quitan Imprimir y Descargar PDF (23/10/2026)
- Decisión de la estudiante: el sistema no ofrece imprimir ni exportar informes. Se eliminó el botón del Panel de control, la librería `html2pdf.js`, `js/pdf.js`, el reemplazo de gráficos por imágenes y los estilos de impresión del panel (los gráficos desbordaban al imprimir y al generar el PDF).

### Etiqueta de tipo en Propuestas Banco (23/10/2026)
- Bajo el código aparece una etiqueta "Idea" (lima) o "Propuesta" (verde) para coordinador y docente, para distinguir a simple vista las ideas de docentes (ID-) de las propuestas de estudiantes (PG-).

### Módulos Docente Director y Evaluador (23/10/2026)
- Las tarjetas de fase con proyectos van en verde y las vacías en gris; columnas "Código" y "Proyecto" (título y estudiantes) en lugar de "ID" y "Descripción"; la situación dice "Esperando el documento" o "En revisión de otros" en vez de "En espera"; el lápiz de calificar solo está activo cuando hay un documento por calificar y, si no, sale apagado con texto flotante.

### Tablero de fases en Docente Director y Evaluador (23/10/2026)
- La línea de tiempo se reemplazó por seis tarjetas con el número de proyectos en grande (verde si hay proyectos, gris si no); cada una filtra la tabla por esa fase y la elegida lleva un marco. Se reacomodan a 3 y 2 por fila en pantallas pequeñas.

### Detalle de la idea en el banco (23/10/2026)
- La ventana muestra la etiqueta "Aprobada · disponible", dice "Propuesta por" y tiene pie con "Cerrar" y, para el estudiante sin propuesta activa, el botón "Elegir esta idea" con su confirmación.

### Pantallas públicas (23/10/2026)
- Inicio de sesión: "Mantener sesión activa" ya no viene marcada por defecto y se indican los dominios de correo de cada tipo de usuario.
- Registro: asteriscos en los campos obligatorios, ejemplos en nombre, documento y correo, nota sobre el dominio y las reglas de la contraseña, y aviso del uso de los datos personales (Ley 1581 de 2012).

### Formulario de entrega del estudiante (23/10/2026)
- Cuando el responsable puede entregar y aún no hay documentos, se muestra solo el formulario con el título "Entrega: Comprobante de pago" (en vez del cuadro "Aún no hay documentos" y el formulario aparte); la etiqueta es "Enlace al documento", el comentario dice "Comentario (opcional)" en la primera entrega y "¿Qué cambió?" solo al enviar una nueva versión, y se explica qué pasa después de enviar.

### Pantalla de calificar (23/10/2026)
- En la Fase 1 la pantalla se llama "Validar pago" y dice "Validas el pago como coordinador" (en las demás fases sigue "Calificar documento"); bajo los botones se explica qué hace Aprobar, Aplazar y Rechazar; el cuadro de observaciones trae un ejemplo.

### Confirmación de rechazo al calificar (23/10/2026)
- Al rechazar un documento, la confirmación dice la consecuencia real: "¿Rechazar y cerrar el proyecto PG-xxxx? Los estudiantes no podrán continuar. Esta decisión es extrema y queda registrada." En cuentas, ideas, propuestas y PQRS se mantiene el mensaje general.

### Calificar: ayudas del evaluador y del director (23/10/2026)
- En las fases 3 y 5, "Aprobar" dice quién más falta por decidir; la ayuda de la rejilla es una sola línea; el cuadro de observaciones trae un ejemplo corto; en la tabla de revisiones, lo vacío dice "Sin observaciones".

### Botón de decidir en Propuestas Banco (23/10/2026)
- El lápiz del coordinador se reemplazó por un botón verde con el icono de decisión ("Aprobar, aplazar o rechazar"), que solo aparece en lo pendiente; en lo ya decidido no se muestra ningún botón apagado.

### Hora de Colombia (23/10/2026)
- Las horas se veían 5 horas adelantadas porque MySQL en Clever Cloud trabaja en UTC. La conexión (`conexion.jsp`) ahora fija la sesión en `-05:00` (`sessionVariables=time_zone='-05:00'`), y las fechas ya guardadas se corrigieron restándoles 5 horas (solo eran datos de prueba). Las sesiones recordadas se borraron.
- Nota para el despliegue: si se instala en otro servidor, la base seguirá guardando en su propia zona, pero la conexión de la aplicación la fija en hora de Colombia.

### Calificar: director en la Fase 5 (23/10/2026)
- Si el Turnitin (director) o la rejilla (evaluador) ya están adjuntos para esa versión, ya no se muestra la caja vacía sino una nota; la ayuda del botón usa su mismo nombre ("Aprobar envío: envía el documento a revisión del evaluador y del comité"); "versión aprobada en la Fase X"; el aviso de decisión ya registrada es informativo.

### Fase aplazada: textos (23/10/2026)
- El cuadro de la observación muestra la fecha y, para quien no es el estudiante, "Esperando que (responsable) envíe una nueva versión", además de avisar que con la nueva versión se vuelve a revisar. Al comité, en la Fase 5, la ayuda de "Aprobar" le dice que el proyecto queda listo para sustentación.

### Inicio del estudiante: código del proyecto y calendario (23/10/2026)
- El panel "Tu proyecto" muestra el código y el título (por ejemplo "PG-0005 · Idea de prueba"). La tarjeta "Calendario académico" ya no sale en el inicio del estudiante (la tiene en la Base documental), así que quedan cuatro tarjetas en una fila; los demás roles la conservan (RF-18).

### Color de los textos de ejemplo (23/10/2026)
- Los ejemplos dentro de los campos (placeholder) ahora van en gris claro en todo el sistema, para que no se confundan con datos ya escritos.

### Separación de los mensajes (23/10/2026)
- Los mensajes de éxito, error o aviso quedaban pegados al botón "Volver"; ahora llevan más separación arriba y abajo en todas las pantallas.

### Formulario de radicar PQRS (23/10/2026)
- El menú resalta "PQRS" (antes seguía marcando "Mis propuestas"); cada tipo de solicitud se explica al elegirlo; asteriscos en los obligatorios (el soporte lo lleva solo en la prórroga), ejemplos y notas de longitud mínima; el subtítulo dice que la respuesta se ve en la lista de PQRS.

### Solicitudes de cuenta (23/10/2026)
- El lápiz se reemplazó por el botón verde de decisión con texto flotante; el detalle muestra el estado y tiene "Cerrar"; la ventana de gestionar explica el nivel, qué hace Aprobar y Rechazar (y que el estudiante no ve la observación), trae un ejemplo en la observación y una confirmación de rechazo específica para cuentas.

### Estudiante nuevo, sin proyecto (23/10/2026)
- El inicio de un estudiante sin proyecto muestra un cuadro de primeros pasos (sin propuesta: botones al banco y a proponer una idea propia; con propuesta pendiente o aplazada: su estado y un botón a "Mis propuestas") en lugar del aviso de revisiones del director, y un saludo que lo orienta.
- Formulario de nueva propuesta: asteriscos en los obligatorios, ejemplos en título, objetivo y alcance, aviso de una propuesta activa por estudiante y de que solo el responsable entrega los documentos.

### Propuesta pendiente del estudiante (23/10/2026)
- En "Mis propuestas", una propuesta pendiente muestra el botón "Agregar a tu compañero" (icono de persona) solo si todavía no lo tiene, y la aplazada el botón verde "Corregir y reenviar"; el detalle de una propuesta pendiente avisa que el coordinador la está revisando; la pantalla de edición se llama "Agregar compañero" (o "Corregir propuesta" si fue aplazada) y no marca con asterisco los campos que están bloqueados.

### Acciones en Mis propuestas (23/10/2026)
- En la tabla del estudiante ya no se reserva el hueco del icono de seguimiento (dejaba una separación grande entre el ojo y el botón de agregar compañero); coordinador y docente lo conservan para alinear sus botones.

### Acciones de Propuestas Banco sin huecos (23/10/2026)
- Se quitó el icono de seguimiento de la tabla (queda en el pie de la ventana de detalle) y los espacios reservados. Cada fila lleva, si corresponde, un botón con texto a la izquierda ("Decidir" para el coordinador; "Corregir" o "Agregar compañero" para el estudiante) y el ojo siempre al final, así las acciones quedan pegadas al borde derecho sin huecos.

### Acciones de Propuestas Banco: todas visibles (23/10/2026)
- Por decisión de la estudiante, cada fila lleva siempre los mismos botones en el mismo orden (ver detalle, seguimiento y, para coordinador y estudiante, decidir o corregir); los que no aplican quedan apagados con un texto flotante que explica por qué ("Ya decidida", "Aún no es un proyecto: no hay seguimiento").

### Acciones de Propuestas Banco con menú (23/10/2026)
- Cada fila lleva siempre dos botones: el ojo y un menú de tres puntos con lo que se puede hacer en ese momento (ver seguimiento, aprobar/aplazar/rechazar, corregir y reenviar o agregar compañero); si no hay nada, dice "Sin acciones disponibles". Sin huecos y sin botones apagados.

### Menú de tres puntos en todas las tablas con acciones (23/10/2026)
- Propuestas Banco, PQRS, Asignación de proyectos, Director y Evaluador, Usuarios y Solicitudes de cuenta usan ahora el mismo patrón: el ojo (o el acceso al seguimiento) y un menú de tres puntos con lo que se puede hacer en esa fila; lo que no aplica se explica dentro del menú en lugar de dejar botones apagados o huecos. El Panel de control (pestaña Proyectos) y la administración de enlaces tienen una sola acción por fila y se dejaron como estaban.

### Pruebas finales y README (23/10/2026)
- Recorrido con los cuatro roles en el despliegue: todas las pantallas de cada rol cargan sin error; las pantallas de otros roles responden "Acceso denegado"; sin sesión se vuelve al ingreso; los procesos rechazan peticiones sin token anti-CSRF o por GET; un estudiante no puede ver el seguimiento de un proyecto ajeno.
- README actualizado (qué hace cada rol, instalación, variables de entorno, hora de Colombia, base documental, usuarios de prueba y seguridad). Los PDF de formatos institucionales se agregaron al `.gitignore`.

---

## Diferencias entre el sistema construido y el documento del sistema (PDF)
Resumen para actualizar la documentación final. Lo que no aparece aquí se implementó como dice el PDF.

| Tema | Lo que dice el PDF | Lo que quedó en el sistema | Motivo |
|---|---|---|---|
| Tecnología | Tomcat y JSTL, desplegable en Render o Clever Cloud | Tomcat 9, JSTL 1.2, Java 21 en Clever Cloud; el WAR se genera con `jar` en un hook de pre-build (sin Maven) | Compatible con el XAMPP local (javax) |
| Base de datos | `gestion_grado` | `gestion_proyectos_grado` (en Clever Cloud la base la nombra la plataforma); script sin `CREATE DATABASE` | Nombre pedido por la estudiante |
| Carpetas | `webapp/assets/css`, `js`, `img` | `webapp/css`, `webapp/js`, `webapp/img` | Indicado en `CLAUDE.md` y `DISENO.md` |
| Datos de prueba | Solo `datos_iniciales.sql` | Además `sql/datos_prueba.sql` (un usuario por rol, ideas, propuesta y proyecto) | Poder recorrer el sistema |
| Correos | Dominio institucional | Estudiantes `@uts.edu.co`; docentes, coordinador y administrador `@correo.uts.edu.co` | Definido por la estudiante |
| Menú del estudiante | "Propuesta Banco" | "Mis propuestas" (los demás roles ven "Propuestas Banco") | Más claro para el estudiante |
| Ventanas | `propuesta_detalle.jsp`, `propuesta_decision.jsp`, `pqrs_detalle.jsp`, `detalles_proyecto.jsp` como páginas | Ventanas modales dentro de cada pantalla | `DISENO.md` |
| Propuesta propia | Título, objetivo y alcance obligatorios | Además descripción opcional (si se omite se copia el título) | La tabla exige descripción |
| Propuestas por estudiante | No se limita | Una propuesta activa (pendiente, aplazada o aprobada); si se rechaza puede crear otra | "Estudiante libre" (RF-26) |
| Compañero | Segundo estudiante opcional | Una vez agregado queda **fijo**; debe tener cuenta aprobada; **solo visualiza** | Definido por la estudiante |
| Responsable | `es_responsable` marca a quien creó la propuesta | Solo el responsable entrega documentos, corrige la propuesta y radica PQRS; si se inactiva, el proyecto no recibe documentos | Definido por la estudiante |
| Máximo de estudiantes | Uno y un compañero | Igual (2). El formato F-DC-124 admite 3; el F-DC-125 trae 2 autores | Decisión pendiente si se quiere 3 |
| Fases 3 y 5 | El director envía al evaluador y al comité | El sistema copia el documento aprobado de la fase anterior; el director aprueba el envío; luego deciden evaluador y comité (ambos) | Interpretación del PDF |
| Fase 6 | Revisión final por evaluador y comité, con informe final | **Estado final automático**: se alcanza al aprobar la fase 5; sin entrega ni revisión | Definido por la estudiante |
| Estado final | Apto para graduación | Se muestra **"Listo para sustentación"** (el valor interno sigue siendo `APTO_GRADUACION`) | La etapa siguiente es la sustentación |
| Nombres de documentos | Genéricos | "Anteproyecto (F-DC-124)" e "Informe (F-DC-125)" según los formatos institucionales | Claridad para el estudiante |
| Rejilla de evaluación | Documento de las fases de revisión | Enlace del evaluador, **obligatorio para aprobar** en la fase 3 (F-DC-124) y en la fase 5 (F-DC-129), una vez por versión | Formatos institucionales |
| Turnitin | Documento de la fase 5 | Enlace del director, **obligatorio en cualquier decisión** de la fase 5, una vez por versión; no se verifica el porcentaje | Evidencia |
| Decisión del director | No se detalla | Queda cerrada cuando el evaluador o el comité ya decidieron sobre la versión (fases 3 y 5) | Evitar decisiones contradictorias |
| Informe de estado | Para el coordinador y para el estudiante (RF-60, RF-61, HU-39) | **Solo para el coordinador**; no hay informe del estudiante | Definido por la estudiante |
| Módulos del administrador | El administrador consulta propuestas, PQRS e historial | Solo gestiona usuarios, cuentas y enlaces de la base documental | Definido por la estudiante |
| Historial de versiones | Pantalla de historial con línea de tiempo por proyecto (RF-58, RF-59) | **No existe como pantalla**: las versiones y revisiones se ven en el seguimiento de cada fase; la tabla `historial_version` sigue registrando los eventos | Definido por la estudiante |
| Notificaciones | Campana con contador y listado de avisos | Campana con contador y menú desplegable con los últimos 20 avisos; sin pantalla de listado | Definido por la estudiante |
| Consulta por estudiante | Pantalla para buscar el proyecto o anteproyecto de un estudiante (RF-36) | Sin pantalla propia: se busca por nombre o documento en Asignación de proyectos y por nombre en Propuestas Banco | Evitar una pantalla repetida |
| Pantalla de informes | Informe de estado por proyecto | **Panel de control**: resumen con gráficos e informe de proyectos (solo coordinador) | Definido por la estudiante |
| Exportar el informe | CSV o imprimir (RF-62, deseable) | **No se implementa**: el sistema no tiene botones de imprimir, descargar ni exportar | Definido por la estudiante |
| PQRS | Aprobar, aplazar o rechazar (HU-34) | Solo **aprobar o rechazar**; el cambio de director aprobado se aplica al proyecto | En PQRS no hay reenvío |
| Seguimiento por fila | Opción en cada fila (RF-33) | Ícono de seguimiento en Propuestas Banco y en las tablas de proyectos; historial desde seguimiento y tablas | Navegación |
| Notificaciones | Campana con contador | Además listado con filtro "solo sin leer", marcar una o todas | RF-57 |
