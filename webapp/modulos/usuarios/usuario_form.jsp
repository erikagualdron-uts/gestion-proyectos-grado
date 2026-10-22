<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Crear o editar un usuario (RF-08, RF-10, RF-11). Sin id: crea personal (administrador, coordinador, docente).
     Con id: edita, incluidos el documento y el correo, e inactiva o reactiva. --%>
<c:set var="menuActivo" value="/modulos/usuarios/usuarios.jsp" scope="request" />
<c:set var="volverA" value="/modulos/usuarios/usuarios.jsp" scope="request" />

<c:if test="${not empty param.id}">
  <c:catch var="idInvalido"><c:set var="idEditar" value="${param.id + 0}" /></c:catch>
  <c:if test="${not empty idInvalido}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="El usuario indicado no es válido." scope="session" />
    <c:redirect url="/modulos/usuarios/usuarios.jsp" />
  </c:if>
  <sql:query var="consulta" dataSource="${bd}">
    SELECT u.id_usuario, u.tipo_documento, u.numero_documento, u.nombre_completo, u.correo, u.nivel,
           u.estado_cuenta, IF(u.activo = 1, 'SI', 'NO') AS habilitado, r.nombre AS rol
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE u.id_usuario = ?
    <sql:param value="${idEditar}" />
  </sql:query>
  <c:if test="${consulta.rowCount != 1}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="El usuario no existe." scope="session" />
    <c:redirect url="/modulos/usuarios/usuarios.jsp" />
  </c:if>
  <c:set var="usuario" value="${consulta.rows[0]}" />
</c:if>

<c:set var="editando" value="${not empty usuario}" />
<c:set var="esEstudiante" value="${editando and usuario.rol == 'ESTUDIANTE'}" />
<c:set var="titulo" value="${editando ? 'Editar usuario' : 'Nuevo usuario'}" scope="request" />
<c:set var="vNombre" value="${not empty sessionScope.vfNombre ? sessionScope.vfNombre : (editando ? usuario.nombre_completo : '')}" />
<c:set var="vTipo" value="${not empty sessionScope.vfTipo ? sessionScope.vfTipo : (editando ? usuario.tipo_documento : 'CC')}" />
<c:set var="vDocumento" value="${not empty sessionScope.vfDocumento ? sessionScope.vfDocumento : (editando ? usuario.numero_documento : '')}" />
<c:set var="vCorreo" value="${not empty sessionScope.vfCorreo ? sessionScope.vfCorreo : (editando ? usuario.correo : '')}" />
<c:set var="vRol" value="${not empty sessionScope.vfRol ? sessionScope.vfRol : (editando ? usuario.rol : 'DOCENTE')}" />
<c:set var="vNivel" value="${not empty sessionScope.vfNivel ? sessionScope.vfNivel : (editando ? usuario.nivel : '')}" />
<c:set var="soyYo" value="${editando and usuario.id_usuario == sessionScope.usuarioId}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina"><c:out value="${titulo}" /></h1>
<p class="descripcion-pagina">
  <c:choose>
    <c:when test="${editando}">Modifica los datos del usuario. El documento y el correo solo los cambia el administrador.</c:when>
    <c:otherwise>Registra a un administrador, coordinador o docente. Los estudiantes crean su propia cuenta.</c:otherwise>
  </c:choose>
</p>

