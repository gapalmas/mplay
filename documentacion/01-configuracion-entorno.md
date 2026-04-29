# Configuración del Entorno de Desarrollo — mplay

**Plataforma objetivo:** Android (compatible con iOS)  
**Lenguaje:** Dart  
**Framework:** Flutter  
**IDE:** Visual Studio Code  
**OS de desarrollo:** Windows 11 Pro 64-bit (Build 26200)  
**Fecha:** Abril 2026

---

## Estado del entorno (resultado final)

| Herramienta | Estado | Versión / Ruta |
|---|---|---|
| Git | ✅ | `C:\Program Files\Git` |
| Flutter SDK | ✅ | 3.41.8 stable → `%USERPROFILE%\develop\flutter` |
| Dart SDK | ✅ | 3.11.5 (incluido con Flutter) |
| Android Studio | ✅ | 2025.3.4.6 → `C:\Program Files\Android\Android Studio` |
| Android SDK | ✅ | 36.1.0 → `%LOCALAPPDATA%\Android\Sdk` |
| Android cmdline-tools | ✅ | instalado desde SDK Manager |
| ANDROID_HOME | ✅ | `%LOCALAPPDATA%\Android\Sdk` |
| VS Code ext. Flutter | ✅ | `dart-code.flutter` |
| VS Code ext. Dart | ✅ | `dart-code.dart-code` |
| Visual Studio (C++) | ⚠️ no requerido | Solo necesario para target Windows Desktop |

---

## Paso 1 — Instalar Flutter SDK

### Versión instalada

**Flutter 3.41.8** (stable) — Abril 2026

Descarga directa:
```
https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.8-stable.zip
```

### 1.1 Crear directorio de instalación

Crear el directorio destino (sin espacios ni caracteres especiales, sin necesitar privilegios elevados):

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\develop"
```

Ruta resultante: `C:\Users\gapalma\develop`

> ⚠️ **No** instalar en `C:\Program Files\` ni en rutas con espacios.

### 1.2 Descargar el SDK

```powershell
curl.exe -L --progress-bar `
  -o "$env:USERPROFILE\Downloads\flutter_windows_3.41.8-stable.zip" `
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.8-stable.zip"
```

### 1.3 Extraer el SDK

```powershell
Expand-Archive `
  -Path "$env:USERPROFILE\Downloads\flutter_windows_3.41.8-stable.zip" `
  -Destination "$env:USERPROFILE\develop\"
```

Ruta final del SDK: `C:\Users\gapalma\develop\flutter`

> ⚠️ Si falta `flutter.bat` en la carpeta `bin` tras la extracción, el antivirus pudo haberlo puesto en cuarentena.
> Configura el antivirus para que confíe en `%USERPROFILE%\develop\flutter` y extrae de nuevo.

### 1.4 Agregar Flutter al PATH

1. Presionar **Windows + Pause** → se abre *Sistema > Acerca de*.
2. Clic en **Configuración avanzada del sistema → Opciones avanzadas → Variables de entorno…**
3. En **Variables de usuario**, seleccionar `Path` → **Editar**.
4. Clic en una fila vacía y escribir:
   ```
   %USERPROFILE%\develop\flutter\bin
   ```
5. Seleccionar la entrada recién agregada y pulsar **Subir** hasta que quede al inicio de la lista.
6. Aceptar en los tres diálogos abiertos.
7. **Cerrar y reabrir** todas las terminales e IDEs para que el cambio tome efecto.

### 1.5 Verificar instalación

```powershell
flutter --version
dart --version
```

Salida esperada:
```
Flutter 3.41.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision xxxxxxxx
Engine • revision xxxxxxxx
Tools • Dart 3.x.x • DevTools x.x.x
```

---

## Paso 2 — Instalar Android Studio

Flutter para Android requiere el Android SDK y las herramientas de compilación.

### 2.1 Instalar via winget

```powershell
winget install --id Google.AndroidStudio --accept-source-agreements --accept-package-agreements
```

Versiones disponibles en winget: `Google.AndroidStudio` (stable), `Google.AndroidStudio.Beta`, `Google.AndroidStudio.Canary`.

Ruta de instalación: `C:\Program Files\Android\Android Studio`

### 2.2 Primer lanzamiento — instalar Android SDK

Al abrir Android Studio por primera vez se ejecuta el asistente de configuración:

1. **Do not import settings** → OK
2. Tipo de instalación → **Standard** → Next
3. Tema de UI → el que prefieras → Next
4. **Verify Settings** → Finish
5. Esperar que descargue los componentes del SDK (~1-2 GB)

Ruta del SDK instalado: `%LOCALAPPDATA%\Android\Sdk`

### 2.3 Instalar Android SDK Command-line Tools

Requerido por `flutter doctor --android-licenses`. Instalar desde el SDK Manager:

1. Android Studio → **More Actions** → **SDK Manager**
2. Pestaña **SDK Tools**
3. Marcar **Android SDK Command-line Tools (latest)**
4. **Apply** → OK

### 2.4 Configurar variables de entorno

```powershell
# ANDROID_HOME
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")

