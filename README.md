# App asistControl
Trabajo de Programación Web | Universidad de Lima 2025-2

## Configuración del Ambiente de Desarrollo

**Stack base**
- **Flutter/Dart** (UI móvil)
- **Git** (control de versiones)
- **Editor**: VS Code (extensiones: *Flutter*, *Dart*, *PlantUML*)
- **Android SDK / Emulador** o dispositivo físico
- **Backend & DB** (para la entrega conceptual): Supabase (Auth, PostgREST, Edge Functions, PostgreSQL)
- **Herramientas de apoyo**: Postman/Insomnia, PlantUML (diagramas)

**Instalación y verificación rápida**
1. **Flutter**  
   - Descarga/instala Flutter según tu SO.  
   - Verifica:  
     ```bash
     flutter doctor -v
     dart --version
     ```
   - Asegúrate de que `flutter doctor` marque todo en verde (o justifica lo pendiente).
2. **Git**  
   - Verifica:  
     ```bash
     git --version
     ```
3. **Editor (VS Code)**  
   - Extensiones: *Flutter* (Dart-Code), *Dart*, *PlantUML (jebbs)*.
4. **Android SDK / Emulador**  
   - Crea un dispositivo virtual (Pixel/Android 12+).  
   - Conecta un físico si prefieres (activar *Depuración USB*).
5. **PlantUML** (para diagramas)  
   - Requiere **Java 11+** y **Graphviz** (para layouts).  
   - Verificación (luego de instalarlos, ver PASO 3):  
     ```bash
     java -version
     dot -V
     ```

> Para la **Evaluación 1**, el foco es documentar: entorno, despliegue, RNF, casos de uso y mockups. El backend puede quedar descrito (no es necesario tenerlo implementado aún).


## Diagrama de Despliegue


![Diagrama de Despliegue](docs/img/despliegue.png)

**Resumen del despliegue.** La app móvil Flutter (AsistControl) se autentica con **Supabase Auth** para obtener un **JWT** y consume la **PostgREST API** (HTTPS) para operaciones de datos en **PostgreSQL**. Para lógica de negocio y generación de reportes se invocan **Edge Functions**, que también interactúan con **Storage** (archivos). La app usa **Geolocation API** al marcar asistencia y recibe **push notifications (FCM)** desde el backend. Este esquema fundamenta los RNF de seguridad, rendimiento y disponibilidad definidos abajo.






## Requerimientos No Funcionales

**Seguridad**
- **Autenticación y Autorización:** Todo acceso a datos requerirá **JWT** emitido por Supabase Auth. El token se envía en el header `Authorization: Bearer <jwt>`.
- **Transporte:** 100% del tráfico **HTTPS/TLS 1.2+**.
- **Acceso a datos:** Reglas **RLS** (Row-Level Security) activas en tablas sensibles; un empleado solo ve sus propios registros.
- **Almacenamiento local:** Tokens y flags en almacenamiento seguro del dispositivo; sin persistir contraseñas en texto plano.
- **Privacidad de ubicación:** La geolocalización se solicita **solo** al marcar asistencia; no se trackea en background.

**Rendimiento**
- **Tiempo de inicio (TTI):** < **3 s** en un dispositivo Android medio (4G).
- **Latencia API:** p95 < **300 ms** para lecturas simples; p95 < **600 ms** para escrituras/reportes.
- **Peso de respuestas:** p95 < **100 KB** en listados; paginación aplicada (p. ej., 20 ítems).
- **Render en cliente:** 60 FPS en pantallas principales (scroll de historial y listado de empleados).

**Disponibilidad y Confiabilidad**
- **Disponibilidad del backend:** ≥ **99.5%** en horario laboral (08:00–22:00).
- **Degradación controlada:** Si el backend no responde, la app muestra estado “sin conexión” y permite reintentar; no se pierde el estado de UI.
- **Tolerancia a fallos:** Reintentos exponenciales para llamadas críticas (login, marcar asistencia).

**Escalabilidad**
- **Horizontal en API/Functions:** backend sin estado, escalable por demanda.
- **Base de datos:** índices en columnas de búsqueda (employee_id, record_date); partición lógica por fechas si el volumen crece.

**Compatibilidad**
- **SO objetivo:** Android **10+** (API 29 o superior). *(iOS opcional para etapa 2).*
- **Tamaños de pantalla:** Layouts responsivos para 360–480 dpi.

**Usabilidad y Accesibilidad**
- **Flujo de asistencia en ≤ 3 toques.**
- **Textos y contraste** AA; tamaños de touch target ≥ **44 px**; mensajes de error comprensibles.

