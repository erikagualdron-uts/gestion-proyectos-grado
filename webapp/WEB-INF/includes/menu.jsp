<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%-- Menú lateral según el rol (RF-06). Cada opción: icono|texto|ruta, separadas por punto y coma. --%>
<c:choose>
  <c:when test="${sessionScope.rol == 'ESTUDIANTE'}">
    <c:set var="opciones" value="bi-house-door|Inicio|/inicio.jsp;bi-person|Mi perfil|/modulos/perfil/perfil.jsp;bi-lightbulb|Banco de ideas|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Mis propuestas|/modulos/propuestas/propuestas_banco.jsp;bi-journal-text|Base documental|/modulos/base_documental/base_documental.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'DOCENTE'}">
    <c:set var="opciones" value="bi-house-door|Inicio|/inicio.jsp;bi-person|Mi perfil|/modulos/perfil/perfil.jsp;bi-lightbulb|Banco de ideas|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Propuestas Banco|/modulos/propuestas/propuestas_banco.jsp;bi-person-check|Docente Director|/modulos/docente_director/docente_director.jsp;bi-clipboard-check|Docente Evaluador|/modulos/docente_evaluador/docente_evaluador.jsp;bi-journal-text|Base documental|/modulos/base_documental/base_documental.jsp" />
  </c:when>
  <c:when test="${sessionScope.rol == 'COORDINADOR'}">
    <c:set var="opciones" value="bi-house-door|Inicio|/inicio.jsp;bi-person|Mi perfil|/modulos/perfil/perfil.jsp;bi-lightbulb|Banco de ideas|/modulos/banco_ideas/banco_ideas.jsp;bi-file-earmark-text|Propuestas Banco|/modulos/propuestas/propuestas_banco.jsp;bi-people|Asignación de proyectos|/modulos/proyectos/asignacion.jsp;bi-chat|PQRS|/modulos/pqrs/pqrs.jsp;bi-bar-chart|Informes de estado|/modulos/informes/informe_coordinador.jsp;bi-journal-text|Base documental|/modulos/base_documental/base_documental.jsp" />
  </c:when>
  <c:otherwise>
    <c:set var="opciones" value="bi-house-door|Inicio|/inicio.jsp;bi-person|Mi perfil|/modulos/perfil/perfil.jsp;bi-people|Usuarios|/modulos/usuarios/usuarios.jsp;bi-person-check|Solicitudes de cuenta|/modulos/usuarios/cuentas_pendientes.jsp;bi-file-earmark-text|Propuestas Banco|/modulos/propuestas/propuestas_banco.jsp;bi-chat|PQRS|/modulos/pqrs/pqrs.jsp;bi-clock-history|Historial de versiones|/modulos/historial/historial.jsp;bi-journal-text|Base documental|/modulos/base_documental/base_documental.jsp" />
  </c:otherwise>
</c:choose>
<c:set var="rutaActual" value="${empty menuActivo ? pageContext.request.servletPath : menuActivo}" />

<div class="offcanvas-lg offcanvas-start menu-lateral d-flex flex-column" tabindex="-1" id="menuLateral" aria-label="Menú principal">
  <div class="menu-logo">
    <img src="${ctx}/img/logo_oscuro.png" alt="Universidades Tecnológicas de Santander (UTS)">
  </div>
  <nav>
    <c:forEach var="opcion" items="${fn:split(opciones, ';')}">
      <c:set var="p" value="${fn:split(opcion, '|')}" />
      <a class="item ${rutaActual == p[2] ? 'activo' : ''}" href="${ctx}${p[2]}" ${rutaActual == p[2] ? 'aria-current="page"' : ''}>
        <i class="bi ${p[0]}"></i><span><c:out value="${p[1]}" /></span>
      </a>
    </c:forEach>
  </nav>
  <div class="menu-pie">
    <a class="item" href="${ctx}/cerrar_sesion.jsp"><i class="bi bi-box-arrow-left"></i><span>Cerrar sesión</span></a>
  </div>
</div>