# Agregar platform-tools y emulator al PATH
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
$currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("Path", "$sdk\platform-tools;$sdk\emulator;$currentPath", "User")

# Informar a Flutter la ruta del SDK
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
```

### 2.5 Aceptar licencias de Android

```powershell
flutter doctor --android-licenses
```

Responder `y` + Enter a cada licencia presentada.

---

## Paso 3 — Java Development Kit (JDK)

Android Studio 2025.x incluye su propio **JDK 21 embebido** — no es necesario instalar Java por separado. `flutter doctor` reconoce el JDK de Android Studio automáticamente.

> Si en algún momento `flutter doctor` reporta problemas con Java, instalar **JDK 17** desde https://adoptium.net/ (Eclipse Temurin 17 LTS) y habilitar la opción **"Set JAVA_HOME variable"** en el instalador.

---

## Paso 4 — Extensiones de VS Code

Instalar las siguientes extensiones desde el Marketplace de VS Code:

| Extensión | ID | Propósito |
|---|---|---|
| Flutter | `Dart-Code.flutter` | Soporte completo Flutter + Dart |
| Dart | `Dart-Code.dart-code` | Incluida automáticamente con Flutter |

Instalación por línea de comandos (opcional):
```powershell
code --install-extension Dart-Code.flutter
```

### Configuración recomendada de VS Code

Agregar en `settings.json` (Ctrl+Shift+P → "Open User Settings JSON"):

```json
{
  "dart.flutterSdkPath": "C:\\Users\\gapalma\\develop\\flutter",
  "editor.formatOnSave": true,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code",
    "editor.formatOnSave": true,
    "editor.rulers": [80]
  }
}
```

---

## Paso 5 — Verificación completa con flutter doctor

Una vez completados los pasos anteriores, ejecutar:

```powershell
flutter doctor -v
```

Todos los ítems deben mostrar ✅. Los únicos que pueden quedar en amarillo sin afectar el desarrollo son:
- `Chrome` (solo necesario para Flutter Web)
- `Visual Studio` (solo necesario para Flutter Windows Desktop)

Salida esperada mínima para desarrollo Android:

```
[✓] Flutter (Channel stable, ...)
[✓] Windows Version
[✓] Android toolchain - develop for Android devices
[✓] Android Studio
[✓] VS Code (version ...)
[✓] Connected device
```

---

## Paso 6 — Configurar dispositivo Android físico (opcional pero recomendado)

Para depurar en dispositivo real:

1. En el dispositivo Android: **Ajustes → Acerca del teléfono** → tocar **Número de compilación** 7 veces (activa modo desarrollador).
2. Ir a **Ajustes → Opciones de desarrollador** → activar **Depuración USB**.
3. Conectar el dispositivo por USB.
4. Verificar que es detectado:

```powershell
flutter devices
```

---

## Paso 7 — Inicializar el proyecto

Una vez el entorno esté configurado, crear el proyecto Flutter en el directorio `src/`:

```powershell
cd "c:\Users\gapalma\Documents\Source\mplay\src"
flutter create --org com.mplay --platforms android,ios mplay
```

Estructura generada:

```
src/mplay/
├── android/          ← configuración Android
├── ios/              ← configuración iOS
├── lib/
│   └── main.dart     ← punto de entrada de la app
├── test/
├── pubspec.yaml      ← dependencias
└── analysis_options.yaml
```

---

## Referencias

- Flutter install (Windows): https://docs.flutter.dev/get-started/install/windows/mobile
- Android Studio: https://developer.android.com/studio
- JDK 17 (Adoptium): https://adoptium.net/
- Flutter VSCode extension: https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter
