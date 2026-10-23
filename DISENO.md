# Diseño de interfaces

Leer antes de crear o modificar una pantalla. Objetivo: verse institucional y moderno con el mínimo de código. Vista principal: computador.
El diseño de referencia son 4 pantallas: inicio de sesión, inicio del estudiante, solicitudes del coordinador y seguimiento de fases. Todas las demás siguen el mismo estilo.

## Base
- **Bootstrap 5 por CDN** (CSS y JS) y **Bootstrap Icons por CDN** en la plantilla común. No escribir CSS propio salvo lo indicado aquí.
- Un solo archivo `css/estilos.css` con las variables de abajo y los ajustes de este documento; nada de estilos sueltos en las páginas.

## Tipografía (Google Fonts)
- **Montserrat** (600, 700, 800): títulos, botones, números grandes.
- **Inter** (400, 500, 600): texto, tablas y formularios.

## Paleta
- Verde bosque `#0B3D2E`: menú lateral, títulos, panel del login.
- Verde esmeralda `#14684B`: botones, encabezados de tabla, fases superadas y actual.
- Verde claro `#E6F2EC`: fondos de iconos, hover del menú, fondos suaves.
- Lima `#C4D600` (del logo UTS): solo detalles (contador de notificaciones, aro de la fase actual).
- Fondo de página `#F5F8F6`; tarjetas blancas con borde `#E3E8E5`; texto `#1F2A26`; texto secundario `#5E6B66`.
- Estados: aprobado verde `#DFF3E8` sobre `#0B5B3A`; aplazado ámbar `#FFF4D6` sobre `#7A5A00`; rechazado rojo `#FBE0DE` sobre `#9A2A22`; pendiente gris `#E8ECEA` sobre `#46524D`.

## Logo UTS
- Sobre fondo oscuro (menú lateral y panel del login) usar la versión con fondo transparente `img/logo_oscuro.png`: "uts" en lima y texto en blanco. Nunca poner el logo dentro de un recuadro blanco.
- Altura: 60 px en el menú lateral, 84 px en el login.
- Si hay una versión SVG oficial de la universidad, preferirla.

## Estructura de las pantallas
- Menú lateral fijo de 260 px, verde bosque, con logo arriba y línea separadora; ítem activo en esmeralda con texto blanco; **un icono por opción** (Bootstrap Icons) y "Cerrar sesión" al final.
- Cabecera con rol a la izquierda, y a la derecha la campana con contador (lima) y el usuario con sus iniciales.
- Panel del login: logo arriba, y el título con su descripción centrados verticalmente (sin cifras ni estadísticas).
- Contenido con título (Montserrat 800, 30 px), una línea de descripción y luego los bloques.

## Componentes
- **Tarjetas de módulos** de inicio: icono en cuadro verde claro, título y descripción corta; borde esmeralda y sombra suave al pasar el mouse.
- **Tarjetas de resumen** sobre las tablas (por ejemplo, coordinador: pendientes, aprobadas, aplazadas, rechazadas): icono en un cuadro del color del estado (reloj, visto, pausa, equis; nunca letras), número grande y etiqueta. Salen de un `COUNT` con JSTL.
- **Tablas:** encabezado esmeralda con texto blanco en mayúsculas, filas alternas, buscador, selector de estado, "registros por página" y paginación. Acciones: ojo = visualizar, lápiz = gestionar, siempre con `aria-label`.
- **Insignias de estado** (pastilla con punto de color a la izquierda): aprobado, aplazado, rechazado, pendiente según la paleta.
- **Seguimiento de fases (línea de tiempo con tarjetas, un solo bloque):** seis columnas unidas por una línea; arriba un círculo (visto verde si está superada, número con aro lima si es la actual, número en gris si está pendiente) y debajo su tarjeta con el estado y el nombre de la fase (verde superada o actual, gris pendiente). Debajo, la ventana de detalles con los documentos y su enlace.
- **Estados vacíos:** cuando no hay datos, tarjeta con borde punteado, icono en círculo verde claro, un título corto y una frase explicativa (por ejemplo, "Aún no hay revisiones nuevas").
- **Formularios:** `form-label` sobre cada campo, campos de 46 px con borde redondeado, botón principal esmeralda. En contraseñas, botón de ojo para mostrar u ocultar.
- **Mensajes:** `alert` de Bootstrap en español (verde éxito, rojo error, ámbar aviso, por ejemplo cuenta pendiente de aprobación).

## Reglas
- Bordes redondeados de 10 a 16 px y sombras suaves, de forma consistente.
- Responsive con la cuadrícula de Bootstrap; en pantallas pequeñas el menú se oculta y las tarjetas pasan a una columna.
- Mismo orden y mismos textos de botones en todos los módulos.
- No usar animaciones ni librerías extra, salvo lo autorizado: Chart.js (CDN) solo en la pestaña Resumen del "Panel y auditoría". Si algo no está aquí, usar el componente de Bootstrap más simple.
- No inventar estilos nuevos: si una pantalla es nueva, copiar la estructura de una de las cuatro de referencia.

## Pantallas del sistema y plantilla que copiar
Solo hay 4 pantallas de referencia (en `docs/referencia/`). Las demás se construyen copiando la estructura de una de ellas, sin inventar estilos nuevos:

| Pantalla | Copiar de |
|---|---|
| Inicio de sesión, Crear cuenta | 1. Inicio de sesión (el registro usa el mismo panel y un formulario más largo) |
| Inicio (todos los roles) | 2. Inicio del estudiante (tarjetas según el rol) |
| Banco de ideas, Base documental, Informes de estado (menú de tarjetas) | 2. Inicio del estudiante (cuadrícula de tarjetas) |
| Mi perfil, Proponer idea, Nueva propuesta, Radicar PQRS, Crear o editar usuario, Administrar enlaces (formularios) | 1. Inicio de sesión: formulario dentro de tarjeta blanca, dentro del layout con menú lateral y cabecera |
| Usuarios, Solicitudes de cuenta, Propuestas Banco, Solicitudes de estudiantes, Lista de PQRS, Notificaciones, Informes | 3. Solicitudes: tarjetas de resumen, buscador, filtro, tabla con ojo y lápiz, paginación |
| Gestionar (aprobar, aplazar o rechazar), Visualizar detalle | Ventana modal de Bootstrap con la misma paleta; botones de decisión con los colores de estado |
| Seguimiento del proyecto, Detalles del proyecto | 4. Seguimiento: línea de tiempo con tarjetas y tabla de documentos con enlace |
| Módulos Docente Director y Docente Evaluador | 3. Solicitudes (tabla de proyectos) más la fila de fases de 4. Seguimiento como filtro |
| Calificar documento (crear, editar, consultar revisión) | Formulario como en 1 y tabla de revisiones como en 3 |

Reglas para todas: mismo menú lateral (según el rol), misma cabecera, mismos botones, estados con insignias y estados vacíos con icono.

## Pantallas del sistema y patrón que debe copiar cada una
Las 4 pantallas de `docs/referencia/` son los patrones. Toda pantalla nueva copia uno de ellos; no se inventa un diseño nuevo.

**Patrón A: formulario centrado (como el inicio de sesión)**
- Crear cuenta (registro de estudiante, con aviso de cuenta pendiente).
- Páginas de error y de acceso no autorizado (mensaje corto, icono y botón para volver).

**Patrón B: inicio con tarjetas de módulos (como el inicio del estudiante)**
- Inicio de cada rol (administrador, coordinador, docente), solo cambian las tarjetas según el rol.
- Base documental (seis tarjetas con enlaces externos).

**Patrón C: listado con tabla (como las solicitudes del coordinador)**, con tarjetas de resumen cuando aplique
- Administrador: usuarios, cuentas pendientes por aprobar, enlaces de la base documental.
- Coordinador: propuestas del banco de ideas por revisar, asignación de director y evaluador, PQRS, informes de estado.
- Estudiante: banco de ideas (solo lectura), mis propuestas, mis PQRS, informe de estado.
- Docente: mis ideas propuestas, módulo Docente Director y módulo Docente Evaluador (tabla con tarjetas de fase que filtran).

**Patrón D: seguimiento por fases (como el seguimiento del estudiante)**
- Seguimiento de un proyecto desde cualquier rol, con la ventana de detalles y los documentos por enlace.

**Patrón E: formulario dentro del área interna (campos como en el login, con el menú lateral)**
- Mi perfil, crear o editar usuario, proponer una idea, crear una propuesta, radicar una PQRS, entregar un documento por enlace, calificar o decidir (aprobado, aplazado, rechazado, con observación).

**Reglas comunes para todas las pantallas**
- Las pantallas de detalle y de gestión (visualizar y gestionar) se abren como ventana modal, no como página nueva.
- Todas llevan el mismo menú lateral (según el rol), la cabecera con la campana y el usuario, y el estado vacío cuando no hay datos.
- Si una pantalla no encaja en ningún patrón, preguntar antes de diseñarla.
