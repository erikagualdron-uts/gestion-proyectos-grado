<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@ include file="/WEB-INF/includes/conexion.jsp" %>
<c:set var="rolesPermitidos" value="ESTUDIANTE" />
<%@ include file="/WEB-INF/includes/seguridad.jsp" %>
<%-- Propuesta del estudiante. Sin id: propuesta propia nueva (RF-25), con segundo estudiante opcional (RF-26).
     Con id: pendiente = solo cambiar al compañero; aplazada = corregir y reenviar (RF-28). --%>
<c:set var="menuActivo" value="/modulos/propuestas/propuestas_banco.jsp" scope="request" />
<c:set var="volverA" value="/modulos/propuestas/propuestas_banco.jsp" scope="request" />

<c:if test="${empty param.id}">
  <sql:query var="activa" dataSource="${bd}">
    SELECT p.codigo FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
    WHERE pe.id_estudiante = ? AND p.estado_decision <> 'RECHAZADO' LIMIT 1
    <sql:param value="${sessionScope.usuarioId}" />
  </sql:query>
  <c:if test="${activa.rowCount > 0}">
    <c:set var="flashTipo" value="warning" scope="session" />
    <c:set var="flashMsg" value="Ya participas en la propuesta ${activa.rows[0].codigo}. Solo puedes tener una propuesta activa." scope="session" />
    <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
  </c:if>
</c:if>

<c:if test="${not empty param.id}">
  <c:catch var="idInvalido"><c:set var="idPropuesta" value="${param.id + 0}" /></c:catch>
  <c:if test="${empty idInvalido}">
    <sql:query var="consulta" dataSource="${bd}">
      SELECT p.id_propuesta, p.codigo, p.origen, p.titulo, p.descripcion, p.objetivo, p.alcance, p.estado_decision, p.observacion
      FROM propuesta p JOIN propuesta_estudiante pe ON pe.id_propuesta = p.id_propuesta
      WHERE p.id_propuesta = ? AND pe.id_estudiante = ? AND pe.es_responsable = 1
      <sql:param value="${idPropuesta}" /><sql:param value="${sessionScope.usuarioId}" />
    </sql:query>
  </c:if>
  <c:if test="${not empty idInvalido or consulta.rowCount != 1 or (consulta.rows[0].estado_decision != 'PENDIENTE' and consulta.rows[0].estado_decision != 'APLAZADO')}">
    <c:set var="flashTipo" value="danger" scope="session" />
    <c:set var="flashMsg" value="La propuesta no existe o ya no se puede modificar." scope="session" />
    <c:redirect url="/modulos/propuestas/propuestas_banco.jsp" />
  </c:if>
  <c:set var="propuesta" value="${consulta.rows[0]}" />
  <sql:query var="companero" dataSource="${bd}">
    SELECT e.numero_documento, e.nombre_completo
    FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante
    WHERE pe.id_propuesta = ? AND pe.es_responsable = 0
    <sql:param value="${idPropuesta}" />
  </sql:query>
</c:if>

<c:set var="editando" value="${not empty propuesta}" />
<c:set var="companeroFijo" value="${editando and companero.rowCount > 0}" />
<c:set var="contenidoEditable" value="${not editando or propuesta.estado_decision == 'APLAZADO'}" />
<c:set var="titulo" value="${editando ? 'Corregir propuesta' : 'Nueva propuesta'}" scope="request" />
<c:set var="vTitulo" value="${not empty sessionScope.vpTitulo ? sessionScope.vpTitulo : (editando ? propuesta.titulo : '')}" />
<c:set var="vDescripcion" value="${not empty sessionScope.vpDescripcion ? sessionScope.vpDescripcion : (editando ? propuesta.descripcion : '')}" />
<c:set var="vObjetivo" value="${not empty sessionScope.vpObjetivo ? sessionScope.vpObjetivo : (editando ? propuesta.objetivo : '')}" />
<c:set var="vAlcance" value="${not empty sessionScope.vpAlcance ? sessionScope.vpAlcance : (editando ? propuesta.alcance : '')}" />
<c:set var="vCompanero" value="${sessionScope.vpCompanero != null ? sessionScope.vpCompanero : (editando and companero.rowCount > 0 ? companero.rows[0].numero_documento : '')}" />

<jsp:include page="/WEB-INF/includes/cabecera.jsp" />

<h1 class="titulo-pagina"><c:out value="${titulo}" /></h1>
<p class="descripcion-pagina">
  <c:choose>
    <c:when test="${not editando}">Propón tu propia idea de trabajo de grado. Quedará pendiente de aprobación del coordinador. Solo puedes tener una propuesta activa a la vez.</c:when>
    <c:when test="${propuesta.estado_decision == 'APLAZADO'}">El coordinador aplazó tu propuesta. Corrígela y reenvíala; se conserva la versión anterior.</c:when>
    <c:otherwise>Tu propuesta está pendiente de decisión. Mientras tanto solo puedes agregar a tu compañero (si aún no lo tienes).</c:otherwise>
  </c:choose>
