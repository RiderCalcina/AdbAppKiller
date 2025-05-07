#include <GUIConstantsEx.au3>  ; Para crear la interfaz gr�fica
#include <WindowsConstants.au3>  ; Constantes de Windows
#include <Date.au3>              ; Funciones para manejo de fechas/horas
#include <StaticConstants.au3>   ; Constantes para controles est�ticos
#include <MsgBoxConstants.au3>   ; Constantes para cuadros de mensaje
#include <Clipboard.au3>         ; Funciones para manejar el portapapeles
#include <EditConstants.au3>     ; Constantes para controles de edici�n

; Configuraci�n inicial de la aplicaci�n
Global $tituloVentana = "ADBAppKiller"  ; T�tulo de la ventana
Global $ancho = 400       ; Ancho de la ventana
Global $alto = 280        ; Alto de la ventana (aumentado para el bot�n)
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
Global $colorBoton = 0xFF4136         ; Color rojo para el bot�n de desinstalar

; ========================================================
; Funci�n: VerificarADBInstalado
; Prop�sito: Comprueba si ADB est� instalado en rutas comunes
; Retorna: Ruta al ejecutable ADB si se encuentra
; ========================================================
Func VerificarADBInstalado()
    ; Rutas comunes donde ADB podr�a estar instalado (ahora incluyendo C:\adb\)
    Local $adbPaths[5] = [ _
        "C:\adb\adb.exe", _                     ; Nueva ruta agregada aqu�
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
; Funci�n: VerificarConexionADB
; Prop�sito: Verifica si hay un dispositivo Android conectado
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
; Funci�n: CrearInterfaz
; Prop�sito: Crea y configura la interfaz gr�fica de usuario
; ========================================================
Func CrearInterfaz()
    ; Crear ventana principal
    $hGUI = GUICreate($tituloVentana, $ancho, $alto, -1, -1, $WS_CAPTION + $WS_SYSMENU, $WS_EX_TOPMOST)
    GUISetBkColor($colorFondo)  ; Establecer color de fondo
    GUISetFont(9, 400, 0, "Segoe UI")  ; Establecer fuente

    ; Etiqueta para mostrar estado de conexi�n
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

    ; �rea de texto para mostrar detalles de la app
    $editDetalles = GUICtrlCreateEdit("", 10, 85, $ancho - 20, 120, BitOR($ES_READONLY, $ES_AUTOVSCROLL, $WS_VSCROLL))
    GUICtrlSetColor(-1, $colorTexto)
    GUICtrlSetBkColor(-1, 0x2A3A4A)  ; Fondo m�s oscuro para el �rea de detalles
    GUICtrlSetFont(-1, 9, 400, 0, "Consolas")  ; Fuente monoespaciada

    ; Bot�n para desinstalar la aplicaci�n
    $btnKillApp = GUICtrlCreateButton("AppKiller", 10, $alto - 60, $ancho - 20, 25)
    GUICtrlSetColor(-1, 0xFFFFFF)
    GUICtrlSetBkColor(-1, $colorBoton)
    GUICtrlSetFont(-1, 10, 600)
    GUICtrlSetTip(-1, "Desinstalar la aplicaci�n mostrada (excepto apps de sistema)")

    ; Etiqueta para mostrar hora de �ltima actualizaci�n
    $labelHora = GUICtrlCreateLabel("", 10, $alto - 30, $ancho - 120, 20)
    GUICtrlSetColor(-1, $colorSecundario)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

    ; Enlace "By: Rider" (cr�ditos del desarrollador)
    $linkRider = GUICtrlCreateLabel("Rider", $ancho - 100, $alto - 30, 90, 20)
    GUICtrlSetColor(-1, $colorLink)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetCursor(-1, 0)  ; Cambiar cursor a mano al pasar sobre el enlace
    GUICtrlSetTip(-1, "Visitar ridersoportetecnico.blogspot.com")  ; Tooltip

    ; Mostrar la ventana
    GUISetState(@SW_SHOW)
EndFunc

; ========================================================
; Funci�n: ObtenerInfoInstalacion
; Prop�sito: Obtiene informaci�n detallada de una aplicaci�n Android
; Par�metros: $paquete - Nombre del paquete de la aplicaci�n
; Retorna: String con la informaci�n formateada
; ========================================================
Func ObtenerInfoInstalacion($paquete)
    If $paquete = "" Then Return "No se pudo obtener informaci�n de la aplicaci�n"
    
    ; Ejecutar comando ADB para obtener informaci�n del paquete
    Local $installInfo = Run('adb shell "dumpsys package ' & $paquete & '"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($installInfo, 3)
    Local $output = StdoutRead($installInfo)
    
    ; Extraer informaci�n
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
    
    ; Construir la informaci�n **sin la l�nea del nombre si es N/A**
    Local $info = "INFORMACI�N DE LA APLICACI�N" & @CRLF & _
                  "--------------------------" & @CRLF
    
    ; **Solo agregar "- Nombre: X" si existe un nombre v�lido**
    If IsArray($appName) And $appName[0] <> "" Then
        $info &= "- Nombre: " & $appName[0] & @CRLF
    EndIf
    
    ; Agregar informaci�n sobre si es app de sistema
    $info &= "- Tipo: " & ($isSystemApp ? "SISTEMA (no se puede desinstalar)" : "USUARIO (se puede desinstalar)") & @CRLF
    
    ; Continuar con el resto de la informaci�n
    $info &= "- Paquete: " & $paquete & @CRLF & _
             "- Versi�n: " & (IsArray($version) ? $version[0] : "N/A") & @CRLF & @CRLF & _
             "FECHAS" & @CRLF & _
             "------" & @CRLF & _
             "- Instalaci�n: " & (IsArray($firstInstall) ? $firstInstall[0] : "N/A") & @CRLF & _
             "- �ltima actualizaci�n: " & (IsArray($lastUpdate) ? $lastUpdate[0] : "N/A") & @CRLF & @CRLF & _
             "DETALLES" & @CRLF & _
             "-----------------" & @CRLF & _
             "- UID: " & ($uid <> $output ? $uid : "N/A") & @CRLF & _
             "- Ruta: " & ($path <> $output ? $path : "N/A")
    
    Return $info
EndFunc

; ========================================================
; Funci�n: _GetForegroundApp
; Prop�sito: Detecta qu� aplicaci�n est� en primer plano en el dispositivo Android
; Retorna: Nombre del paquete de la aplicaci�n en primer plano
; ========================================================
Func _GetForegroundApp()
    ; M�todo 1: Usando dumpsys activity (m�s confiable)
    Local $activity = Run('adb shell "dumpsys activity activities | grep mResumedActivity"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($activity, 2)
    Local $output = StdoutRead($activity)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; M�todo 2: Alternativo usando dumpsys window (segunda opci�n)
    Local $window = Run('adb shell "dumpsys window windows | grep mCurrentFocus"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($window, 2)
    $output = StdoutRead($window)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; M�todo 3: Alternativa adicional (tercera opci�n)
    Local $window2 = Run('adb shell "dumpsys window | grep mFocusedApp"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($window2, 2)
    $output = StdoutRead($window2)
    
    If Not @error And $output <> "" Then
        Local $match = StringRegExp($output, '([a-zA-Z0-9._]+)/', 1)
        If IsArray($match) Then Return $match[0]
    EndIf
    
    ; Si ning�n m�todo funciona, retornar error
    Return SetError(1, 0, "")
EndFunc

; ========================================================
; Funci�n: _CopiarTodo
; Prop�sito: Copia toda la informaci�n mostrada al portapapeles
; ========================================================
Func _CopiarTodo()
    ; Concatenar toda la informaci�n visible
    Local $textoCompleto = GUICtrlRead($labelPaquete) & @CRLF & _
                         GUICtrlRead($labelNombreAmigable) & @CRLF & _
                         GUICtrlRead($editDetalles)
    ClipPut($textoCompleto)  ; Copiar al portapapeles
    ; Mostrar confirmaci�n con hora
    GUICtrlSetData($labelHora, "Copiado: " & _NowTime(5))
EndFunc

; ========================================================
; Funci�n: _AbrirBlogRider
; Prop�sito: Abre el blog del desarrollador en el navegador
; ========================================================
Func _AbrirBlogRider()
    ShellExecute("https://ridersoportetecnico.blogspot.com/")
EndFunc

; ========================================================
; Funci�n: _TerminarProcesosADB
; Prop�sito: Detiene el servidor ADB al cerrar la aplicaci�n
; ========================================================
Func _TerminarProcesosADB()
    Run('adb kill-server', "", @SW_HIDE)
EndFunc

; ========================================================
; Funci�n: _DesinstalarApp
; Prop�sito: Desinstala la aplicaci�n mostrada actualmente
; ========================================================
Func _DesinstalarApp()
    Local $paquete = GUICtrlRead($labelPaquete)
    
    ; Verificar si hay un paquete v�lido
    If $paquete = "" Or $paquete = "Esperando dispositivo..." Or $paquete = "Dispositivo desconectado" Or $paquete = "No se detect� aplicaci�n" Then
        MsgBox($MB_ICONWARNING + $MB_OK + $MB_TOPMOST, "Advertencia", "No hay una aplicaci�n v�lida seleccionada para desinstalar.")
        Return
    EndIf
    
    ; Verificar si es una aplicaci�n de sistema
    Local $installInfo = Run('adb shell "dumpsys package ' & $paquete & '"', "", @SW_HIDE, $STDERR_MERGED)
    ProcessWaitClose($installInfo, 3)
    Local $output = StdoutRead($installInfo)
    Local $isSystemApp = StringInStr($output, 'flags=[^"]*SYSTEM[^"]*')
    
    If $isSystemApp Then
        MsgBox($MB_ICONERROR + $MB_OK + $MB_TOPMOST, "Error", "No se puede desinstalar una aplicaci�n de sistema: " & $paquete)
        Return
    EndIf
    
    ; Confirmar con el usuario antes de desinstalar
    Local $respuesta = MsgBox($MB_ICONQUESTION + $MB_YESNO + $MB_TOPMOST, "Confirmar", "�Est� seguro que desea desinstalar la aplicaci�n: " & $paquete & "?")
    
    If $respuesta = $IDYES Then
        ; Ejecutar comando para desinstalar
        Local $resultado = Run('adb uninstall ' & $paquete, "", @SW_HIDE, $STDERR_MERGED)
        ProcessWaitClose($resultado, 5)
        Local $salida = StdoutRead($resultado)
        
        If StringInStr($salida, "Success") Then
            MsgBox($MB_ICONINFORMATION + $MB_OK + $MB_TOPMOST, "�xito", "Aplicaci�n desinstalada correctamente: " & $paquete)
            GUICtrlSetData($labelPaquete, "Aplicaci�n desinstalada")
            GUICtrlSetData($editDetalles, "La aplicaci�n " & $paquete & " fue desinstalada correctamente.")
        Else
            MsgBox($MB_ICONERROR + $MB_OK + $MB_TOPMOST, "Error", "No se pudo desinstalar la aplicaci�n: " & $paquete & @CRLF & @CRLF & "Error: " & $salida)
        EndIf
    EndIf
EndFunc

; ========================================================
; Funci�n: ActualizarEstadoConexion
; Prop�sito: Actualiza el estado de conexi�n en la interfaz
; Retorna: Estado actual de la conexi�n (True/False)
; ========================================================
Func ActualizarEstadoConexion()
    Static $ultimoEstado = -1  ; Para detectar cambios de estado
    Local $conectado = VerificarConexionADB()
    
    ; Solo actualizar si el estado cambi�
    If $conectado <> $ultimoEstado Then
        If $conectado Then
            ; Estado conectado
            GUICtrlSetData($labelEstado, "Estado: Conectado")
            GUICtrlSetColor($labelEstado, $colorConectado)
            GUICtrlSetData($labelPaquete, "Analizando aplicaci�n...")
            GUICtrlSetColor($labelPaquete, $colorDestacado)
            GUICtrlSetData($editDetalles, "Buscando aplicaci�n en primer plano...")
        Else
            ; Estado desconectado
            GUICtrlSetData($labelEstado, "Estado: Desconectado")
            GUICtrlSetColor($labelEstado, $colorDesconectado)
            GUICtrlSetData($labelPaquete, "Dispositivo desconectado")
            GUICtrlSetColor($labelPaquete, $colorError)
            GUICtrlSetData($editDetalles, "Conecte un dispositivo Android via USB y active la depuraci�n USB")
        EndIf
        $ultimoEstado = $conectado
    EndIf
    
    Return $conectado
EndFunc

; ========================================================
; Funci�n: Main
; Prop�sito: Funci�n principal que maneja el flujo del programa
; ========================================================
Func Main()
    ; Verificar requisitos y crear interfaz
    VerificarADBInstalado()
    CrearInterfaz()
    
    ; Variables para control de tiempos
    Local $timerActualizacion = TimerInit()  ; Para actualizaci�n de informaci�n
    Local $timerConexion = TimerInit()       ; Para verificaci�n de conexi�n
    Local $running = True                    ; Control del bucle principal
    Local $sleepTime = 100                   ; Tiempo de espera entre iteraciones
    Local $ultimaApp = ""                    ; Para detectar cambios de aplicaci�n
    
    ; Bucle principal del programa
    While $running
        ; Manejar eventos de la interfaz
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ; Cerrar la aplicaci�n limpiamente
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
                ; Desinstalar la aplicaci�n actual
                _DesinstalarApp()
        EndSwitch

        ; Verificar conexi�n peri�dicamente (cada 500ms)
        If TimerDiff($timerConexion) > 500 Then
            ActualizarEstadoConexion()
            $timerConexion = TimerInit()
        EndIf

        ; Actualizar informaci�n de la app (cada 1000ms si est� conectado)
        If TimerDiff($timerActualizacion) > 1000 Then
            If ActualizarEstadoConexion() Then
                Local $app = _GetForegroundApp()
                
                If @error Then
                    ; No se pudo detectar la aplicaci�n
                    GUICtrlSetData($labelPaquete, "No se detect� aplicaci�n")
                    GUICtrlSetColor($labelPaquete, $colorAdvertencia)
                    GUICtrlSetData($editDetalles, "Intente abrir una aplicaci�n en el dispositivo")
                ElseIf $app <> "" And $app <> $ultimaApp Then
                    ; Nueva aplicaci�n detectada
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
        
        ; Peque�a pausa para no saturar la CPU
        Sleep($sleepTime)
    WEnd
    
    ; Limpieza al salir
    _TerminarProcesosADB()
    GUIDelete($hGUI)
    Exit
EndFunc

; Iniciar la aplicaci�n
Main()