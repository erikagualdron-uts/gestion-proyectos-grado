<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="DOCENTE" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Módulo Docente Director (RF-49): proyectos que el docente dirige. --%>
<c:set var="titulo" value="Docente Director" scope="request" />
<c:set var="modoDocente" value="DIRECTOR" />
<c:set var="rutaDocente" value="/modulos/docente_director/docente_director.jsp" />
<%@ include file="/WEB-INF/includes/proyectos_docente.jsp" %>
