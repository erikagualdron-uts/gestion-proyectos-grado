<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Solicitudes de cuenta de estudiantes (RF-04, RF-12): aprobar asignando nivel o rechazar con observación. --%>
<c:set var="titulo" value="Solicitudes de cuenta" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>
<c:set var="qLike" value="%${q}%" />

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE' AND u.activo = 1
    AND (? = '' OR u.nombre_completo LIKE ? OR u.correo LIKE ? OR u.numero_documento LIKE ?)
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="pendientes" dataSource="${bd}">
  SELECT u.id_usuario, u.nombre_completo, u.tipo_documento, u.numero_documento, u.correo,
         DATE_FORMAT(u.fecha_registro, '%d/%m/%Y %H:%i') AS registro
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE r.nombre = 'ESTUDIANTE' AND u.estado_cuenta = 'PENDIENTE' AND u.activo = 1
    AND (? = '' OR u.nombre_completo LIKE ? OR u.correo LIKE ? OR u.numero_documento LIKE ?)
  ORDER BY u.fecha_registro ASC, u.id_usuario ASC
  LIMIT ? OFFSET ?
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:url var="pagBase" value="/modulos/usuarios/cuentas_pendientes.jsp"><c:param name="q" value="${q}" /></c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina">Solicitudes de cuenta</h1>
<p class="descripcion-pagina">Aprueba o rechaza las cuentas de estudiantes. Al aprobar debes asignar el nivel.</p>

<div class="row g-3 mb-4">
  <div class="col-12 col-md-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-clock"></i></span><div><div class="resumen-numero"><c:out value="${totalRegistros}" /></div><div class="resumen-etiqueta">Por revisar</div></div></div></div>
</div>

<form method="get" action="${ctx}/modulos/usuarios/cuentas_pendientes.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Nombre, correo o documento" maxlength="120">
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${pendientes.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-person-check"></i></span>
      <h3>No hay solicitudes pendientes</h3>
      <p>Cuando un estudiante cree su cuenta, aparecerá aquí para que la apruebes.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead>
          <tr><th>Estudiante</th><th>Correo</th><th>Solicitud</th><th>Estado</th><th class="text-end">Acciones</th></tr>
        </thead>
        <tbody>
          <c:forEach var="s" items="${pendientes.rows}">
            <tr>
              <td><div class="fw-semibold"><c:out value="${s.nombre_completo}" /></div><div class="texto-sec"><c:out value="${s.tipo_documento}" /> <c:out value="${s.numero_documento}" /></div></td>
              <td><c:out value="${s.correo}" /></td>
              <td><c:out value="${s.registro}" /></td>
              <td><span class="insignia insignia-pendiente">Pendiente</span></td>
              <td class="acciones">
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalVerCuenta" aria-label="Visualizar la solicitud de ${fn:escapeXml(s.nombre_completo)}"
                        data-nombre="${fn:escapeXml(s.nombre_completo)}" data-documento="${fn:escapeXml(s.tipo_documento)} ${fn:escapeXml(s.numero_documento)}"
                        data-correo="${fn:escapeXml(s.correo)}" data-registro="${s.registro}"><i class="bi bi-eye"></i></button>
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalGestionarCuenta" aria-label="Gestionar la solicitud de ${fn:escapeXml(s.nombre_completo)}"
                        data-id="${s.id_usuario}" data-nombre="${fn:escapeXml(s.nombre_completo)}" data-correo="${fn:escapeXml(s.correo)}"><i class="bi bi-pencil"></i></button>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalVerCuenta" tabindex="-1" aria-labelledby="tituloVerCuenta" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloVerCuenta">Solicitud de cuenta</h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="dato-etiqueta">Nombre completo</div><div class="dato-valor" data-llenar="nombre"></div>
        <div class="dato-etiqueta">Documento</div><div class="dato-valor" data-llenar="documento"></div>
        <div class="dato-etiqueta">Correo institucional</div><div class="dato-valor" data-llenar="correo"></div>
        <div class="dato-etiqueta">Fecha de solicitud</div><div class="dato-valor" data-llenar="registro"></div>
      </div>
    </div>
  </div>
</div>

<div class="modal fade" id="modalGestionarCuenta" tabindex="-1" aria-labelledby="tituloGestionarCuenta" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <form method="post" action="${ctx}/proceso/cuenta_decision_proc.jsp" data-decisiones novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="id" value="" data-llenar-valor="id">
        <div class="modal-header border-0">
          <h2 class="modal-title fs-5" id="tituloGestionarCuenta">Gestionar solicitud</h2>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
        </div>
        <div class="modal-body pt-0">
          <div class="dato-etiqueta">Estudiante</div><div class="dato-valor" data-llenar="nombre"></div>
          <div class="dato-etiqueta">Correo institucional</div><div class="dato-valor" data-llenar="correo"></div>
          <div class="mb-3">
            <label for="nivel" class="form-label">Nivel (obligatorio para aprobar)</label>
            <select class="form-select" id="nivel" name="nivel">
              <option value="">Selecciona el nivel</option>
              <option value="TECNOLOGICO">Tecnológico</option>
              <option value="PROFESIONAL">Profesional</option>
            </select>
            <div class="invalid-feedback">Selecciona el nivel del estudiante.</div>
          </div>
          <div class="mb-1">
            <label for="observacion" class="form-label">Observación (obligatoria para rechazar)</label>
            <textarea class="form-control" id="observacion" name="observacion" rows="3" maxlength="400"></textarea>
            <div class="invalid-feedback">Escribe el motivo del rechazo.</div>
          </div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <button type="submit" name="decision" value="RECHAZAR" class="btn btn-rechazar"><i class="bi bi-x-circle me-1"></i>Rechazar</button>
          <button type="submit" name="decision" value="APROBAR" class="btn btn-uts"><i class="bi bi-check-circle me-1"></i>Aprobar</button>
        </div>
      </form>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />
