# 🛠️ TecrobSys - Sistema de Gestión de Taller Técnico (Flutter)

Sistema multiplataforma (Android, Web y Desktop) para la gestión técnica de talleres, control de órdenes de servicio, inventario, clientes, ventas e informes, desarrollado en **Flutter** con backend en **Supabase**.

---

## 📋 Requisitos del Sistema y Herramientas Necesarias

Para abrir, compilar y ejecutar este proyecto correctamente en tu entorno local, asegúrate de contar con las siguientes herramientas y versiones:

### 1. Entorno de Desarrollo y SDKs
| Herramienta | Versión Recomendada | Notas |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.24.x` o superior (Probado en `3.47.1`) | Canal `stable` |
| **Dart SDK** | `3.5.x` o superior (incluido en Flutter) | |
| **Java JDK** | `JDK 17` | Requerido por Gradle y Android |
| **Android SDK** | API Level `30`, `34` y `35` | Android SDK Command-line Tools |
| **Android Gradle Plugin (AGP)** | `8.11.1` | Configurado en el proyecto |
| **Kotlin** | `2.2.20` | Configurado en el proyecto |

### 2. Editor Recomendado: Visual Studio Code
- **Extensiones necesarias en VS Code:**
  - `Flutter` (`Dart-Code.flutter`)
  - `Dart` (`Dart-Code.dart-code`)

### 3. Navegadores (Para modo Web)
- **Google Chrome** o **Microsoft Edge**

---

## 🚀 Pasos para Abrir y Ejecutar el Proyecto

### Paso 1: Clonar el Repositorio
```bash
git clone https://github.com/Franck147/TECROB-FLUTTER.git
cd TECROB-FLUTTER
```

### Paso 2: Abrir en Visual Studio Code
Abre la carpeta del proyecto en VS Code:
```bash
code .
```

### Paso 3: Instalar las Dependencias
Ejecuta en la terminal de VS Code:
```bash
flutter pub get
```

### Paso 4: Configuración de Base de Datos (Supabase)
Las credenciales de Supabase están configuradas en `lib/core/constants/app_constants.dart`:
```dart
class AppConstants {
  static const String supabaseUrl = 'https://cgjzbwqoeyqtvnfspybg.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_4prX92nOSSbKaay8HMQuVw_5wynwwa3';
}
```

---

## 💻 Ejecución del Proyecto

### Opción A: Desde Visual Studio Code (Recomendado)
1. Abre el panel de depuración presionando **`Ctrl + Shift + D`** (o el ícono ▶️ en la barra lateral).
2. Selecciona tu entorno objetivo en el menú desplegable:
   - 🌐 **`TecrobSys (Chrome - Web)`** *(Recomendado para pruebas rápidas)*
   - 📱 **`TecrobSys (Android Emulator / Device)`**
   - 🌐 **`TecrobSys (Edge)`**
3. Presiona **`F5`** para iniciar en modo depuración con Hot Reload.

### Opción B: Desde la Terminal
```bash
# Ejecutar en Google Chrome
flutter run -d chrome

# Ejecutar en Emulador o Dispositivo Android conectado
flutter run -d android

# Ejecutar en Microsoft Edge
flutter run -d edge
```

---

## 📦 Compilación para Producción

### Generar APK de Android (Debug):
```bash
flutter build apk --debug
```
*El APK resultante se ubicará en:* `build/app/outputs/flutter-apk/app-debug.apk`

### Generar APK de Android (Release):
```bash
flutter build apk --release
```

### Generar Web (HTML/JS/CanvasKit):
```bash
flutter build web --release
```
