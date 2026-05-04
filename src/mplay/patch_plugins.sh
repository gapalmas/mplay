#!/bin/bash
# patch_plugins.sh
# Aplica los parches necesarios a plugins de Flutter que no son compatibles con
# las versiones actuales de Android Gradle Plugin (AGP).
#
# Ejecutar desde la raíz del proyecto Flutter (src/mplay) después de flutter pub get:
#   ./patch_plugins.sh
#
# Problemas solucionados:
#   - on_audio_query_android 1.1.0: falta 'namespace' requerido por AGP 8.x
#   - on_audio_query_android 1.1.0: Java 1.8 vs Kotlin 17 mismatch

set -e

PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/on_audio_query_android-1.1.0/android/build.gradle"

if [ ! -f "$PLUGIN_PATH" ]; then
    echo "Plugin on_audio_query_android-1.1.0 no encontrado. Ejecuta 'flutter pub get' primero."
    exit 1
fi

# Verificar si ya está parcheado
if grep -q "namespace 'com.lucasjosino.on_audio_query'" "$PLUGIN_PATH"; then
    echo "✓ Plugin ya está parcheado."
    exit 0
fi

# Parche 1: añadir namespace
sed -i "s/android {/android {\n    namespace 'com.lucasjosino.on_audio_query'/" "$PLUGIN_PATH"

# Parche 2: añadir compileOptions con Java 17
sed -i "/compileSdkVersion 33/a\\
\\
    compileOptions {\\
        sourceCompatibility JavaVersion.VERSION_17\\
        targetCompatibility JavaVersion.VERSION_17\\
    }" "$PLUGIN_PATH"

echo "✓ Plugin on_audio_query_android parcheado correctamente."
