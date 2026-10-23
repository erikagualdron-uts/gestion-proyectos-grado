<%@ page contentType="application/vnd.ms-excel; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/informe_filtros.jsp" %>
<%-- Exportación del informe de estado a Excel (RF-62): una tabla HTML con estilos que Excel abre con formato
     (encabezado verde, bordes y anchos de columna). Respeta los mismos filtros de la pantalla. --%>
<sql:query var="proyectos" dataSource="${bd}">
  SELECT ${columnasInforme} ${desdeInforme}
  ORDER BY pr.id_proyecto DESC
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
  <sql:param value="${filtroDirector}" /><sql:param value="${filtroDirector}" /><sql:param value="${filtroEvaluador}" /><sql:param value="${filtroEvaluador}" />
</sql:query>
<sql:query var="ahora" dataSource="${bd}">SELECT DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i') AS fecha</sql:query>
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
</body>
</html>
