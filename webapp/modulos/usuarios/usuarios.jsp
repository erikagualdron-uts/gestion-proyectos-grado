<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ADMINISTRADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Usuarios (RF-09, RF-10): tarjetas de resumen, búsqueda, filtros por rol y estado, tabla paginada. --%>
<c:set var="titulo" value="Usuarios" scope="request" />

<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="filtroRol" value="${fn:contains(',ADMINISTRADOR,COORDINADOR,DOCENTE,ESTUDIANTE,', ',' += param.rol += ',') ? param.rol : ''}" />
<c:set var="filtroEstado" value="${fn:contains(',PENDIENTE,APROBADA,RECHAZADA,INACTIVO,', ',' += param.estado += ',') ? param.estado : ''}" />
<c:set var="pp" value="${param.pp == '10' ? 10 : (param.pp == '20' ? 20 : 5)}" />
<c:catch var="pagInvalida"><c:set var="pagPedida" value="${empty param.pag ? 1 : param.pag + 0}" /></c:catch>
<c:if test="${not empty pagInvalida or pagPedida < 1}"><c:set var="pagPedida" value="1" /></c:if>
<c:set var="qLike" value="%${q}%" />

<sql:query var="resumen" dataSource="${bd}">
  SELECT SUM(estado_cuenta = 'PENDIENTE' AND activo = 1) AS pendientes,
         SUM(estado_cuenta = 'APROBADA' AND activo = 1) AS aprobadas,
         SUM(estado_cuenta = 'RECHAZADA') AS rechazadas,
         SUM(activo = 0) AS inactivas
  FROM usuario
</sql:query>

<sql:query var="conteo" dataSource="${bd}">
  SELECT COUNT(*) AS total
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE (? = '' OR u.nombre_completo LIKE ? OR u.correo LIKE ? OR u.numero_documento LIKE ?)
    AND (? = '' OR r.nombre = ?)
    AND (? = '' OR (? = 'INACTIVO' AND u.activo = 0) OR (? <> 'INACTIVO' AND u.estado_cuenta = ? AND u.activo = 1))
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroRol}" /><sql:param value="${filtroRol}" />
  <sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
</sql:query>
<c:set var="totalRegistros" value="${conteo.rows[0].total}" />
<c:set var="totalPaginas" value="${fn:substringBefore(((totalRegistros + pp - 1) - ((totalRegistros + pp - 1) mod pp)) div pp, '.')}" />
<c:set var="totalPaginas" value="${totalPaginas < 1 ? 1 : totalPaginas}" />
<c:set var="pagActual" value="${pagPedida > totalPaginas ? totalPaginas : pagPedida}" />

<sql:query var="usuarios" dataSource="${bd}">
  SELECT u.id_usuario, u.nombre_completo, u.tipo_documento, u.numero_documento, u.correo, u.nivel,
         u.estado_cuenta, IF(u.activo = 1, 'SI', 'NO') AS habilitado, r.nombre AS rol,
         DATE_FORMAT(u.fecha_registro, '%d/%m/%Y') AS registro
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
  WHERE (? = '' OR u.nombre_completo LIKE ? OR u.correo LIKE ? OR u.numero_documento LIKE ?)
    AND (? = '' OR r.nombre = ?)
    AND (? = '' OR (? = 'INACTIVO' AND u.activo = 0) OR (? <> 'INACTIVO' AND u.estado_cuenta = ? AND u.activo = 1))
  ORDER BY u.fecha_registro DESC, u.id_usuario DESC
  LIMIT ? OFFSET ?
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroRol}" /><sql:param value="${filtroRol}" />
  <sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
  <sql:param value="${pp}" /><sql:param value="${(pagActual - 1) * pp}" />
</sql:query>

<c:url var="pagBase" value="/modulos/usuarios/usuarios.jsp">
  <c:param name="q" value="${q}" />
  <c:param name="rol" value="${filtroRol}" />
  <c:param name="estado" value="${filtroEstado}" />
