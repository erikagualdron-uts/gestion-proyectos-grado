<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Mi perfil (RF-13 a RF-16): todos los roles. Documento, correo y rol se ven pero no se editan. --%>
<c:set var="titulo" value="Mi perfil" scope="request" />
<sql:query var="consulta" dataSource="${bd}">
  SELECT u.tipo_documento, u.numero_documento, u.nombre_completo, u.correo, u.nivel, u.foto_url, r.nombre AS rol
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol WHERE u.id_usuario = ?
  <sql:param value="${sessionScope.usuarioId}" />
</sql:query>
<c:set var="perfil" value="${consulta.rows[0]}" />
<c:set var="vNombre" value="${not empty sessionScope.vpNombre ? sessionScope.vpNombre : perfil.nombre_completo}" />
<c:set var="vTipo" value="${not empty sessionScope.vpTipo ? sessionScope.vpTipo : perfil.tipo_documento}" />
<c:set var="vFoto" value="${sessionScope.vpFoto != null ? sessionScope.vpFoto : perfil.foto_url}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Mi perfil</h1>
<p class="descripcion-pagina">Revisa y actualiza tus datos personales.</p>

<div class="row g-4">
  <div class="col-12 col-xl-8">
    <div class="tarjeta">
      <form method="post" action="${ctx}/proceso/perfil_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">

        <div class="d-flex align-items-center gap-3 mb-4">
          <c:choose>
            <c:when test="${not empty perfil.foto_url}"><img class="foto-perfil" src="<c:out value='${perfil.foto_url}' />" alt="Tu foto de perfil" referrerpolicy="no-referrer"></c:when>
            <c:otherwise><span class="foto-defecto" aria-hidden="true"><c:out value="${sessionScope.iniciales}" /></span></c:otherwise>
          </c:choose>
          <div>
            <div class="fw-bold fs-5 titulo"><c:out value="${perfil.nombre_completo}" /></div>
            <div class="texto-sec"><c:out value="${fn:substring(perfil.rol, 0, 1)}" /><c:out value="${fn:toLowerCase(fn:substring(perfil.rol, 1, 40))}" /><c:if test="${perfil.rol == 'ESTUDIANTE' and not empty perfil.nivel}"> · Nivel <c:out value="${perfil.nivel == 'TECNOLOGICO' ? 'Tecnológico' : 'Profesional'}" /></c:if></div>
          </div>
        </div>

        <div class="mb-3">
          <label for="nombre" class="form-label">Nombre completo</label>
          <input type="text" class="form-control" id="nombre" name="nombre" maxlength="120" minlength="5" value="<c:out value='${vNombre}' />" required>
          <div class="invalid-feedback">Ingresa tu nombre completo.</div>
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
            <input type="text" class="form-control campo-bloqueado" id="documento" value="<c:out value='${perfil.numero_documento}' />" readonly aria-describedby="ayudaBloqueado">
          </div>
        </div>
        <div class="mb-3">
          <label for="correo" class="form-label">Correo institucional</label>
          <input type="email" class="form-control campo-bloqueado" id="correo" value="<c:out value='${perfil.correo}' />" readonly aria-describedby="ayudaBloqueado">
          <div class="form-text" id="ayudaBloqueado">El documento y el correo están bloqueados. Si necesitas cambiarlos, solicítalo al administrador.</div>
        </div>
        <div class="row g-3 mb-3">
          <div class="col-sm-6">
            <label for="rol" class="form-label">Rol</label>
            <input type="text" class="form-control campo-bloqueado" id="rol" value="${fn:substring(perfil.rol, 0, 1)}${fn:toLowerCase(fn:substring(perfil.rol, 1, 40))}" readonly>
          </div>
          <c:if test="${perfil.rol == 'ESTUDIANTE'}">
            <div class="col-sm-6">
              <label for="nivel" class="form-label">Nivel</label>
              <input type="text" class="form-control campo-bloqueado" id="nivel" value="${perfil.nivel == 'TECNOLOGICO' ? 'Tecnológico' : (perfil.nivel == 'PROFESIONAL' ? 'Profesional' : 'Sin asignar')}" readonly>
            </div>
          </c:if>
        </div>
        <div class="mb-4">
          <label for="foto" class="form-label">Foto de perfil (enlace a la imagen)</label>
          <input type="url" class="form-control" id="foto" name="foto" maxlength="300" placeholder="https://..." value="<c:out value='${vFoto}' />">
          <div class="form-text">Pega el enlace de una imagen. Si lo dejas vacío se muestra la imagen por defecto.</div>
          <div class="invalid-feedback">Ingresa un enlace válido que empiece por http:// o https://.</div>
        </div>

        <div class="d-flex flex-wrap gap-2">
          <button type="submit" name="accion" value="guardar" class="btn btn-uts px-4"><i class="bi bi-check-lg me-1"></i>Guardar</button>
          <c:if test="${not empty perfil.foto_url}">
            <button type="submit" name="accion" value="quitar_foto" class="btn btn-outline-uts" formnovalidate><i class="bi bi-trash me-1"></i>Eliminar foto</button>
          </c:if>
        </div>
      </form>
    </div>
  </div>

  <div class="col-12 col-xl-4">
    <div class="tarjeta">
      <h2 class="h5 titulo mb-3" style="color: var(--verde-bosque)">Cambiar contraseña</h2>
      <form method="post" action="${ctx}/proceso/perfil_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="accion" value="clave">
        <div class="mb-3">
          <label for="claveActual" class="form-label">Contraseña actual</label>
          <div class="campo-clave">
            <input type="password" class="form-control" id="claveActual" name="claveActual" maxlength="64" autocomplete="current-password" required>
            <button type="button" class="ver-clave" data-target="claveActual" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
            <div class="invalid-feedback">Ingresa tu contraseña actual.</div>
          </div>
        </div>
        <div class="mb-3">
          <label for="clave" class="form-label">Nueva contraseña</label>
          <div class="campo-clave">
            <input type="password" class="form-control" id="clave" name="clave" minlength="8" maxlength="64" autocomplete="new-password" required>
            <button type="button" class="ver-clave" data-target="clave" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
            <div class="invalid-feedback">Mínimo 8 caracteres.</div>
          </div>
        </div>
        <div class="mb-4">
          <label for="confirmar" class="form-label">Confirmar nueva contraseña</label>
          <div class="campo-clave">
            <input type="password" class="form-control" id="confirmar" name="confirmar" maxlength="64" autocomplete="new-password" required>
            <button type="button" class="ver-clave" data-target="confirmar" aria-label="Mostrar contraseña"><i class="bi bi-eye"></i></button>
            <div class="invalid-feedback">Las contraseñas no coinciden.</div>
          </div>
        </div>
        <button type="submit" class="btn btn-uts w-100">Cambiar contraseña</button>
      </form>
    </div>
  </div>
</div>

<c:remove var="vpNombre" scope="session" />
<c:remove var="vpTipo" scope="session" />
<c:remove var="vpFoto" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />
