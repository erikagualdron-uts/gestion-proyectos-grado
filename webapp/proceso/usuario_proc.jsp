<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Crear, editar, inactivar y reactivar usuarios (RF-08, RF-10, RF-11). Todo queda en el historial (RNF-13). --%>
<c:set var="accion" value="${param.accion}" />
<c:catch var="idInvalido"><c:set var="idObj" value="${empty param.id ? 0 : param.id + 0}" /></c:catch>
<c:if test="${not empty idInvalido or (accion != 'crear' and accion != 'editar' and accion != 'inactivar' and accion != 'reactivar')}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Solicitud no válida." scope="session" />
  <c:redirect url="/modulos/usuarios/usuarios.jsp" />
</c:if>

<%-- Usuario sobre el que se actúa (editar, inactivar, reactivar) --%>
<c:if test="${accion != 'crear'}">
  <sql:query var="consulta" dataSource="${bd}">
    SELECT u.id_usuario, u.tipo_documento, u.numero_documento, u.nombre_completo, u.correo, u.nivel,
           u.estado_cuenta, u.activo + 0 AS activo_num, r.nombre AS rol
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE u.id_usuario = ?
    <sql:param value="${idObj}" />
  </sql:query>
  <c:if test="${consulta.rowCount != 1}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="El usuario no existe." scope="session" />
    <c:redirect url="/modulos/usuarios/usuarios.jsp" />
  </c:if>
  <c:set var="objetivo" value="${consulta.rows[0]}" />
  <sql:query var="otrosAdmins" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
    WHERE r.nombre = 'ADMINISTRADOR' AND u.estado_cuenta = 'APROBADA' AND u.activo = 1 AND u.id_usuario <> ?
    <sql:param value="${idObj}" />
  </sql:query>
</c:if>

<%-- ===== Inactivar / reactivar ===== --%>
<c:if test="${accion == 'inactivar' or accion == 'reactivar'}">
  <c:choose>
    <c:when test="${idObj == sessionScope.usuarioId}">
      <c:set var="errorUsuario" value="No puedes inactivar tu propia cuenta." />
    </c:when>
    <c:when test="${accion == 'inactivar' and objetivo.rol == 'ADMINISTRADOR' and otrosAdmins.rows[0].total < 1}">
      <c:set var="errorUsuario" value="Debe quedar al menos un administrador activo." />
    </c:when>
  </c:choose>
  <c:if test="${empty errorUsuario}">
    <c:set var="nuevoActivo" value="${accion == 'reactivar' ? 1 : 0}" />
    <c:catch var="falloEstado">
      <sql:transaction dataSource="${bd}">
        <sql:update>
          UPDATE usuario SET activo = ? WHERE id_usuario = ?
          <sql:param value="${nuevoActivo}" /><sql:param value="${idObj}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
          VALUES (?, 'USUARIO', ?, ?, ?, ?, ?)
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idObj}" />
          <sql:param value="${accion == 'inactivar' ? 'INACTIVAR' : 'REACTIVAR'}" />
          <sql:param value="${accion == 'inactivar' ? 'ACTIVO' : 'INACTIVO'}" />
          <sql:param value="${accion == 'inactivar' ? 'INACTIVO' : 'ACTIVO'}" />
          <sql:param value="${objetivo.nombre_completo}" />
        </sql:update>
        <c:if test="${accion == 'inactivar'}">
          <sql:update>
            DELETE FROM sesion_persistente WHERE id_usuario = ?
            <sql:param value="${idObj}" />
          </sql:update>
        </c:if>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloEstado}"><c:set var="errorUsuario" value="No se pudo cambiar el estado del usuario." /></c:if>
  </c:if>
  <c:set var="flashTipo" value="${empty errorUsuario ? 'success' : 'danger'}" scope="session" />
  <c:set var="flashMsg" value="${empty errorUsuario ? (accion == 'inactivar' ? 'Usuario inactivado. Su historial se conserva.' : 'Usuario reactivado.') : errorUsuario}" scope="session" />
  <c:redirect url="/modulos/usuarios/usuarios.jsp" />
</c:if>

<%-- ===== Crear / editar ===== --%>
<c:set var="nombreIngresado" value="${fn:trim(param.nombre)}" />
<c:set var="documentoIngresado" value="${fn:trim(param.documento)}" />
<c:set var="correoIngresado" value="${fn:toLowerCase(fn:trim(param.correo))}" />
<c:set var="esEstudiante" value="${accion == 'editar' and objetivo.rol == 'ESTUDIANTE'}" />
<c:set var="rolObjetivo" value="${esEstudiante ? 'ESTUDIANTE' : param.rol}" />
<c:set var="sufijoCorreo" value="${esEstudiante ? '@uts.edu.co' : '@correo.uts.edu.co'}" />
<c:set var="hayClave" value="${not empty param.clave}" />
<c:set var="exigeNivel" value="${esEstudiante and objetivo.estado_cuenta == 'APROBADA'}" />

<sql:query var="docValido" dataSource="${bd}">
  SELECT (? REGEXP '^[0-9A-Za-z]{5,20}$') AS ok
  <sql:param value="${documentoIngresado}" />
</sql:query>
<sql:query var="repetido" dataSource="${bd}">
  SELECT COUNT(*) AS total FROM usuario WHERE (correo = ? OR numero_documento = ?) AND id_usuario <> ?
  <sql:param value="${correoIngresado}" /><sql:param value="${documentoIngresado}" /><sql:param value="${idObj}" />
</sql:query>

<c:choose>
  <c:when test="${fn:length(nombreIngresado) < 5 or fn:length(nombreIngresado) > 120 or not fn:contains(nombreIngresado, ' ')}">
    <c:set var="errorUsuario" value="Ingresa el nombre completo (nombre y apellido)." />
  </c:when>
  <c:when test="${not fn:contains(',CC,TI,CE,PASAPORTE,OTRO,', ',' += param.tipo += ',')}">
    <c:set var="errorUsuario" value="Selecciona un tipo de documento válido." />
  </c:when>
  <c:when test="${docValido.rows[0].ok != 1}">
    <c:set var="errorUsuario" value="El número de documento debe tener entre 5 y 20 letras o números, sin espacios." />
  </c:when>
  <c:when test="${fn:length(correoIngresado) > 120 or fn:indexOf(correoIngresado, '@') < 1 or fn:length(fn:split(correoIngresado, '@')) != 2 or fn:contains(correoIngresado, ' ') or not fn:endsWith(correoIngresado, sufijoCorreo)}">
    <c:set var="errorUsuario" value="El correo debe ser institucional con el dominio ${sufijoCorreo}." />
  </c:when>
  <c:when test="${not fn:contains(',ADMINISTRADOR,COORDINADOR,DOCENTE,ESTUDIANTE,', ',' += rolObjetivo += ',') or (accion == 'crear' and rolObjetivo == 'ESTUDIANTE')}">
    <c:set var="errorUsuario" value="Selecciona un rol válido." />
  </c:when>
  <c:when test="${exigeNivel and param.nivel != 'TECNOLOGICO' and param.nivel != 'PROFESIONAL'}">
    <c:set var="errorUsuario" value="Selecciona el nivel del estudiante." />
  </c:when>
  <c:when test="${(accion == 'crear' or hayClave) and (fn:length(param.clave) < 8 or fn:length(param.clave) > 64)}">
    <c:set var="errorUsuario" value="La contraseña debe tener entre 8 y 64 caracteres." />
  </c:when>
  <c:when test="${(accion == 'crear' or hayClave) and param.clave != param.confirmar}">
    <c:set var="errorUsuario" value="Las contraseñas no coinciden." />
  </c:when>
  <c:when test="${repetido.rows[0].total > 0}">
    <c:set var="errorUsuario" value="Ya existe otro usuario con ese correo o número de documento." />
  </c:when>
  <c:when test="${accion == 'editar' and idObj == sessionScope.usuarioId and rolObjetivo != objetivo.rol}">
    <c:set var="errorUsuario" value="No puedes cambiar tu propio rol." />
  </c:when>
  <c:when test="${accion == 'editar' and objetivo.rol == 'ADMINISTRADOR' and rolObjetivo != 'ADMINISTRADOR' and otrosAdmins.rows[0].total < 1}">
    <c:set var="errorUsuario" value="Debe quedar al menos un administrador activo." />
  </c:when>
</c:choose>

<c:if test="${not empty errorUsuario}">
  <c:set var="vfNombre" value="${nombreIngresado}" scope="session" />
  <c:set var="vfTipo" value="${param.tipo}" scope="session" />
  <c:set var="vfDocumento" value="${documentoIngresado}" scope="session" />
  <c:set var="vfCorreo" value="${correoIngresado}" scope="session" />
  <c:set var="vfRol" value="${param.rol}" scope="session" />
  <c:set var="vfNivel" value="${param.nivel}" scope="session" />
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="${errorUsuario}" scope="session" />
  <c:choose>
    <c:when test="${accion == 'editar'}">
      <c:redirect url="/modulos/usuarios/usuario_form.jsp"><c:param name="id" value="${idObj}" /></c:redirect>
    </c:when>
    <c:otherwise><c:redirect url="/modulos/usuarios/usuario_form.jsp" /></c:otherwise>
  </c:choose>
</c:if>

<sql:query var="salNueva" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(16))) AS sal</sql:query>
<c:set var="sal" value="${salNueva.rows[0].sal}" />

<c:if test="${accion == 'crear'}">
  <c:catch var="falloGuardar">
    <sql:transaction dataSource="${bd}">
      <sql:update>
        INSERT INTO usuario (id_rol, tipo_documento, numero_documento, nombre_completo, correo, contrasena_hash, sal,
                             estado_cuenta, id_aprobador, fecha_decision)
        VALUES ((SELECT id_rol FROM rol WHERE nombre = ?), ?, ?, ?, ?, SHA2(CONCAT(?, ?), 256), ?, 'APROBADA', ?, NOW())
        <sql:param value="${rolObjetivo}" /><sql:param value="${param.tipo}" /><sql:param value="${documentoIngresado}" />
        <sql:param value="${nombreIngresado}" /><sql:param value="${correoIngresado}" />
        <sql:param value="${sal}" /><sql:param value="${param.clave}" /><sql:param value="${sal}" />
        <sql:param value="${sessionScope.usuarioId}" />
      </sql:update>
      <sql:query var="nuevo">SELECT LAST_INSERT_ID() AS id</sql:query>
      <sql:update>
        INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_nuevo, detalle)
        VALUES (?, 'USUARIO', ?, 'CREAR', 'APROBADA', ?)
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${nuevo.rows[0].id}" />
        <sql:param value="${'Usuario creado con rol ' += rolObjetivo}" />
      </sql:update>
    </sql:transaction>
  </c:catch>
  <c:set var="mensajeOk" value="Usuario creado: ${nombreIngresado}." />
</c:if>

<c:if test="${accion == 'editar'}">
  <c:set var="cambios" value="${(nombreIngresado != objetivo.nombre_completo ? 'nombre, ' : '') += (param.tipo != objetivo.tipo_documento ? 'tipo de documento, ' : '') += (documentoIngresado != objetivo.numero_documento ? 'número de documento, ' : '') += (correoIngresado != objetivo.correo ? 'correo, ' : '') += (rolObjetivo != objetivo.rol ? 'rol, ' : '') += (hayClave ? 'contraseña restablecida, ' : '')}" />
  <c:set var="nivelNuevo" value="${exigeNivel ? param.nivel : objetivo.nivel}" />
  <c:catch var="falloGuardar">
    <sql:transaction dataSource="${bd}">
      <sql:update>
        UPDATE usuario SET tipo_documento = ?, numero_documento = ?, nombre_completo = ?, correo = ?,
               id_rol = (SELECT id_rol FROM rol WHERE nombre = ?), nivel = ?
        WHERE id_usuario = ?
        <sql:param value="${param.tipo}" /><sql:param value="${documentoIngresado}" />
        <sql:param value="${nombreIngresado}" /><sql:param value="${correoIngresado}" />
        <sql:param value="${rolObjetivo}" /><sql:param value="${nivelNuevo}" /><sql:param value="${idObj}" />
      </sql:update>
      <c:if test="${hayClave}">
        <sql:update>
          UPDATE usuario SET sal = ?, contrasena_hash = SHA2(CONCAT(?, ?), 256) WHERE id_usuario = ?
          <sql:param value="${sal}" /><sql:param value="${sal}" /><sql:param value="${param.clave}" /><sql:param value="${idObj}" />
        </sql:update>
        <sql:update>
          DELETE FROM sesion_persistente WHERE id_usuario = ?
          <sql:param value="${idObj}" />
        </sql:update>
      </c:if>
      <sql:update>
        INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, estado_anterior, estado_nuevo, detalle)
        VALUES (?, 'USUARIO', ?, 'EDITAR', ?, ?, ?)
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${idObj}" />
        <sql:param value="${objetivo.estado_cuenta}" /><sql:param value="${objetivo.estado_cuenta}" />
        <sql:param value="${empty cambios ? 'Edición sin cambios en los datos' : ('Modificado: ' += fn:substring(cambios, 0, fn:length(cambios) - 2))}" />
      </sql:update>
    </sql:transaction>
  </c:catch>
  <c:set var="mensajeOk" value="Cambios guardados: ${nombreIngresado}." />
</c:if>

<c:choose>
  <c:when test="${not empty falloGuardar}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="No se pudo guardar el usuario. Verifica los datos e inténtalo de nuevo." scope="session" />
    <c:redirect url="/modulos/usuarios/usuarios.jsp" />
  </c:when>
  <c:otherwise>
    <c:set var="flashTipo" value="success" scope="session" />
    <c:set var="flashMsg" value="${mensajeOk}" scope="session" />
    <c:redirect url="/modulos/usuarios/usuarios.jsp" />
  </c:otherwise>
</c:choose>
