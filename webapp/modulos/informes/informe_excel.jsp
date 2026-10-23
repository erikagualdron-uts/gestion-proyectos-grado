<%@ page contentType="application/vnd.ms-excel; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/informe_filtros.jsp" %>
<%@ include file="/WEB-INF/includes/auditoria_filtros.jsp" %>
<%-- Exportación a Excel (RF-62) de la pestaña Proyectos o Auditoría: una tabla HTML con estilos que Excel abre con
     formato (encabezado verde, bordes y anchos de columna). Respeta los mismos filtros de la pantalla. --%>
<c:set var="esAuditoria" value="${param.vista == 'auditoria'}" />
<c:if test="${not esAuditoria}">
<sql:query var="proyectos" dataSource="${bd}">
  SELECT ${columnasInforme} ${desdeInforme}
  ORDER BY pr.id_proyecto DESC
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
  <sql:param value="${filtroDirector}" /><sql:param value="${filtroDirector}" /><sql:param value="${filtroEvaluador}" /><sql:param value="${filtroEvaluador}" />
</sql:query>
</c:if>
<c:if test="${esAuditoria}">
<sql:query var="eventos" dataSource="${bd}">
  SELECT ${columnasAuditoria} ${desdeAuditoria}
  ORDER BY h.fecha_evento DESC, h.id_historial DESC LIMIT 5000
  <sql:param value="${aDesde}" /><sql:param value="${aDesdeP}" /><sql:param value="${aHasta}" /><sql:param value="${aHastaP}" />
  <sql:param value="${aUsuario}" /><sql:param value="${aUsuario}" /><sql:param value="${aEntidad}" /><sql:param value="${aEntidad}" />
  <sql:param value="${aAccion}" /><sql:param value="${aAccion}" />
  <sql:param value="${aq}" /><sql:param value="${aqLike}" /><sql:param value="${aqLike}" /><sql:param value="${aqLike}" />
</sql:query>
</c:if>
<sql:query var="ahora" dataSource="${bd}">SELECT DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i') AS fecha</sql:query>
<c:set var="ignorar" value="${pageContext.response.setHeader('Content-Disposition', 'attachment; filename=' += (esAuditoria ? 'auditoria_sistema.xls' : 'informe_estado_proyectos.xls'))}" />
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<style>
  table { border-collapse: collapse; font-family: Calibri, Arial, sans-serif; font-size: 11pt; }
  td, th { border: 1px solid #C9D3CE; padding: 4px 8px; vertical-align: middle; mso-number-format: "\@"; }
  th { background: #14684B; color: #FFFFFF; font-weight: bold; text-align: left; }
  .titulo { font-size: 16pt; font-weight: bold; color: #0B3D2E; border: none; }
  .sub { color: #5E6B66; border: none; }
  .alterna td { background: #F5F8F6; }
</style>
</head>
<body>
<c:choose>
<c:when test="${esAuditoria}">
<table>
  <col width="130"><col width="220"><col width="110"><col width="210"><col width="150"><col width="170"><col width="130"><col width="420">
  <tr><td class="titulo" colspan="8">Sistema de Gestión de Proyectos de Grado - Auditoría del sistema</td></tr>
  <tr><td class="sub" colspan="8">Generado el <c:out value="${ahora.rows[0].fecha}" /> · <c:out value="${eventos.rowCount}" /> evento(s)<c:if test="${eventos.rowCount == 5000}"> (se exportan como máximo 5000, los más recientes)</c:if></td></tr>
  <tr><td class="sub" colspan="8"></td></tr>
  <tr>
    <th>Fecha</th><th>Usuario</th><th>Rol</th><th>Acción</th><th>Sobre</th><th>Referencia</th><th>Estado</th><th>Detalle</th>
  </tr>
  <c:forEach var="e" items="${eventos.rows}" varStatus="fila">
    <tr class="${fila.index mod 2 == 1 ? 'alterna' : ''}">
      <td><c:out value="${e.fecha}" /></td>
      <td><c:out value="${e.usuario}" /></td>
      <td><c:out value="${e.rol_texto}" /></td>
      <td><c:out value="${e.accion_texto}" /></td>
      <td><c:out value="${e.entidad_texto}" /></td>
      <td><c:out value="${e.referencia}" /></td>
      <td><c:if test="${not empty e.estado_anterior}"><c:out value="${fn:replace(fn:replace(fn:toLowerCase(e.estado_anterior), '_', ' '), 'apto graduacion', 'listo para sustentación')}" /> -> </c:if><c:out value="${fn:replace(fn:replace(fn:toLowerCase(e.estado_nuevo), '_', ' '), 'apto graduacion', 'listo para sustentación')}" /></td>
      <td><c:out value="${e.detalle}" /></td>
    </tr>
  </c:forEach>
</table>
</c:when>
<c:otherwise>
<table>
  <col width="110"><col width="320"><col width="260"><col width="150"><col width="170"><col width="190"><col width="190"><col width="190"><col width="150">
  <tr><td class="titulo" colspan="9">Sistema de Gestión de Proyectos de Grado - Informe de estado de proyectos</td></tr>
  <tr><td class="sub" colspan="9">Generado el <c:out value="${ahora.rows[0].fecha}" /> · <c:out value="${proyectos.rowCount}" /> proyecto(s)</td></tr>
  <tr><td class="sub" colspan="9"></td></tr>
  <tr>
    <th>Código</th><th>Título</th><th>Estudiantes</th><th>Fase</th><th>Estado</th><th>Director</th><th>Evaluador</th><th>Último movimiento</th><th>Fecha</th>
  </tr>
  <c:forEach var="p" items="${proyectos.rows}" varStatus="fila">
    <tr class="${fila.index mod 2 == 1 ? 'alterna' : ''}">
      <td><c:out value="${p.codigo}" /></td>
      <td><c:out value="${p.titulo}" /></td>
      <td><c:out value="${p.estudiantes}" /></td>
      <td>Fase <c:out value="${p.fase_actual}" /> - <c:out value="${p.fase}" /></td>
      <td><c:out value="${p.estado_general == 'EN_CURSO' ? 'En curso' : (p.estado_general == 'CERRADO' ? 'Cerrado' : 'Listo para sustentación')}" /></td>
      <td><c:out value="${empty p.director ? 'Sin asignar' : p.director}" /></td>
      <td><c:out value="${empty p.evaluador ? 'Sin asignar' : p.evaluador}" /></td>
      <td><c:out value="${p.ultimo_movimiento}" /></td>
      <td><c:out value="${p.ultimo_fecha}" /></td>
    </tr>
  </c:forEach>
</table>
</c:otherwise>
</c:choose>
</body>
</html>
