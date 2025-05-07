#include <GUIConstantsEx.au3>  ; Para crear la interfaz gráfica
#include <WindowsConstants.au3>  ; Constantes de Windows
#include <Date.au3>              ; Funciones para manejo de fechas/horas
#include <StaticConstants.au3>   ; Constantes para controles estáticos
#include <MsgBoxConstants.au3>   ; Constantes para cuadros de mensaje
#include <Clipboard.au3>         ; Funciones para manejar el portapapeles
#include <EditConstants.au3>     ; Constantes para controles de edición

; Configuración inicial de la aplicación
Global $tituloVentana = "ADBAppKiller"  ; Título de la ventana
Global $ancho = 400       ; Ancho de la ventana
Global $alto = 280        ; Alto de la ventana (aumentado para el botón)
Global $hGUI, $labelPaquete, $labelNombreAmigable, $editDetalles, $labelHora, $linkRider, $labelEstado, $btnKillApp  ; Variables para controles GUI
Global $listaApps = ObjCreate("Scripting.Dictionary")  ; Diccionario para almacenar apps (no se usa actualmente)

; Paleta de colores para la interfaz
Global $colorFondo = 0x1A2A3A         ; Color de fondo oscuro
Global $colorTexto = 0xE0E0E0         ; Color de texto principal
Global $colorDestacado = 0x4A9FF5     ; Color para elementos destacados
Global $colorSecundario = 0x7FDBFF    ; Color secundario
Global $colorError = 0xFF6B6B         ; Color para mensajes de error
Global $colorLink = 0x7FDBFF          ; Color para enlaces
Global $colorConectado = 0x2ECC40     ; Color para estado "Conectado"
Global $colorDesconectado = 0xFF6B6B  ; Color para estado "Desconectado"
Global $colorAdvertencia = 0xFFDC00   ; Color para advertencias
Global $colorBoton = 0xFF4136         ; Color rojo para el botón de desinstalar

; ========================================================
; Función: VerificarADBInstalado
; Propósito: Comprueba si ADB está instalado en rutas comunes
; Retorna: Ruta al ejecutable ADB si se encuentra
; ========================================================
Func VerificarADBInstalado()
    ; Rutas comunes donde ADB podría estar instalado (ahora incluyendo C:\adb\)
    Local $adbPaths[5] = [ _
        "C:\adb\adb.exe", _                     ; Nueva ruta agregada aquí
        @ProgramFilesDir & "\Android\android-sdk\platform-tools\adb.exe", _
        @LocalAppDataDir & "\Android\android-sdk\platform-tools\adb.exe", _
        @SystemDir & "\adb.exe", _
        "adb.exe" _
    ]
    
    ; Buscar ADB en las rutas especificadas
    For $path In $adbPaths
        If FileExists($path) Then Return $path
    Next
    
    ; Si no se encuentra ADB, mostrar mensaje de error y salir
    MsgBox($MB_ICONERROR + $MB_OK, "Error ADB", "ADB no encontrado." & @CRLF & @CRLF & _
          "Descargar ADB (Android SDK Platform-Tools) de:" & @CRLF & _
          "https://developer.android.com/studio/releases/platform-tools" & @CRLF & @CRLF & _
          "Instalar en el directorio: C:\adb" & @CRLF & _
          "y agregar esta ruta a la variable de entorno PATH.")
    Exit
EndFunc