</p>

<c:if test="${editando and propuesta.estado_decision == 'APLAZADO' and not empty propuesta.observacion}">
  <div class="alert alert-warning" role="alert"><i class="bi bi-chat-left-text me-1"></i><strong>Observación del coordinador:</strong> <c:out value="${propuesta.observacion}" /></div>
</c:if>

<div class="row">
  <div class="col-12 col-xl-8">
    <div class="tarjeta">
      <c:if test="${editando}"><div class="mb-3"><span class="etiqueta-sup">Propuesta</span> <span class="fw-bold"><c:out value="${propuesta.codigo}" /></span></div></c:if>
      <form method="post" action="${ctx}/proceso/propuesta_proc.jsp" class="needs-validation" novalidate>
        <input type="hidden" name="csrf" value="<c:out value='${sessionScope.csrf}' />">
        <input type="hidden" name="accion" value="${editando ? 'editar' : 'crear'}">
        <c:if test="${editando}"><input type="hidden" name="id" value="${propuesta.id_propuesta}"></c:if>

        <div class="mb-3">
          <label for="titulo" class="form-label requerido">Título</label>
          <input type="text" class="form-control ${contenidoEditable ? '' : 'campo-bloqueado'}" id="titulo" name="titulo" maxlength="200" minlength="5" placeholder="Ej.: Sistema web para el control de inventario" value="<c:out value='${vTitulo}' />" ${contenidoEditable ? 'required' : 'readonly'}>
          <div class="invalid-feedback">Ingresa el título (mínimo 5 caracteres).</div>
        </div>
        <div class="mb-3">
          <label for="descripcion" class="form-label">Descripción <span class="texto-sec">(opcional)</span></label>
          <textarea class="form-control ${contenidoEditable ? '' : 'campo-bloqueado'}" id="descripcion" name="descripcion" rows="3" maxlength="2000" ${contenidoEditable ? '' : 'readonly'}><c:out value="${vDescripcion}" /></textarea>
        </div>
        <div class="mb-3">
          <label for="objetivo" class="form-label requerido">Objetivo</label>
          <textarea class="form-control ${contenidoEditable ? '' : 'campo-bloqueado'}" id="objetivo" name="objetivo" rows="3" maxlength="2000" placeholder="¿Qué quieres lograr con tu trabajo de grado?" ${contenidoEditable ? 'required' : 'readonly'}><c:out value="${vObjetivo}" /></textarea>
          <div class="invalid-feedback">Escribe el objetivo.</div>
        </div>
        <div class="mb-3">
          <label for="alcance" class="form-label requerido">Alcance</label>
          <textarea class="form-control ${contenidoEditable ? '' : 'campo-bloqueado'}" id="alcance" name="alcance" rows="3" maxlength="2000" placeholder="¿Hasta dónde llega el trabajo y qué no incluye?" ${contenidoEditable ? 'required' : 'readonly'}><c:out value="${vAlcance}" /></textarea>
          <div class="invalid-feedback">Escribe el alcance.</div>
        </div>

        <div class="mb-4">
          <label for="companero" class="form-label">Segundo estudiante <span class="texto-sec">(opcional)</span></label>
          <input type="text" class="form-control ${companeroFijo ? 'campo-bloqueado' : ''}" id="companero" name="companero" maxlength="20" pattern="[0-9A-Za-z]{5,20}" inputmode="numeric" placeholder="Número de documento de tu compañero"
                 value="<c:out value='${companeroFijo ? companero.rows[0].numero_documento : vCompanero}' />" ${companeroFijo ? 'readonly' : ''}>
          <div class="form-text">
            <c:choose>
              <c:when test="${companeroFijo}">Compañero registrado: <strong><c:out value="${companero.rows[0].nombre_completo}" /></strong>. Ya no se puede modificar.</c:when>
              <c:otherwise>Debe tener cuenta aprobada y no estar en otra propuesta activa. Una vez agregado, no se podrá cambiar. Tú, como responsable, serás quien entregue los documentos; tu compañero solo podrá consultarlos.</c:otherwise>
            </c:choose>
          </div>
          <div class="invalid-feedback">Entre 5 y 20 letras o números.</div>
        </div>

        <div class="d-flex flex-wrap gap-2">
          <button type="submit" class="btn btn-uts px-4">
            <i class="bi bi-send me-1"></i>${not editando ? 'Enviar propuesta' : (propuesta.estado_decision == 'APLAZADO' ? 'Corregir y reenviar' : 'Agregar compañero')}
          </button>
          <a class="btn btn-outline-uts px-4" href="${ctx}/modulos/propuestas/propuestas_banco.jsp">Cancelar</a>
        </div>
      </form>
    </div>
  </div>
</div>
<c:remove var="vpTitulo" scope="session" />
<c:remove var="vpDescripcion" scope="session" />
<c:remove var="vpObjetivo" scope="session" />
<c:remove var="vpAlcance" scope="session" />
<c:remove var="vpCompanero" scope="session" />

<jsp:include page="/WEB-INF/includes/pie.jsp" />
