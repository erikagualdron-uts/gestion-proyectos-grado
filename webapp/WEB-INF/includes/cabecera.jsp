<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%--
  Cabecera común. Se incluye con <jsp:include>. La página define en ámbito request:
    titulo         título de la pestaña
    paginaPublica  true para login/registro (panel verde a la izquierda, sin menú)
    menuActivo     (opcional) ruta del ítem del menú que debe verse activo
--%>
<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><c:out value="${titulo}" /> · Sistema de Gestión de Proyectos de Grado</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Montserrat:wght@600;700;800&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
  <link href="${ctx}/css/estilos.css" rel="stylesheet">
</head>
<body>
<c:choose>
  <c:when test="${not empty paginaPublica}">
    <div class="publica">
      <aside class="publica-panel">
        <img class="logo" src="${ctx}/img/logo_oscuro.png" alt="Universidades Tecnológicas de Santander (UTS)">
        <div class="mensaje">
          <div class="barra"></div>
          <h1>Sistema de Gestión de Proyectos de Grado</h1>
          <p>Propuestas, fases, revisiones y solicitudes del trabajo de grado en un solo lugar, con seguimiento claro para estudiantes, docentes y comité.</p>
        </div>
      </aside>
      <main class="publica-area">
  </c:when>
  <c:otherwise>
    <sql:query var="notificaciones" dataSource="${bd}">
      SELECT COUNT(*) AS total FROM notificacion WHERE id_usuario = ? AND leida = 0
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
    <c:set var="notifCount" value="${notificaciones.rows[0].total}" scope="request" />
    <jsp:include page="/WEB-INF/includes/menu.jsp" />
    <div class="contenido">
      <header class="topbar">
        <div class="d-flex align-items-center gap-3">
          <button class="btn btn-outline-uts btn-icono d-lg-none" type="button" data-bs-toggle="offcanvas" data-bs-target="#menuLateral" aria-controls="menuLateral" aria-label="Abrir menú">
            <i class="bi bi-list"></i>
          </button>
          <span class="rol">
            <c:out value="${fn:substring(sessionScope.rol, 0, 1)}" /><c:out value="${fn:toLowerCase(fn:substring(sessionScope.rol, 1, 40))}" /><c:if test="${sessionScope.rol == 'ESTUDIANTE' and not empty sessionScope.nivel}"> · Nivel <c:out value="${sessionScope.nivel == 'TECNOLOGICO' ? 'Tecnológico' : 'Profesional'}" /></c:if>
          </span>
        </div>
        <div class="derecha">
          <a class="campana" href="${ctx}/modulos/notificaciones/notificaciones.jsp" aria-label="Notificaciones: ${notifCount} sin leer">
            <i class="bi bi-bell"></i>
            <c:if test="${notifCount > 0}"><span class="contador"><c:out value="${notifCount}" /></span></c:if>
          </a>
          <div class="usuario">
            <span class="iniciales"><c:out value="${sessionScope.iniciales}" /></span>
            <span class="nombre"><c:out value="${sessionScope.nombre}" /></span>
          </div>
        </div>
      </header>
      <jsp:include page="/WEB-INF/includes/mensaje.jsp" />
  </c:otherwise>
</c:choose>