</c:url>
<c:set var="pagPorPagina" value="${pp}" scope="request" />
<c:set var="pagActual" value="${pagActual}" scope="request" />
<c:set var="pagTotalPaginas" value="${totalPaginas}" scope="request" />
<c:set var="pagBase" value="${pagBase}" scope="request" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<div class="d-flex flex-wrap align-items-end justify-content-between gap-3">
  <div>
    <h1 class="titulo-pagina">Usuarios</h1>
    <p class="descripcion-pagina mb-3">Consulta, edita e inactiva usuarios del sistema.</p>
  </div>
  <a class="btn btn-uts mb-3" href="${ctx}/modulos/usuarios/usuario_form.jsp"><i class="bi bi-plus-lg me-1"></i>Nuevo usuario</a>
</div>

<div class="row g-3 mb-4">
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono pendiente"><i class="bi bi-clock"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].pendientes}" default="0" /></div><div class="resumen-etiqueta">Pendientes</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aprobado"><i class="bi bi-check-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].aprobadas}" default="0" /></div><div class="resumen-etiqueta">Activas</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono aplazado"><i class="bi bi-pause-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].inactivas}" default="0" /></div><div class="resumen-etiqueta">Inactivas</div></div></div></div>
  <div class="col-6 col-xl-3"><div class="tarjeta resumen"><span class="resumen-icono rechazado"><i class="bi bi-x-circle"></i></span><div><div class="resumen-numero"><c:out value="${resumen.rows[0].rechazadas}" default="0" /></div><div class="resumen-etiqueta">Rechazadas</div></div></div></div>
</div>

<form method="get" action="${ctx}/modulos/usuarios/usuarios.jsp" class="row g-3 align-items-end mb-3">
  <input type="hidden" name="pp" value="${pp}">
  <input type="hidden" name="pag" value="1">
  <div class="col-12 col-md">
    <label for="q" class="form-label">Buscar</label>
    <input type="search" class="form-control" id="q" name="q" value="<c:out value='${q}' />" placeholder="Nombre, correo o documento" maxlength="120">
  </div>
  <div class="col-6 col-md-auto">
    <label for="rol" class="form-label">Rol</label>
    <select class="form-select" id="rol" name="rol" data-autoenviar>
      <option value="">Todos</option>
      <option value="ADMINISTRADOR" ${filtroRol == 'ADMINISTRADOR' ? 'selected' : ''}>Administrador</option>
      <option value="COORDINADOR" ${filtroRol == 'COORDINADOR' ? 'selected' : ''}>Coordinador</option>
      <option value="DOCENTE" ${filtroRol == 'DOCENTE' ? 'selected' : ''}>Docente</option>
      <option value="ESTUDIANTE" ${filtroRol == 'ESTUDIANTE' ? 'selected' : ''}>Estudiante</option>
    </select>
  </div>
  <div class="col-6 col-md-auto">
    <label for="estado" class="form-label">Estado</label>
    <select class="form-select" id="estado" name="estado" data-autoenviar>
      <option value="">Todos</option>
      <option value="APROBADA" ${filtroEstado == 'APROBADA' ? 'selected' : ''}>Activa</option>
      <option value="PENDIENTE" ${filtroEstado == 'PENDIENTE' ? 'selected' : ''}>Pendiente</option>
      <option value="RECHAZADA" ${filtroEstado == 'RECHAZADA' ? 'selected' : ''}>Rechazada</option>
      <option value="INACTIVO" ${filtroEstado == 'INACTIVO' ? 'selected' : ''}>Inactiva</option>
    </select>
  </div>
  <div class="col-12 col-md-auto"><button type="submit" class="btn btn-uts w-100"><i class="bi bi-search me-1"></i>Buscar</button></div>
</form>

