<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="soloPost" value="true" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Perfil propio (RF-14, RF-15, RF-16): guardar nombre, tipo de documento y foto; quitar foto; cambiar contraseña.
     El documento y el correo no se reciben aquí: solo los cambia el administrador. --%>
<c:set var="accion" value="${param.accion}" />
<c:set var="nombreIngresado" value="${fn:trim(param.nombre)}" />
<c:set var="fotoIngresada" value="${fn:trim(param.foto)}" />

<c:if test="${accion != 'guardar' and accion != 'quitar_foto' and accion != 'clave'}">
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="Solicitud no válida." scope="session" />
  <c:redirect url="/modulos/perfil/perfil.jsp" />
</c:if>

<%-- ===== Quitar foto ===== --%>
<c:if test="${accion == 'quitar_foto'}">
  <c:catch var="falloPerfil">
    <sql:transaction dataSource="${bd}">
      <sql:update>
        UPDATE usuario SET foto_url = NULL WHERE id_usuario = ?
        <sql:param value="${sessionScope.usuarioId}" />
      </sql:update>
      <sql:update>
        INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, detalle)
        VALUES (?, 'USUARIO', ?, 'EDITAR_PERFIL', 'Foto de perfil eliminada')
        <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
      </sql:update>
    </sql:transaction>
  </c:catch>
  <c:set var="flashTipo" value="${empty falloPerfil ? 'success' : 'danger'}" scope="session" />
  <c:set var="flashMsg" value="${empty falloPerfil ? 'Foto eliminada. Se muestra la imagen por defecto.' : 'No se pudo eliminar la foto.'}" scope="session" />
  <c:redirect url="/modulos/perfil/perfil.jsp" />
</c:if>

<%-- ===== Cambiar contraseña ===== --%>
<c:if test="${accion == 'clave'}">
  <sql:query var="claveActual" dataSource="${bd}">
    SELECT COUNT(*) AS total FROM usuario WHERE id_usuario = ? AND contrasena_hash = SHA2(CONCAT(sal, ?), 256)
    <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${param.claveActual}" />
  </sql:query>
  <c:choose>
    <c:when test="${claveActual.rows[0].total != 1}">
      <c:set var="errorPerfil" value="La contraseña actual no es correcta." />
    </c:when>
    <c:when test="${fn:length(param.clave) < 8 or fn:length(param.clave) > 64}">
      <c:set var="errorPerfil" value="La nueva contraseña debe tener entre 8 y 64 caracteres." />
    </c:when>
    <c:when test="${param.clave != param.confirmar}">
      <c:set var="errorPerfil" value="Las contraseñas nuevas no coinciden." />
    </c:when>
  </c:choose>
  <c:if test="${empty errorPerfil}">
    <sql:query var="salNueva" dataSource="${bd}">SELECT LOWER(HEX(RANDOM_BYTES(16))) AS sal</sql:query>
    <c:set var="sal" value="${salNueva.rows[0].sal}" />
    <c:catch var="falloPerfil">
      <sql:transaction dataSource="${bd}">
        <sql:update>
          UPDATE usuario SET sal = ?, contrasena_hash = SHA2(CONCAT(?, ?), 256) WHERE id_usuario = ?
          <sql:param value="${sal}" /><sql:param value="${sal}" /><sql:param value="${param.clave}" /><sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
        <sql:update>
          DELETE FROM sesion_persistente WHERE id_usuario = ?
          <sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
        <sql:update>
          INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, detalle)
          VALUES (?, 'USUARIO', ?, 'CAMBIAR_CLAVE', 'Contraseña actualizada por el propio usuario')
          <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
        </sql:update>
      </sql:transaction>
    </c:catch>
    <c:if test="${not empty falloPerfil}"><c:set var="errorPerfil" value="No se pudo cambiar la contraseña. Inténtalo de nuevo." /></c:if>
  </c:if>
  <c:set var="flashTipo" value="${empty errorPerfil ? 'success' : 'danger'}" scope="session" />
  <c:set var="flashMsg" value="${empty errorPerfil ? 'Contraseña actualizada. Si tenías la sesión recordada en otros equipos, deberás ingresar de nuevo allí.' : errorPerfil}" scope="session" />
  <c:redirect url="/modulos/perfil/perfil.jsp" />
</c:if>

<%-- ===== Guardar datos personales ===== --%>
<c:choose>
  <c:when test="${fn:length(nombreIngresado) < 5 or fn:length(nombreIngresado) > 120 or not fn:contains(nombreIngresado, ' ')}">
    <c:set var="errorPerfil" value="Ingresa tu nombre completo (nombre y apellido)." />
  </c:when>
  <c:when test="${not fn:contains(',CC,TI,CE,PASAPORTE,OTRO,', ',' += param.tipo += ',')}">
    <c:set var="errorPerfil" value="Selecciona un tipo de documento válido." />
  </c:when>
  <c:when test="${not empty fotoIngresada and (fn:length(fotoIngresada) > 300 or fn:contains(fotoIngresada, ' ') or not (fn:startsWith(fotoIngresada, 'https://') or fn:startsWith(fotoIngresada, 'http://')))}">
    <c:set var="errorPerfil" value="El enlace de la foto debe empezar por http:// o https:// y tener máximo 300 caracteres." />
  </c:when>
</c:choose>
<c:if test="${not empty errorPerfil}">
  <c:set var="vpNombre" value="${nombreIngresado}" scope="session" />
  <c:set var="vpTipo" value="${param.tipo}" scope="session" />
  <c:set var="vpFoto" value="${fotoIngresada}" scope="session" />
  <c:set var="flashTipo" value="danger" scope="session" />
  <c:set var="flashMsg" value="${errorPerfil}" scope="session" />
  <c:redirect url="/modulos/perfil/perfil.jsp" />
</c:if>

<c:catch var="falloPerfil">
  <sql:transaction dataSource="${bd}">
    <sql:update>
      UPDATE usuario SET nombre_completo = ?, tipo_documento = ?, foto_url = NULLIF(?, '') WHERE id_usuario = ?
      <sql:param value="${nombreIngresado}" /><sql:param value="${param.tipo}" />
      <sql:param value="${fotoIngresada}" /><sql:param value="${sessionScope.usuarioId}" />
    </sql:update>
    <sql:update>
      INSERT INTO historial_version (id_usuario, entidad, id_entidad, accion, detalle)
      VALUES (?, 'USUARIO', ?, 'EDITAR_PERFIL', 'Perfil actualizado por el propio usuario')
      <sql:param value="${sessionScope.usuarioId}" /><sql:param value="${sessionScope.usuarioId}" />
    </sql:update>
  </sql:transaction>
</c:catch>
<c:set var="flashTipo" value="${empty falloPerfil ? 'success' : 'danger'}" scope="session" />
<c:set var="flashMsg" value="${empty falloPerfil ? 'Cambios guardados correctamente.' : 'No se pudieron guardar los cambios.'}" scope="session" />
<c:redirect url="/modulos/perfil/perfil.jsp" />
