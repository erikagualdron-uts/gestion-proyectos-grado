<%-- Datos comunes de las seis fases. Se incluye con <%@ include %> (necesita los taglibs c y fn).
     nombresDocumento[fase - 1] = nombre del documento principal que se revisa en esa fase.
     Quién entrega y quién decide en cada fase:
       1 Pago          entrega el estudiante responsable   decide el coordinador (comité)
       2 Propuesta I   entrega el estudiante responsable   decide el director (formato F-DC-124)
       3 Propuesta II  se copia el anteproyecto aprobado   el director aprueba el envío; luego evaluador (rejilla del F-DC-124) y comité
       4 Informe I     entrega el estudiante responsable   decide el director (formato F-DC-125)
       5 Informe II    se copia el informe aprobado        el director aprueba el envío (con Turnitin); luego evaluador (rejilla F-DC-129) y comité
       6 Revisión final no hay entrega ni revisión: se alcanza sola cuando evaluador y comité aprueban la fase 5
                       y deja el proyecto listo para la sustentación --%>
<c:set var="nombresDocumento" value="${fn:split('Comprobante de pago|Anteproyecto (F-DC-124)|Anteproyecto (F-DC-124)|Informe (F-DC-125)|Informe (F-DC-125)|Revisión final', '|')}" />