<c:choose>
  <c:when test="${usuarios.rowCount == 0}">
    <div class="vacio">
      <span class="icono-circulo"><i class="bi bi-people"></i></span>
      <h3>No hay usuarios para mostrar</h3>
      <p>Cambia la búsqueda o los filtros, o registra un usuario nuevo.</p>
    </div>
  </c:when>
  <c:otherwise>
    <div class="tabla-envoltorio table-responsive">
      <table class="table tabla-uts">
        <thead>
          <tr><th>Nombre</th><th>Correo</th><th>Rol</th><th>Estado</th><th class="text-end">Acciones</th></tr>
        </thead>
        <tbody>
          <c:forEach var="u" items="${usuarios.rows}">
            <tr>
              <td><div class="fw-semibold"><c:out value="${u.nombre_completo}" /></div><div class="texto-sec"><c:out value="${u.tipo_documento}" /> <c:out value="${u.numero_documento}" /></div></td>
              <td><c:out value="${u.correo}" /></td>
              <td><c:out value="${fn:substring(u.rol, 0, 1)}" /><c:out value="${fn:toLowerCase(fn:substring(u.rol, 1, 40))}" /></td>
              <td>
                <c:choose>
                  <c:when test="${u.habilitado == 'NO'}"><c:set var="estadoTexto" value="Inactiva" /><span class="insignia insignia-aplazado">Inactiva</span></c:when>
                  <c:when test="${u.estado_cuenta == 'APROBADA'}"><c:set var="estadoTexto" value="Activa" /><span class="insignia insignia-aprobado">Activa</span></c:when>
                  <c:when test="${u.estado_cuenta == 'RECHAZADA'}"><c:set var="estadoTexto" value="Rechazada" /><span class="insignia insignia-rechazado">Rechazada</span></c:when>
                  <c:otherwise><c:set var="estadoTexto" value="Pendiente" /><span class="insignia insignia-pendiente">Pendiente</span></c:otherwise>
                </c:choose>
              </td>
              <td class="acciones">
                <button type="button" class="btn btn-outline-uts btn-icono" data-bs-toggle="modal" data-bs-target="#modalUsuario" aria-label="Visualizar a ${fn:escapeXml(u.nombre_completo)}"
                        data-nombre="${fn:escapeXml(u.nombre_completo)}" data-documento="${fn:escapeXml(u.tipo_documento)} ${fn:escapeXml(u.numero_documento)}"
                        data-correo="${fn:escapeXml(u.correo)}" data-rol="${fn:escapeXml(fn:substring(u.rol, 0, 1))}${fn:escapeXml(fn:toLowerCase(fn:substring(u.rol, 1, 40)))}"
                        data-nivel="${u.nivel == 'TECNOLOGICO' ? 'Tecnológico' : (u.nivel == 'PROFESIONAL' ? 'Profesional' : '')}"
                        data-estado="${estadoTexto}" data-registro="${u.registro}"><i class="bi bi-eye"></i></button>
                <a class="btn btn-outline-uts btn-icono" href="${ctx}/modulos/usuarios/usuario_form.jsp?id=${u.id_usuario}" aria-label="Gestionar a ${fn:escapeXml(u.nombre_completo)}"><i class="bi bi-pencil"></i></a>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
    <jsp:include page="/WEB-INF/includes/paginacion.jsp" />
  </c:otherwise>
</c:choose>

<div class="modal fade" id="modalUsuario" tabindex="-1" aria-labelledby="tituloModalUsuario" aria-hidden="true">
  <div class="modal-dialog modal-dialog-centered">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h2 class="modal-title fs-5" id="tituloModalUsuario">Detalle del usuario</h2>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="dato-etiqueta">Nombre completo</div><div class="dato-valor" data-llenar="nombre"></div>
        <div class="dato-etiqueta">Documento</div><div class="dato-valor" data-llenar="documento"></div>
        <div class="dato-etiqueta">Correo institucional</div><div class="dato-valor" data-llenar="correo"></div>
        <div class="row">
          <div class="col-6"><div class="dato-etiqueta">Rol</div><div class="dato-valor" data-llenar="rol"></div></div>
          <div class="col-6"><div class="dato-etiqueta">Nivel</div><div class="dato-valor" data-llenar="nivel"></div></div>
          <div class="col-6"><div class="dato-etiqueta">Estado</div><div class="dato-valor" data-llenar="estado"></div></div>
          <div class="col-6"><div class="dato-etiqueta">Registro</div><div class="dato-valor" data-llenar="registro"></div></div>
        </div>
      </div>
    </div>
  </div>
</div>

<jsp:include page="/WEB-INF/includes/pie.jsp" />