<div class="row">
  <div class="col-12 col-xl-8">
    <div class="tarjeta">
      <c:if test="${editando}">
        <div class="d-flex flex-wrap align-items-center gap-2 mb-3">
          <c:choose>
            <c:when test="${usuario.habilitado == 'NO'}"><span class="insignia insignia-aplazado">Inactiva</span></c:when>
            <c:when test="${usuario.estado_cuenta == 'APROBADA'}"><span class="insignia insignia-aprobado">Activa</span></c:when>
            <c:when test="${usuario.estado_cuenta == 'RECHAZADA'}"><span class="insignia insignia-rechazado">Rechazada</span></c:when>
            <c:otherwise><span class="insignia insignia-pendiente">Pendiente</span></c:otherwise>
          </c:choose>
          <span class="texto-sec"><c:out value="${fn:substring(usuario.rol, 0, 1)}" /><c:out value="${fn:toLowerCase(fn:substring(usuario.rol, 1, 40))}" /></span>
        </div>
      </c:if>

      <form method="post" action="${ctx}/proceso/usuario_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="accion" value="${editando ? 'editar' : 'crear'}">
        <c:if test="${editando}"><input type="hidden" name="id" value="${usuario.id_usuario}"></c:if>

        <div class="mb-3">
          <label for="nombre" class="form-label">Nombre completo</label>
          <input type="text" class="form-control" id="nombre" name="nombre" maxlength="120" minlength="5" value="<c:out value='${vNombre}' />" required>
          <div class="invalid-feedback">Ingresa el nombre completo.</div>
        </div>
        <div class="row g-3 mb-3">
          <div class="col-sm-5">
            <label for="tipo" class="form-label">Tipo de documento</label>
            <select class="form-select" id="tipo" name="tipo" required>
              <c:forEach var="t" items="${fn:split('CC,TI,CE,PASAPORTE,OTRO', ',')}">
                <option value="${t}" ${vTipo == t ? 'selected' : ''}>${t}</option>
              </c:forEach>
            </select>
          </div>
          <div class="col-sm-7">
            <label for="documento" class="form-label">Número de documento</label>
            <input type="text" class="form-control" id="documento" name="documento" pattern="[0-9A-Za-z]{5,20}" maxlength="20" value="<c:out value='${vDocumento}' />" required>
            <div class="invalid-feedback">Entre 5 y 20 letras o números, sin espacios.</div>
          </div>
        </div>
        <div class="mb-3">
          <label for="correo" class="form-label">Correo institucional</label>
          <input type="email" class="form-control" id="correo" name="correo" maxlength="120"
                 placeholder="${esEstudiante ? 'usuario@uts.edu.co' : 'usuario@correo.uts.edu.co'}"
                 pattern="${esEstudiante ? '[A-Za-z0-9._%+\\-]+@uts\\.edu\\.co' : '[A-Za-z0-9._%+\\-]+@correo\\.uts\\.edu\\.co'}"
                 value="<c:out value='${vCorreo}' />" required>
          <div class="form-text">${esEstudiante ? 'Estudiantes: @uts.edu.co.' : 'Docentes, coordinadores y administradores: @correo.uts.edu.co.'}</div>
          <div class="invalid-feedback">Usa el correo institucional con el dominio indicado.</div>
        </div>

        <div class="row g-3 mb-3">
          <c:choose>
            <c:when test="${esEstudiante}">
              <div class="col-sm-6">
                <label class="form-label">Rol</label>
                <input type="text" class="form-control campo-bloqueado" value="Estudiante" readonly>
              </div>
              <c:if test="${usuario.estado_cuenta == 'APROBADA'}">
                <div class="col-sm-6">
                  <label for="nivel" class="form-label">Nivel</label>
                  <select class="form-select" id="nivel" name="nivel" required>
                    <option value="TECNOLOGICO" ${vNivel == 'TECNOLOGICO' ? 'selected' : ''}>Tecnológico</option>
                    <option value="PROFESIONAL" ${vNivel == 'PROFESIONAL' ? 'selected' : ''}>Profesional</option>
                  </select>
                </div>
              </c:if>
            </c:when>
            <c:otherwise>
              <div class="col-sm-6">
                <label for="rol" class="form-label">Rol</label>
                <select class="form-select" id="rol" name="rol" required ${soyYo ? 'disabled' : ''}>
                  <option value="ADMINISTRADOR" ${vRol == 'ADMINISTRADOR' ? 'selected' : ''}>Administrador</option>
                  <option value="COORDINADOR" ${vRol == 'COORDINADOR' ? 'selected' : ''}>Coordinador</option>
                  <option value="DOCENTE" ${vRol == 'DOCENTE' ? 'selected' : ''}>Docente</option>
                </select>
                <c:if test="${soyYo}"><input type="hidden" name="rol" value="${usuario.rol}"><div class="form-text">No puedes cambiar tu propio rol.</div></c:if>
              </div>
            </c:otherwise>
          </c:choose>
        </div>

        <div class="row g-3 mb-4">
          <div class="col-sm-6">
            <label for="clave" class="form-label">${editando ? 'Nueva contraseña (opcional)' : 'Contraseña inicial'}</label>
            <div class="campo-clave">
              <input type="password" class="form-control" id="clave" name="clave" minlength="8" maxlength="64" autocomplete="new-password" ${editando ? '' : 'required'}>
              <button type="button" class="ver-clave" data-target="clave" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
              <div class="invalid-feedback">Mínimo 8 caracteres.</div>
            </div>
            <c:if test="${editando}"><div class="form-text">Déjala vacía para no cambiarla.</div></c:if>
          </div>
          <div class="col-sm-6">
            <label for="confirmar" class="form-label">Confirmar contraseña</label>
            <div class="campo-clave">
              <input type="password" class="form-control" id="confirmar" name="confirmar" maxlength="64" autocomplete="new-password" ${editando ? '' : 'required'}>
              <button type="button" class="ver-clave" data-target="confirmar" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
              <div class="invalid-feedback">Las contraseñas no coinciden.</div>
            </div>
          </div>
        </div>

        <div class="d-flex flex-wrap gap-2">
          <button type="submit" class="btn btn-uts px-4"><i class="bi bi-check-lg me-1"></i>Guardar</button>
          <a class="btn btn-outline-uts px-4" href="${ctx}/modulos/usuarios/usuarios.jsp">Cancelar</a>
        </div>
      </form>

      <c:if test="${editando and not soyYo}">
        <hr class="my-4">
        <form method="post" action="${ctx}/proceso/usuario_proc.jsp" data-confirmar="${usuario.habilitado == 'SI' ? '¿Inactivar este usuario? No podrá ingresar, pero se conserva su historial.' : '¿Reactivar este usuario?'}">
          <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
          <input type="hidden" name="accion" value="${usuario.habilitado == 'SI' ? 'inactivar' : 'reactivar'}">
          <input type="hidden" name="id" value="${usuario.id_usuario}">
          <button type="submit" class="btn ${usuario.habilitado == 'SI' ? 'btn-rechazar' : 'btn-aprobar'}">
            <i class="bi ${usuario.habilitado == 'SI' ? 'bi-person-dash' : 'bi-person-check'} me-1"></i>${usuario.habilitado == 'SI' ? 'Inactivar usuario' : 'Reactivar usuario'}
          </button>
        </form>
      </c:if>
    </div>
  </div>
</div>

<c:remove var="vfNombre" scope="session" />
<c:remove var="vfTipo" scope="session" />
<c:remove var="vfDocumento" scope="session" />
<c:remove var="vfCorreo" scope="session" />
<c:remove var="vfRol" scope="session" />
<c:remove var="vfNivel" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />
