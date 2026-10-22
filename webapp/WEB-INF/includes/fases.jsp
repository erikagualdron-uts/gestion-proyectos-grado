<%-- Datos comunes de las seis fases. Se incluye con <%@ include %> (necesita los taglibs c y fn).
     nombresDocumento[fase - 1] = nombre del documento principal que se revisa en esa fase.
     Quién entrega y quién decide en cada fase:
       1 Pago          entrega el estudiante responsable   decide el coordinador (comité)
       2 Propuesta I   entrega el estudiante responsable   decide el director
       3 Propuesta II  se copia la propuesta aprobada      el director aprueba el envío; luego evaluador y comité
       4 Informe I     entrega el estudiante responsable   decide el director
       5 Informe II    se copia el informe aprobado        el director aprueba el envío; luego evaluador y comité
       6 Revisión final entrega el estudiante responsable  deciden evaluador y comité --%>
<c:set var="nombresDocumento" value="${fn:split('Comprobante de pago|Propuesta (anteproyecto)|Propuesta|Informe|Informe|Informe final', '|')}" />
