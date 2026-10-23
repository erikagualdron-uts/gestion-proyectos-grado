# Proyecto: Sistema de Gestión de Proyectos de Grado (UTS)

Estudiante: Erika Viviana Gualdrón Parra · Tecnología en Desarrollo de Sistemas Informáticos · Programación JAVA.

## 0. Nombre y archivos de referencia
- Nombre del sistema (visible): Sistema de Gestión de Proyectos de Grado.
- Nombre técnico (carpeta, repositorio GitHub y aplicación en Clever Cloud): `gestion-proyectos-grado`. Base de datos: `gestion_proyectos_grado`. Si el nombre está ocupado, pregúntame.
- **Antes de crear o modificar una pantalla, lee `DISENO.md`.** Las imágenes de `docs/referencia/` son el diseño aprobado de las pantallas; cópialas fielmente y reutiliza sus patrones para las demás pantallas.
- Logos: `img/logo_oscuro.png` (fondos oscuros) e `img/logo_uts.png` (fondos claros).

## 1. Fuente de verdad
- El PDF del sistema (`Documento_Sistema_Gestion_Proyectos_de_Grado.pdf`): requerimientos RF-01 a RF-62, RNF-01 a RNF-20, historias de usuario, base de datos de 15 tablas, estructura de carpetas y script SQL (Anexo A).
- Si el PDF y mis instrucciones se contradicen, avísame y pregúntame.

## 2. Reglas técnicas obligatorias
- Solo JSP + JSTL (core, fmt, functions, sql). Sin scriptlets, sin Maven, sin archivos .java.
- Servidor: Apache Tomcat. Base de datos: MySQL. Despliegue: Clever Cloud. Repositorio: GitHub.
- Todas las consultas con `<sql:param>`; las operaciones sobre varias tablas con `<sql:transaction>`.
- Los documentos se guardan solo como enlace (URL), nunca como archivo. No se pide tipo ni formato del documento.
- Sin correos ni autenticación por correo. Sin créditos. Las notificaciones son internas (campana con contador).
- No calcular fechas límite ni días restantes. No implementar expiración de sesión ni HTTPS obligatorio.
- Estructura de carpetas y nombres de tablas exactamente como en el PDF (sección 9 y Anexo A).

## 3. Contexto del sistema
**Roles:** Administrador, Coordinador, Estudiante, Docente Director y Docente Evaluador (en la base se guardan 4 roles; un docente asume Director o Evaluador al asignarlo el coordinador a un proyecto).
- Administrador: crea coordinadores, docentes y administradores; aprueba o rechaza cuentas de estudiantes (asignando nivel Tecnológico o Profesional); edita datos bloqueados; administra los enlaces de la base documental.
- Estudiante: se registra solo (queda Pendiente hasta que se apruebe); elige una idea del banco o propone una propia; puede agregar un segundo estudiante por número de documento; entrega documentos por enlace; radica PQRS; ve su seguimiento e informe de estado.
- Coordinador: decide sobre ideas de docentes y propuestas de estudiantes; asigna director y evaluador; valida el pago; resuelve PQRS; ve informes de estado.
- Docente Director / Evaluador: ven sus proyectos, revisan y califican documentos, deciden en sus fases.
- Un docente puede ver ambos módulos, pero **nunca ser director y evaluador del mismo proyecto**.

**Cuentas:** solo correo institucional; contraseña con hash y sal; cuenta Pendiente no puede ingresar; casilla "Mantener sesión activa" (tabla `sesion_persistente`).

**Fases (en orden):** 1 Pago, 2 Propuesta I, 3 Propuesta II, 4 Informe I, 5 Informe II, 6 Revisión final. El estudiante no avanza hasta que la fase actual sea aprobada. Al aprobar la fase 6 queda listo para la sustentación (en la base: `APTO_GRADUACION`).

**Estados de decisión:** APROBADO, APLAZADO (el estudiante corrige y reenvía una nueva versión), RECHAZADO (solo casos extremos; exige confirmación y observación obligatoria) y PENDIENTE (estado técnico inicial).

**Otros módulos:** banco de ideas (solo ideas aprobadas, solo lectura), tabla de solicitudes con visualizar y gestionar, seguimiento con seis tarjetas (verde: superada o actual; gris: pendiente), PQRS (prórroga, cambio de director, petición, queja, reclamo, sugerencia), historial de versiones (se conservan todas, una marcada como vigente), notificaciones, informes de estado, base documental con seis tarjetas de enlaces.

## 4. Cómo trabajar conmigo
- Antes de configurar cuentas o servicios (GitHub, Clever Cloud, base de datos), **pregúntame los datos que necesites y encárgate tú de la configuración**. Guíame para iniciar sesión por navegador (`gh auth login`, `clever login`).
- Cada vez que te falte información o haya una decisión que me corresponda, **pregúntame antes de seguir**. No supongas.
- Trabaja un módulo a la vez. Al terminar cada uno: explícame brevemente qué hiciste, haz commit, redespliega y avísame para probarlo.
- Si un requerimiento choca con una limitación técnica (por ejemplo, JSTL no permite algo), propón una alternativa y pregúntame antes de cambiar el diseño.
- Si el tiempo no alcanza, dímelo y propón qué recortar, empezando por prioridad baja.
- Responde en español, de forma breve y clara.

## 5. Plan y orden de trabajo
Tiempo total: miércoles 2 h, jueves 12 h, viernes 4 h (viernes = documentación y entrega).

**Miércoles (2 h):** repositorio GitHub (ramas main y develop, .gitignore, carpetas); base MySQL en Clever Cloud con el script del PDF; plantilla común, conexión y seguridad; registro, login, logout y menú por rol (RF-01 a RF-07); primer despliegue.

**Jueves (12 h):**
1. Usuarios, aprobación de cuentas y perfil (RF-08 a RF-16) – 2 h
2. Inicio, base documental, banco de ideas y propuestas (RF-17 a RF-28) – 2,5 h
3. Tabla de solicitudes y asignación de director y evaluador (RF-29 a RF-37) – 1,5 h
4. Fases, entrega por enlace, módulos Director/Evaluador y calificación (RF-38 a RF-52) – 2,5 h
5. PQRS, notificaciones, historial e informes (RF-53 a RF-62) – 1,5 h
6. Pruebas con todos los roles y despliegue final – 1,5 h

**Prioridad:** primero A (alta), luego M (media), al final B (baja). No avances al siguiente bloque con el anterior roto.

**Definición de terminado de un módulo:** funciona para todos los roles que lo usan; validaciones en servidor y en navegador; muestra mensajes claros; protegido con `seguridad.jsp`; probado en el despliegue; commit hecho; `avance.md` actualizado.

## 6. Convenciones de código
- Nombres de archivos en minúscula con guion bajo (`entrega_form.jsp`, `login_proc.jsp`).
- Cada página protegida incluye `seguridad.jsp` al inicio (verifica sesión, rol y token CSRF). El menú nunca es la única barrera.
- Plantilla común para cabecera, menú lateral y pie; no repetir HTML ni la conexión.
- Todo texto ingresado por el usuario se muestra con `<c:out>` (o `fn:escapeXml`).
- Formularios de modificación con token anti-CSRF.
- Mensajes de éxito y error en español; colores consistentes; botones uniformes (ojo = visualizar, lápiz = gestionar).
- Diseño responsive (computador, tableta y celular).
- Listados con paginación (LIMIT/OFFSET), búsqueda y filtros.
- Borrado lógico (inactivar) cuando hay historial.

## 7. Datos de prueba
Crear un script `sql/datos_prueba.sql` (solo para demostración) con:
- Un usuario por rol (administrador, coordinador, estudiante, docente director, docente evaluador), con contraseñas simples de prueba. Aclarar en el README que son solo para pruebas.
- Un par de ideas aprobadas, una propuesta aprobada y un proyecto en distintas fases, para poder recorrer el sistema completo sin crear todo a mano.
- Nunca usar datos reales de personas.

## 8. Git
- Ramas: `main` (estable) y `develop` (trabajo). Integrar a main solo con el módulo probado.
- Commits en español con el módulo al inicio, por ejemplo: `perfil: guardar cambios con validación`.
- No subir contraseñas, tokens, archivos de configuración local ni carpetas generadas. Mantén el `.gitignore` al día.
- Actualizar el README al terminar cada módulo (instalación, variables de entorno, usuarios de prueba).

## 9. Despliegue en Clever Cloud
- Las credenciales de la base (host, puerto, nombre, usuario, contraseña) se leen de **variables de entorno**; el código nunca tiene datos de conexión fijos.
- Al inicio, confirmar conmigo y con la documentación actual cómo se despliega JSP en Clever Cloud (WAR o contenedor) y dejarlo funcionando con una página mínima.
- Redesplegar después de cada módulo terminado, no solo al final.
- Después de cada despliegue, verificar que el login y la conexión a la base funcionan.

## 10. Documentación mientras se desarrolla
- Mantener `avance.md`: por cada módulo terminado, listar lo implementado, las pantallas, los requerimientos y las historias de usuario que cubre, y los problemas resueltos.
- Pedirme una captura de cada pantalla importante y guardarla en `docs/capturas/` con nombre claro (`modulo_pantalla.png`).
- Al final, la documentación se arma con el PDF del sistema como base y estos archivos, adaptada a lo que realmente quedó funcionando.

## 11. Seguridad y privacidad
- Nunca escribas contraseñas, tokens ni claves en el código ni en commits; usa variables de entorno. En el chat solo las das si yo te las pido por el chat (por ejemplo, las contraseñas de las cuentas de prueba); nunca las muestres por iniciativa propia.
- Contraseñas almacenadas con hash y sal (SHA2 de MySQL); nunca en texto plano.
- Solo solicitar los datos personales necesarios (Ley 1581 de 2012).
