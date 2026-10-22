<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%-- Fuente de datos MySQL: único lugar donde se configura la conexión.
     Las credenciales vienen de variables de entorno (Clever Cloud). --%>
<sql:setDataSource var="bd" scope="request"
    driver="com.mysql.cj.jdbc.Driver"
    url="jdbc:mysql://${System.getenv('MYSQL_ADDON_HOST')}:${System.getenv('MYSQL_ADDON_PORT')}/${System.getenv('MYSQL_ADDON_DB')}?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=America/Bogota"
    user="${System.getenv('MYSQL_ADDON_USER')}"
    password="${System.getenv('MYSQL_ADDON_PASSWORD')}" />