**Observabilidad**
- **Trazabilidad:** cada request incluye un **correlation-id** (generado en el cliente) que se propaga en logs del backend.
- **Métricas:** conteo de marca de asistencia/día, tiempos de respuesta y errores por endpoint.
- **Registro de errores:** logs de app y backend con niveles (info/warn/error), sin PII sensible.

**Mantenibilidad y Calidad**
- **Estructura de código** modular por features.
- **Convenciones:** formateo y lints activos; nomenclatura consistente.
- **Pruebas:** smoke tests para login y flujo de marcar asistencia.

**Requisitos legales**
- **Consentimiento:** solicitud explícita de permiso de ubicación antes de la primera marca.
- **Retención:** políticas de retención de datos alineadas a la normativa local; exportación de datos del empleado bajo solicitud.









## Diagrama de Casos de Uso

![Diagrama de Casos de Uso](docs/img/casos_uso.png)

**Actores:**  
- **Administrador:** configura empresa, horarios y geocercas; gestiona empleados; revisa notificaciones; consulta reportes.  
- **Empleado:** inicia sesión, marca asistencia (entrada, salida, inicio/fin de almuerzo) y consulta su historial.  
- **Sistema:** valida geolocalización, calcula horas trabajadas y genera/envía notificaciones.

**Principales casos de uso:**  
UC-01 Gestionar Empresa · UC-02 Configurar Horarios/Geocercas · UC-03 Gestionar Empleados ·  
UC-04 Consultar Reportes · UC-05 Revisar Notificaciones · UC-06 Iniciar Sesión ·  
UC-07 Marcar Asistencia (Entrada/Salida/Inicio/Fin) · UC-08 Consultar Historial ·  
UC-09 Validar Geolocalización · UC-10 Calcular Horas · UC-11 Generar/Enviar Notificaciones.

## Descripciones de Casos de Uso

> Nota: Los IDs y nombres coinciden con el diagrama de casos de uso. Cada UC incluye propósito, flujos y criterios de aceptación para validación.

### UC-06: Iniciar Sesión
**Actor principal:** Empleado (también aplica a Administrador)  
**Propósito:** Autenticar al usuario y abrir una sesión segura con JWT.  
**Precondiciones:** El usuario tiene una cuenta activa. Conectividad a internet.  
**Postcondiciones:** La app mantiene un JWT válido en almacenamiento seguro.

**Flujo principal**
1. El usuario abre la app y elige “Iniciar sesión”.
2. Ingresa email y contraseña (o PIN si está habilitado).
3. La app envía credenciales a Supabase Auth.
4. El backend valida y retorna **JWT** y datos básicos del perfil.
5. La app guarda el JWT de forma segura y redirige al **Home**.

**Flujos alternos/Excepciones**
- **FA1:** Credenciales inválidas → Mostrar *“Usuario o contraseña incorrectos”* y permitir reintentar.
- **FA2:** Cuenta desactivada → Mostrar *“Tu cuenta está inactiva, contacta al administrador”*.
- **FA3:** Sin internet → Mostrar estado *offline* y deshabilitar login.

**Criterios de aceptación (Gherkin)**
```gherkin
Scenario: Login válido
  Given un usuario activo con email y contraseña correctos
  When ingresa sus credenciales y envía
  Then recibe un JWT válido y accede a la pantalla Home

Scenario: Login inválido
  Given un usuario con credenciales incorrectas
  When intenta iniciar sesión
  Then la app muestra "Usuario o contraseña incorrectos" y permanece en Login
```

**Mockups vinculados:** 
- `docs/img/mockups/seleccionar_empresa.png`
- `docs/img/mockups/login.png`



---

### UC-07: Marcar Asistencia (Entrada/Salida/Almuerzo)
**Actor principal:** Empleado  
**Propósito:** Registrar marcas de **Entrada**, **Salida**, **Inicio/Fin de almuerzo**.  
**Precondiciones:** Sesión iniciada, permisos de ubicación concedidos, conectividad.  
**Postcondiciones:** Se crea un registro en la tabla de asistencia asociado al empleado.

**Flujo principal (Entrada como ejemplo)**
1. El empleado toca **“Marcar Asistencia”** → selecciona **Entrada**.
2. La app solicita **geolocalización** actual.
3. La app envía `{employee_id, tipo=entrada, timestamp, lat/lon}` a la API.
4. El backend **valida geocerca** y **calcula tardanza** según hora esperada.
5. Se guarda el registro y se confirma en la app.

**Flujos alternos/Excepciones**
- **FA1:** Ubicación fuera de geocerca → Mostrar *“Fuera de zona permitida”* y no registrar.
- **FA2:** Sin permisos de ubicación → Solicitar permisos; si se niegan, cancelar operación.
- **FA3:** Backend no responde → Reintento con backoff; si persiste, mostrar *“No se pudo registrar, reintenta”*.

