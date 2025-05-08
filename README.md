[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AutoIt Version](https://img.shields.io/badge/AutoIt-v3.3.14.5+-green.svg)](https://www.autoitscript.com)
[![Platform](https://img.shields.io/badge/Platform-Windows%20|%20ADB%20Device-lightgrey.svg)]()

**ADBAppKiller** es una herramienta para la gestión de aplicaciones Android a través de ADB.

![Interfaz](src/assets/screenshot.png)

## 🌟 Características Principales
- 🔍 Detección en tiempo real de la aplicación en primer plano.
- 📊 Extracción completa de metadatos (versión, UID, rutas).
- 🗑️ Desinstalación segura de aplicaciones de usuario.
- 🛡️ Protección contra la eliminación de aplicaciones del sistema.
- 📋 Copiado automático de información al portapapeles.

## 📋 Requisitos del Sistema

| Componente       | Versión Mínima       |
|------------------|----------------------|
| Windows          | 7 SP1 (x64)          |
| AutoIt           | 3.3.14.5             |
| ADB              | 33.0.3               |
| Android API      | 26 (8.0 Oreo)        |

## 🚀 Instalación Rápida

1. **Prerrequisitos**:
   - [Android Platform-Tools](https://developer.android.com/studio/releases/platform-tools)
   - [AutoIt v3.3.14.5+](https://www.autoitscript.com/site/autoit/downloads)

2. **Ejecución**:
   ```bash
   # 1. Instalar dependencias (Windows)
   choco install autoit adb -y

   # 2. Clonar el repositorio
   git clone https://github.com/RiderCalcina/ADBAppKiller.git

   # 3. Ejecutar la aplicación
   cd ADBAppKiller
   autoit3 src/ADBAppKiller.au3
