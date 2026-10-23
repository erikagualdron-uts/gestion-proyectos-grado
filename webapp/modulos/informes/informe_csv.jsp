<%@ page contentType="text/csv; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="COORDINADOR" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%@ include file="/WEB-INF/includes/informe_filtros.jsp" %>
<%-- Exportación del informe de estado a CSV (RF-62, deseable), con los mismos filtros de la pantalla. Separador ";" para Excel en español. --%>
<sql:query var="proyectos" dataSource="${bd}">
  SELECT ${columnasInforme} ${desdeInforme}
  ORDER BY pr.id_proyecto DESC
  <sql:param value="${q}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" /><sql:param value="${qLike}" />
  <sql:param value="${filtroFase}" /><sql:param value="${filtroFase}" /><sql:param value="${filtroEstado}" /><sql:param value="${filtroEstado}" />
  <sql:param value="${filtroDirector}" /><sql:param value="${filtroDirector}" /><sql:param value="${filtroEvaluador}" /><sql:param value="${filtroEvaluador}" />
</sql:query>
<c:set var="ignorar" value="${pageContext.response.setHeader('Content-Disposition', 'attachment; filename=\"informe_estado_proyectos.csv\"')}" />
<c:out value="${Character.toString(65279)}" escapeXml="false" />Código;Título;Estudiantes;Fase;Estado;Director;Evaluador;Último movimiento;Fecha del último movimiento
<c:forEach var="p" items="${proyectos.rows}">"${fn:replace(p.codigo, '"', '""')}";"${fn:replace(p.titulo, '"', '""')}";"${fn:replace(p.estudiantes, '"', '""')}";"Fase ${p.fase_actual} - ${fn:replace(p.fase, '"', '""')}";"${p.estado_general == 'EN_CURSO' ? 'En curso' : (p.estado_general == 'CERRADO' ? 'Cerrado' : 'Listo para sustentación')}";"${empty p.director ? 'Sin asignar' : fn:replace(p.director, '"', '""')}";"${empty p.evaluador ? 'Sin asignar' : fn:replace(p.evaluador, '"', '""')}";"${fn:replace(p.ultimo_movimiento, '"', '""')}";"${p.ultimo_fecha}"
</c:forEach>