**Criterios de aceptación (Gherkin)**
```gherkin
Scenario: Entrada válida dentro de geocerca
  Given un empleado con sesión activa y permisos de ubicación
  And se encuentra dentro de la geocerca de su empresa
  When marca Entrada
  Then el sistema registra la asistencia con éxito
  And si llegó tarde, calcula los minutos de tardanza

Scenario: Marca fuera de geocerca
  Given un empleado con sesión activa y permisos de ubicación
  And se encuentra fuera de la geocerca
  When intenta marcar Entrada
  Then la app notifica "Fuera de zona permitida" y no registra
```

**Mockups vinculados:** 
- `docs/img/mockups/home_empleado.png`
- `docs/img/mockups/acciones_asistencia.png`
- `docs/img/mockups/confirmacion.png`



---

### UC-04: Consultar Reportes (Administrador)
**Actor principal:** Administrador  
**Propósito:** Visualizar reportes por empleado/fecha y exportar a archivo.  
**Precondiciones:** Sesión válida de Admin. Datos de asistencia existentes.  
**Postcondiciones:** Se muestran reportes; opcionalmente se genera archivo (CSV/Excel).

**Flujo principal**
1. El Admin abre **Reportes**.
2. Selecciona filtros: rango de fechas, empleado(s), área, tipo de marca.
3. La app consulta la API y muestra el listado y totales (horas, tardanzas).
4. (Opcional) El Admin presiona **“Exportar”** y se genera un archivo.

**Flujos alternos/Excepciones**
- **FA1:** Sin datos en el rango → Mostrar *“Sin resultados para los filtros seleccionados”*.
- **FA2:** Error de backend → Mensaje de error + opción de reintento.

**Criterios de aceptación (Gherkin)**
```gherkin
Scenario: Consulta con resultados
  Given un administrador con sesión activa
  When filtra reportes por un rango de fechas
  Then la app muestra la lista de marcas y totales asociados

Scenario: Exportación a archivo
  Given un administrador visualizando un reporte
  When presiona "Exportar"
  Then el sistema genera un archivo descargable con los datos actuales
```

**Mockups vinculados:** 
- `docs/img/mockups/historial_asistencia.png`
- `docs/img/mockups/tardanzas.png`
- `docs/img/mockups/panel_admin.png`



## Prototipos (Mockups)

### Flujo Empleado
1. **Seleccionar Empresa**  
   ![Seleccionar Empresa](docs/img/mockups/seleccionar_empresa.png)

2. **Login**  
   ![Login](docs/img/mockups/login.png)

3. **Home (listo para marcar)**  
   ![Home Empleado](docs/img/mockups/home_empleado.png)

4. **Acciones de Asistencia** (Entrada/Salida/Almuerzo)  
   ![Acciones de Asistencia](docs/img/mockups/acciones_asistencia.png)

5. **Confirmación de Marca** (éxito/error)  
   ![Confirmación](docs/img/mockups/confirmacion.png)

---

### Flujo Administrador
1. **Configurar Empresa (alta inicial)**  
   ![Configurar Empresa](docs/img/mockups/configurar_empresa.png)

2. **Panel de Administración (KPIs)**  
   ![Panel Admin](docs/img/mockups/panel_admin.png)

3. **Gestión de Empleados**  
   ![Gestión de Empleados](docs/img/mockups/gestion_empleados.png)

4. **Credenciales del Empleado (modal)**  
   ![Credenciales del Empleado](docs/img/mockups/credenciales_empleado.png)

5. **Configuración de Horarios**  
   ![Configuración de Horarios](docs/img/mockups/configuracion_horarios.png)

6. **Historial de Asistencia + Exportar**  
   ![Historial de Asistencia](docs/img/mockups/historial_asistencia.png)

7. **Tardanzas (estadísticas)**  
   ![Tardanzas](docs/img/mockups/tardanzas.png)




## Diagrama de Clases (ER)

![Modelo ER](docs/img/erd.png)

**Resumen:**  
- **companies** define parámetros globales de la empresa (horarios base, ventanas de almuerzo).  
- **profiles** representa la cuenta de usuario (rol admin/employee) y su empresa.  
- **employees** modela al trabajador; puede enlazarse a un **profile** si usa login.  
- **attendance_records** guarda cada marca (entrada/salida/almuerzo) con hora y ubicación.  
- **geofences** define zonas válidas por empresa (centro + radio en metros).  
- **notifications** almacena avisos para empleados o generales por empresa.

**Índices/Reglas sugeridas:**  
- `employees (company_id, dni) UNIQUE`  
- `attendance_records (employee_id, record_date)` INDEX  
- Validar lat/lon obligatorios para marcas desde móvil; permitir NULL si se carga manualmente por admin.

## Enlace al repositorio

> https://github.com/RodrigoAGA/asistControl
