<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%--
  Cabecera común. Se incluye con <jsp:include>. La página define en ámbito request:
    titulo         título de la pestaña
    paginaPublica  true para login/registro (panel verde a la izquierda, sin menú)
    menuActivo     (opcional) ruta del ítem del menú que debe verse activo
    volverA        (opcional) ruta a la que lleva el botón "Volver" (por defecto, el inicio)
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
    <sql:query var="avisosCampana" dataSource="${bd}">
      SELECT n.id_notificacion, n.tipo, n.mensaje, IF(n.leida = 1, 'SI', 'NO') AS leida_txt,
             DATE_FORMAT(n.fecha_creacion, '%d/%m/%Y %H:%i') AS fecha, p.codigo AS codigo_proyecto
      FROM notificacion n
      LEFT JOIN proyecto pr ON pr.id_proyecto = n.id_proyecto
      LEFT JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
      WHERE n.id_usuario = ?
      ORDER BY n.fecha_creacion DESC, n.id_notificacion DESC
      LIMIT 20
      <sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
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
          <div class="dropdown">
            <button type="button" class="campana" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Notificaciones: ${notifCount} sin leer">
              <i class="bi bi-bell"></i>
              <c:if test="${notifCount > 0}"><span class="contador"><c:out value="${notifCount}" /></span></c:if>
            </button>
            <div class="dropdown-menu dropdown-menu-end notif-panel p-0">
              <div class="notif-cab">
                <strong>Notificaciones</strong>
                <c:if test="${notifCount > 0}">
                  <form method="post" action="${ctx}/proceso/notificacion_proc.jsp" class="m-0">
                    <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
                    <input type="hidden" name="accion" value="todas">
                    <input type="hidden" name="volver" value="${fn:escapeXml(pageContext.request.requestURI += (empty pageContext.request.queryString ? '' : '?') += pageContext.request.queryString)}">
                    <button type="submit" class="notif-todas"><i class="bi bi-check2-all me-1"></i>Marcar todas como leídas</button>
                  </form>
                </c:if>
              </div>
              <div class="notif-lista">
                <c:choose>
                  <c:when test="${avisosCampana.rowCount == 0}">
                    <div class="notif-vacio"><i class="bi bi-bell-slash"></i><div>Aún no tienes notificaciones.</div></div>
                  </c:when>
                  <c:otherwise>
                    <c:forEach var="av" items="${avisosCampana.rows}">
                      <c:set var="iconoAviso" value="${fn:startsWith(av.tipo, 'PQRS') ? 'bi-chat-dots' : (fn:startsWith(av.tipo, 'IDEA') ? 'bi-lightbulb' : (fn:startsWith(av.tipo, 'PROPUESTA') or av.tipo == 'COMPANERO_AGREGADO' ? 'bi-file-earmark-text' : (av.tipo == 'ASIGNACION' ? 'bi-people' : (av.tipo == 'REVISION' or av.tipo == 'ENTREGA' ? 'bi-clipboard-check' : 'bi-bell'))))}" />
                      <form method="post" action="${ctx}/proceso/notificacion_proc.jsp" class="m-0">
                        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
                        <input type="hidden" name="accion" value="abrir">
                        <input type="hidden" name="id" value="${av.id_notificacion}">
                        <button type="submit" class="notif-item ${av.leida_txt == 'NO' ? 'nueva' : ''}">
                          <span class="notif-icono"><i class="bi ${iconoAviso}"></i></span>
                          <span class="notif-texto">
                            <span class="notif-msg"><c:out value="${av.mensaje}" /></span>
                            <span class="notif-meta"><c:if test="${not empty av.codigo_proyecto}"><c:out value="${av.codigo_proyecto}" /> · </c:if><c:out value="${av.fecha}" /></span>
                          </span>
                          <c:if test="${av.leida_txt == 'NO'}"><span class="punto-nuevo" title="Sin leer"></span></c:if>
                        </button>
                      </form>
                    </c:forEach>
                  </c:otherwise>
                </c:choose>
              </div>
            </div>
          </div>
          <div class="usuario">
            <c:choose>
              <c:when test="${not empty sessionScope.fotoUrl}"><img class="iniciales" src="<c:out value='${sessionScope.fotoUrl}' />" alt="Foto de perfil" referrerpolicy="no-referrer"></c:when>
              <c:otherwise><span class="iniciales"><c:out value="${sessionScope.iniciales}" /></span></c:otherwise>
            </c:choose>
            <span class="nombre"><c:out value="${sessionScope.nombre}" /></span>
          </div>
        </div>
      </header>
      <c:if test="${pageContext.request.servletPath != '/inicio.jsp'}">
        <a class="btn btn-outline-uts btn-sm mt-2" href="${ctx}${empty volverA ? '/inicio.jsp' : volverA}"><i class="bi bi-arrow-left me-1"></i>Volver</a>
      </c:if>
      <jsp:include page="/WEB-INF/includes/mensaje.jsp" />
  </c:otherwise>
</c:choose>
