# FJSS — integración funcional v0.3

Esta versión continúa sobre el launcher tv-detox original y conserva su gestión de paquetes, foco D-pad, menús de edición, detección de entradas y cambio de fuente.

## Incluido en v0.3
- Cabecera FJSS con reloj y fecha en vivo.
- Navegación superior funcional: Inicio vuelve al inicio de la página, Apps abre el selector de aplicaciones y Ajustes abre los ajustes del launcher.
- Cinco aplicaciones prioritarias en el orden definido en `apps.txt`; las no instaladas se omiten.
- Segunda fila fija de cinco accesos con nombre: Xbox, PlayStation 5, TV, Soundbar y Ajustes.
- Xbox y PlayStation 5 buscan una entrada de TV cuyo nombre coincida; si no la encuentran, permiten elegir entre las entradas HDMI reales disponibles. TV abre una entrada no asignada a consola o la aplicación Live TV disponible. Soundbar abre el panel de sonido del televisor.
- Conserva el menú de administración de apps y el soporte D-pad del proyecto original.
- Estanterías reales: consulta `PreviewPrograms` y `WatchNextPrograms` del proveedor Android TV. Solo muestra títulos, descripciones, pósteres e intents publicados por las aplicaciones; máximo tres elementos por servicio. No incluye títulos de relleno ni usa un catálogo inventado.
- Solicita el permiso Android `READ_TV_LISTINGS` para acceder a las recomendaciones compartidas con el sistema. Las imágenes HTTPS se cargan desde sus URL publicadas por las apps; también admite URI `content://` y `android.resource://`.
- Al seleccionar una tarjeta intenta abrir el `intent_uri` original publicado por la app. Si no hay intent válido, abre la aplicación de origen.
- Android solo permite leer las filas que el proveedor considera visibles para la app. Cada servicio decide si publica recomendaciones/Watch Next; por eso Netflix u otra app puede no aparecer aunque esté instalada. Si el usuario deniega `READ_TV_LISTINGS`, las estanterías no mostrarán resultados.
- Bodoni Moda y Montserrat todavía no están empaquetadas. La cabecera usa tipografías del sistema; la integración de archivos de fuente queda pendiente.
- El acceso Soundbar abre los ajustes de sonido del televisor; no puede garantizar el cambio de entrada de la barra si el fabricante no lo expone a Android TV.
- No se ha compilado un APK en este entorno: no está instalado Android SDK 34 / Build Tools 34.0.0. El workflow `.github/workflows/build.yml` puede compilarlo en GitHub Actions.
- Para actualizar la instalación existente, el APK debe conservar la misma clave de firma que la versión instalada. No regeneres `key.jks`; si la clave no está disponible en el repositorio o en los secretos de GitHub, instala primero como prueba sin reemplazar el launcher actual.

## Compilación
Con Java 17 y Android SDK platform 34 / build-tools 34.0.0: `sh build.sh`. El resultado se genera en `out/tvhome.apk`.

## Tipografías FJSS

- Montserrat Regular y SemiBold están incluidas en `assets/fonts/` y se cargan desde el APK.
- Bodoni Moda está configurada para cargarse desde `assets/fonts/BodoniModa.ttf`. El archivo oficial no estaba disponible en el paquete fuente ni en el entorno sin conexión usado para esta revisión; mientras no se incorpore, Android usa su serif del sistema como fallback. No se debe considerar esto la tipografía final aprobada.
- Las fuentes Montserrat se distribuyen bajo SIL Open Font License 1.1; se incluye la licencia en `assets/fonts/OFL-1.1.txt`.
## Fondo FJSS aprobado

La pantalla principal usa `assets/fjss-background.jpg`: fondo fijo azul medianoche casi negro, con estrellas tenues. No hay nebulosa animada ni efectos dinámicos. El fondo se carga localmente desde el APK y no requiere conexión.


## HOME predeterminado en TCL Android 9 (v1.5.11)
- El servicio de accesibilidad HomeButton ahora reconoce también la actividad HOME observada en TCL: `com.google.android.tvlauncher/.MainActivity`.
- Si Android mantiene el launcher del fabricante como HOME preferido, al habilitar el servicio Home button en Accesibilidad, FJSS se abre encima cuando el launcher TCL aparece.
- No deshabilita ni elimina el launcher de fábrica. Para volver al comportamiento original, desactivar el servicio Home button en Accesibilidad o desinstalar FJSS.

\n## Corrección TCL TV (v1.5.12)\n
- El botón TV abre `com.tcl.tv/.TVActivity` con `ACTION_VIEW` y el URI `content://android.media.tv/passthrough/` más el ID completo `com.tcl.tvinput/.TDTVInputService/HW1413742848` codificado.
- Esta llamada exacta fue probada desde ADB en el TCL objetivo y abrió el sintonizador de canales. El ID corresponde al hardware de ese televisor; otros modelos TCL pueden requerir un ID distinto.


## HOME priority test (v1.5.13)
- Se incrementa a 100 la prioridad del intent-filter MAIN/HOME de FJSS (Google TV/TCL observado: prioridad 2).
- No se modifica ni desactiva el launcher TCL. Es una prueba de resolución HOME; el fabricante puede seguir imponiendo su launcher.
- Para actualizar la instalación existente, el APK debe firmarse con la misma clave que la versión instalada.
