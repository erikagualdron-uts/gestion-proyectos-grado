<%-- Filtros y consulta comunes del informe de estado del coordinador (informe_coordinador.jsp).
     Define: q, qLike, filtroFase, filtroEstado, filtroDirector, filtroEvaluador y el texto SQL desdeInforme.
     Parámetros de desdeInforme, en orden: q, qLike x3, fase x2, estado x2, director x2, evaluador x2. --%>
<c:set var="q" value="${fn:trim(param.q)}" />
<c:set var="qLike" value="%${q}%" />
<c:catch var="errorFiltros">
  <c:set var="filtroFase" value="${empty param.fase ? 0 : param.fase + 0}" />
  <c:set var="filtroDirector" value="${empty param.director ? 0 : param.director + 0}" />
  <c:set var="filtroEvaluador" value="${empty param.evaluador ? 0 : param.evaluador + 0}" />
</c:catch>
<c:if test="${not empty errorFiltros or filtroFase < 0 or filtroFase > 6}">
  <c:set var="filtroFase" value="${0}" /><c:set var="filtroDirector" value="${0}" /><c:set var="filtroEvaluador" value="${0}" />
</c:if>
<c:set var="filtroEstado" value="${fn:contains(',EN_CURSO,APTO_GRADUACION,CERRADO,', ',' += param.estado += ',') ? param.estado : ''}" />
<c:set var="desdeInforme">
  FROM proyecto pr
  JOIN propuesta p ON p.id_propuesta = pr.id_propuesta
  JOIN fase f ON f.id_fase = pr.fase_actual
  LEFT JOIN usuario d ON d.id_usuario = pr.id_director
  LEFT JOIN usuario ev ON ev.id_usuario = pr.id_evaluador
  WHERE (? = '' OR p.codigo LIKE ? OR p.titulo LIKE ?
         OR EXISTS (SELECT 1 FROM propuesta_estudiante pe2 JOIN usuario e2 ON e2.id_usuario = pe2.id_estudiante
                    WHERE pe2.id_propuesta = p.id_propuesta AND e2.nombre_completo LIKE ?))
    AND (? = 0 OR pr.fase_actual = ?) AND (? = '' OR pr.estado_general = ?)
    AND (? = 0 OR pr.id_director = ?) AND (? = 0 OR pr.id_evaluador = ?)
</c:set>
<c:set var="columnasInforme">
  pr.id_proyecto, p.codigo, p.titulo, pr.fase_actual, f.nombre AS fase, pr.estado_general,
  d.nombre_completo AS director, ev.nombre_completo AS evaluador,
  (SELECT GROUP_CONCAT(e.nombre_completo ORDER BY pe.es_responsable DESC SEPARATOR ', ')
   FROM propuesta_estudiante pe JOIN usuario e ON e.id_usuario = pe.id_estudiante WHERE pe.id_propuesta = p.id_propuesta) AS estudiantes,
  (SELECT DATE_FORMAT(h.fecha_evento, '%d/%m/%Y %H:%i') FROM historial_version h WHERE h.id_proyecto = pr.id_proyecto
   ORDER BY h.fecha_evento DESC, h.id_historial DESC LIMIT 1) AS ultimo_fecha,
  (SELECT CASE h.accion WHEN 'CREAR' THEN 'Creación' WHEN 'DECIDIR' THEN 'Decisión' WHEN 'ASIGNAR' THEN 'Asignación'
     WHEN 'ENTREGAR' THEN 'Entrega de documento' WHEN 'REVISAR' THEN 'Revisión' WHEN 'EDITAR_REVISION' THEN 'Revisión editada'
     WHEN 'APROBAR_FASE' THEN 'Fase aprobada' WHEN 'APLAZAR_FASE' THEN 'Fase aplazada' WHEN 'CERRAR_PROYECTO' THEN 'Proyecto cerrado'
     WHEN 'APTO_GRADUACION' THEN 'Listo para sustentación' WHEN 'CAMBIAR_DIRECTOR' THEN 'Cambio de director' ELSE h.accion END
   FROM historial_version h WHERE h.id_proyecto = pr.id_proyecto
   ORDER BY h.fecha_evento DESC, h.id_historial DESC LIMIT 1) AS ultimo_movimiento
</c:set>