; ========================================================
; Función: VerificarConexionADB
; Propósito: Verifica si hay un dispositivo Android conectado
; Retorna: True si hay dispositivo conectado, False en caso contrario
; ========================================================
Func VerificarConexionADB()
    ; Ejecutar comando para listar dispositivos conectados
    Local $adbCheck = Run('adb devices', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($adbCheck, 2)
    Local $output = StdoutRead($adbCheck)
    ; Buscar en la salida si hay un dispositivo conectado
    Return StringRegExp($output, "\w+\tdevice", 0) > 0
EndFunc

; ========================================================
; Función: CrearInterfaz
; Propósito: Crea y configura la interfaz gráfica de usuario
; ========================================================
Func CrearInterfaz()
    ; Crear ventana principal
    $hGUI = GUICreate($tituloVentana, $ancho, $alto, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_TOPMOST)
    GUISetBkColor($colorFondo)  ; Establecer color de fondo
    GUISetFont(9, 400, 0, "Segoe UI")  ; Establecer fuente

    ; Etiqueta para mostrar estado de conexión
    $labelEstado = GUICtrlCreateLabel("Estado: Verificando...", 10, 10, $ancho - 20, 20)
    GUICtrlSetColor(-1, $colorTexto)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Etiqueta principal para mostrar el paquete de la app
    $labelPaquete = GUICtrlCreateLabel("Esperando dispositivo...", 10, 35, $ancho - 20, 24, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 600)  ; Texto en negrita
    GUICtrlSetColor(-1, $colorDestacado)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Etiqueta para mostrar el nombre amigable de la app
    $labelNombreAmigable = GUICtrlCreateLabel("", 10, 60, $ancho - 20, 18, $SS_CENTER)
    GUICtrlSetColor(-1, $colorSecundario)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Área de texto para mostrar detalles de la app
    $editDetalles = GUICtrlCreateEdit("", 10, 85, $ancho - 20, 120, BitOR($ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
    GUICtrlSetColor(-1, $colorTexto)
    GUICtrlSetBkColor(-1, 0x2A3A4A)  ; Fondo más oscuro para el área de detalles
    GUICtrlSetFont(-1, 9, 400, 0, "Consolas")  ; Fuente monoespaciada

    ; Botón para desinstalar la aplicación
    $btnKillApp = GUICtrlCreateButton("AppKiller", 10, $alto - 60, $ancho - 20, 25)
    GUICtrlSetColor(-1, 0xFFFFFF)
    GUICtrlSetBkColor(-1, $colorBoton)
    GUICtrlSetFont(-1, 10, 600)
    GUICtrlSetTip(-1, "Desinstalar la aplicación mostrada (excepto apps de sistema)")

    ; Etiqueta para mostrar hora de última actualización
    $labelHora = GUICtrlCreateLabel("", 10, $alto - 30, $ancho - 120, 20)
    GUICtrlSetColor(-1, $colorSecundario)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Enlace "By: Rider" (créditos del desarrollador)
    $linkRider = GUICtrlCreateLabel("Rider", $ancho - 100, $alto - 30, 90, 20)
    GUICtrlSetColor(-1, $colorLink)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetCursor(-1, 0)  ; Cambiar cursor a mano al pasar sobre el enlace
    GUICtrlSetTip(-1, "Visitar ridersoportetecnico.blogspot.com")  ; Tooltip

    ; Mostrar la ventana
    GUISetState(@SW_SHOW)
EndFunc

; ========================================================
; Función: ObtenerInfoInstalacion
; Propósito: Obtiene información detallada de una aplicación Android
; Parámetros: $paquete - Nombre del paquete de la aplicación
; Retorna: String con la información formateada
; ========================================================
Func ObtenerInfoInstalacion($paquete)
    If $paquete = "" Then Return "No se pudo obtener información de la aplicación"
    
    ; Ejecutar comando ADB para obtener información del paquete
    Local $installInfo = Run('adb shell "dumpsys package ' & $paquete & '"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($installInfo, 3)
    Local $output = StdoutRead($installInfo)
    
    ; Extraer información
    Local $firstInstall = StringRegExp($output, "firstInstallTime=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})", 1)
    Local $lastUpdate = StringRegExp($output, "lastUpdateTime=(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})", 1)
    Local $version = StringRegExp($output, "versionName=([^\s]+)", 1)
    Local $appName = StringRegExp($output, "applicationInfo labelRes=.*?label='(.*?)'", 1)
    Local $uid = StringRegExpReplace($output, "(?s).*userId=(\d+).*", "$1")
    Local $path = StringRegExpReplace($output, "(?s).*codePath=(.*?)\s.*", "$1")
    Local $isSystemApp = StringInStr($output, 'flags=[^"]*SYSTEM[^"]*')
    
    ; Actualizar nombre amigable en la interfaz (si existe)
    If IsArray($appName) Then
        GUICtrlSetData($labelNombreAmigable, $appName[0])
    Else
        GUICtrlSetData($labelNombreAmigable, "")
    EndIf
    
    ; Construir la información **sin la línea del nombre si es N/A**
    Local $info = "INFORMACIÓN DE LA APLICACIÓN" & @CRLF & _
                  "--------------------------" & @CRLF
    
    ; **Solo agregar "- Nombre: X" si existe un nombre válido**
    If IsArray($appName) And $appName[0] <> "" Then
        $info &= "- Nombre: " & $appName[0] & @CRLF
    EndIf
    
    ; Agregar información sobre si es app de sistema
    $info &= "- Tipo: " & ($isSystemApp ? "SISTEMA (no se puede desinstalar)" : "USUARIO (se puede desinstalar)") & @CRLF
    
    ; Continuar con el resto de la información
    $info &= "- Paquete: " & $paquete & @CRLF & _
             "- Versión: " & (IsArray($version) ? $version[0] : "N/A") & @CRLF & @CRLF & _
             "FECHAS" & @CRLF & _
             "------" & @CRLF & _
             "- Instalación: " & (IsArray($firstInstall) ? $firstInstall[0] : "N/A") & @CRLF & _
             "- Última actualización: " & (IsArray($lastUpdate) ? $lastUpdate[0] : "N/A") & @CRLF & @CRLF & _
             "DETALLES" & @CRLF & _
             "-----------------" & @CRLF & _
             "- UID: " & ($uid <> $output ? $uid : "N/A") & @CRLF & _
             "- Ruta: " & ($path <> $output ? $path : "N/A")
    
    Return $info
EndFunc

; ========================================================
; Función: _GetForegroundApp
; Propósito: Detecta qué aplicación está en primer plano en el dispositivo Android
; Retorna: Nombre del paquete de la aplicación en primer plano
; ========================================================
Func _GetForegroundApp()
    ; Método 1: Usando dumpsys activity (más confiable)
    Local $activity = Run('adb shell "dumpsys activity activities | grep mResumedActivity"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($activity, 2)
    Local $output = StdoutRead($activity)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; Método 2: Alternativo usando dumpsys window (segunda opción)
    Local $window = Run('adb shell "dumpsys window windows | grep mCurrentFocus"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($window, 2)
    $output = StdoutRead($window)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; Método 3: Alternativa adicional (tercera opción)
    Local $window2 = Run('adb shell "dumpsys window | grep mFocusedApp"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($window2, 2)
    $output = StdoutRead($window2)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; Si ningún método funciona, retornar error
    Return SetError(1, 0, "")
EndFunc

; ========================================================
; Función: _CopiarTodo
; Propósito: Copia toda la información mostrada al portapapeles
; ========================================================
Func _CopiarTodo()
    ; Concatenar toda la información visible
    Local $textoCompleto = GUICtrlRead($labelPaquete) & @CRLF & _
                         GUICtrlRead($labelNombreAmigable) & @CRLF & _
                         GUICtrlRead($editDetalles)
    ClipPut($textoCompleto)  ; Copiar al portapapeles
    ; Mostrar confirmación con hora
    GUICtrlSetData($labelHora, "Copiado: " & _NowTime(5))
EndFunc

; ========================================================
; Función: _AbrirBlogRider
; Propósito: Abre el blog del desarrollador en el navegador
; ========================================================
Func _AbrirBlogRider()
    ShellExecute("https://ridersoportetecnico.blogspot.com/")
EndFunc

; ========================================================
; Función: _TerminarProcesosADB
; Propósito: Detiene el servidor ADB al cerrar la aplicación
; ========================================================
Func _TerminarProcesosADB()
    Run('adb kill-server', "", @SW_HIDE)
EndFunc

; ========================================================
; Función: _DesinstalarApp
; Propósito: Desinstala la aplicación mostrada actualmente
; ========================================================
Func _DesinstalarApp()
    Local $paquete = GUICtrlRead($labelPaquete)
    
    ; Verificar si hay un paquete válido
    If $paquete = "" Or $paquete = "Esperando dispositivo..." Or $paquete = "Dispositivo desconectado" Or $paquete = "No se detectó aplicación" Then
        MsgBox($MB_ICONWARNING + $MB_OK + $MB_TOPMOST, "Advertencia", "No hay una aplicación válida seleccionada para desinstalar.")
        Return
    EndIf
    
    ; Verificar si es una aplicación de sistema
    Local $installInfo = Run('adb shell "dumpsys package ' & $paquete & '"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($installInfo, 3)
    Local $output = StdoutRead($installInfo)
    Local $isSystemApp = StringInStr($output, 'flags=[^"]*SYSTEM[^"]*')
    
    If $isSystemApp Then
        MsgBox($MB_ICONERROR + $MB_OK + $MB_TOPMOST, "Error", "No se puede desinstalar una aplicación de sistema: " & $paquete)
        Return
    EndIf
    
    ; Confirmar con el usuario antes de desinstalar
    Local $respuesta = MsgBox($MB_ICONQUESTION + $MB_YESNO + $MB_TOPMOST, "Confirmar", "¿Está seguro que desea desinstalar la aplicación: " & $paquete & "?")
    
    If $respuesta = $IDYES Then
        ; Ejecutar comando para desinstalar
        Local $resultado = Run('adb uninstall ' & $paquete, "", @SW_HIDE, $STDERR_MERGED)
        ProcessWaitClose($resultado, 5)
        Local $salida = StdoutRead($resultado)
        
        If StringInStr($salida, "Success") Then
            MsgBox($MB_ICONINFORMATION + $MB_OK + $MB_TOPMOST, "Éxito", "Aplicación desinstalada correctamente: " & $paquete)
            GUICtrlSetData($labelPaquete, "Aplicación desinstalada")
            GUICtrlSetData($editDetalles, "La aplicación " & $paquete & " fue desinstalada correctamente.")
        Else
            MsgBox($MB_ICONERROR + $MB_OK + $MB_TOPMOST, "Error", "No se pudo desinstalar la aplicación: " & $paquete & @CRLF & @CRLF & "Error: " & $salida)
        EndIf
    EndIf
EndFunc

; ========================================================
; Función: ActualizarEstadoConexion
; Propósito: Actualiza el estado de conexión en la interfaz
; Retorna: Estado actual de la conexión (True/False)
; ========================================================
Func ActualizarEstadoConexion()
    Static $ultimoEstado = -1  ; Para detectar cambios de estado
    Local $conectado = VerificarConexionADB()
    
    ; Solo actualizar si el estado cambió
    If $conectado <> $ultimoEstado Then
        If $conectado Then
            ; Estado conectado
            GUICtrlSetData($labelEstado, "Estado: Conectado")
            GUICtrlSetColor($labelEstado, $colorConectado)
            GUICtrlSetData($labelPaquete, "Analizando aplicación...")
            GUICtrlSetColor($labelPaquete, $colorDestacado)
            GUICtrlSetData($editDetalles, "Buscando aplicación en primer plano...")
        Else
            ; Estado desconectado
            GUICtrlSetData($labelEstado, "Estado: Desconectado")
            GUICtrlSetColor($labelEstado, $colorDesconectado)
            GUICtrlSetData($labelPaquete, "Dispositivo desconectado")
            GUICtrlSetColor($labelPaquete, $colorError)
            GUICtrlSetData($editDetalles, "Conecte un dispositivo Android via USB y active la depuración USB")
        EndIf
        $ultimoEstado = $conectado
    EndIf
    
    Return $conectado
EndFunc

; ========================================================
; Función: Main
; Propósito: Función principal que maneja el flujo del programa
; ========================================================
Func Main()
    ; Verificar requisitos y crear interfaz
    VerificarADBInstalado()
    CrearInterfaz()
    
    ; Variables para control de tiempos
    Local $timerActualizacion = TimerInit()  ; Para actualización de información
    Local $timerConexion = TimerInit()       ; Para verificación de conexión
    Local $running = True                    ; Control del bucle principal
    Local $sleepTime = 100                   ; Tiempo de espera entre iteraciones
    Local $ultimaApp = ""                    ; Para detectar cambios de aplicación
    
    ; Bucle principal del programa
    While $running
        ; Manejar eventos de la interfaz
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ; Cerrar la aplicación limpiamente
                _TerminarProcesosADB()
                $running = False
                ExitLoop
                
            Case $GUI_EVENT_SECONDARYDOWN
                ; Copiar al portapapeles con clic derecho
                _CopiarTodo()
                
            Case $linkRider
                ; Abrir blog al hacer clic en el enlace
                _AbrirBlogRider()
                
            Case $btnKillApp
                ; Desinstalar la aplicación actual
                _DesinstalarApp()
        EndSwitch

        ; Verificar conexión periódicamente (cada 500ms)
        If TimerDiff($timerConexion) > 500 Then
            ActualizarEstadoConexion()
            $timerConexion = TimerInit()
        EndIf

        ; Actualizar información de la app (cada 1000ms si está conectado)
        If TimerDiff($timerActualizacion) > 1000 Then
            If ActualizarEstadoConexion() Then
                Local $app = _GetForegroundApp()
                
                If @error Then
                    ; No se pudo detectar la aplicación
                    GUICtrlSetData($labelPaquete, "No se detectó aplicación")
                    GUICtrlSetColor($labelPaquete, $colorAdvertencia)
                    GUICtrlSetData($editDetalles, "Intente abrir una aplicación en el dispositivo")
                ElseIf $app <> "" And $app <> $ultimaApp Then
                    ; Nueva aplicación detectada
                    GUICtrlSetData($labelPaquete, $app)
                    GUICtrlSetColor($labelPaquete, $colorDestacado)
                    GUICtrlSetData($editDetalles, ObtenerInfoInstalacion($app))
                    $ultimaApp = $app
                EndIf
            EndIf
            
            ; Actualizar marca de tiempo
            GUICtrlSetData($labelHora, "Actualizado: " & _NowTime(5))
            $timerActualizacion = TimerInit()
        EndIf
        
        ; Pequeña pausa para no saturar la CPU
        Sleep($sleepTime)
    WEnd
    
    ; Limpieza al salir
    _TerminarProcesosADB()
    GUIDelete($hGUI)
    Exit
EndFunc

; Iniciar la aplicación
Main()