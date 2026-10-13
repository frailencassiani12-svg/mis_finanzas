# Mis Finanzas (Versión Local)

App de finanzas personales para Android con **inicio de sesión local**, múltiples perfiles, gráficos y tema adaptativo.

## Características

- Inicio de sesión con correo + contraseña (guardado en el dispositivo)
- El primer usuario se convierte en **Administrador**
- El administrador puede registrar otras personas (en el mismo teléfono)
- Cada usuario tiene sus **propias finanzas**
- Importar / Exportar respaldos en formato `mis-finanzas-respaldo-v1`
- Gráficos de gastos e ingresos por categoría
- Tema claro / oscuro automático
- Interfaz 100% en español
- **No necesita internet ni Firebase**

---

## Cómo generar el APK

### 1. Crear el proyecto Flutter

```bash
flutter create --org com.misfinanzas mis_finanzas_app
cd mis_finanzas_app
```

### 2. Copiar los archivos

- Copia todo el contenido de la carpeta `lib/` del ZIP dentro de la carpeta `lib/` del proyecto nuevo (reemplaza lo que haya).
- Reemplaza el archivo `pubspec.yaml` por el del ZIP.

### 3. Instalar dependencias y generar APK

```bash
flutter pub get
flutter build apk --release
```

El APK estará en:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Cómo usar la app

1. Al abrirla por primera vez → crea la **cuenta de administrador**
2. Inicia sesión
3. Ve al menú (⋮) → **Administrar usuarios** → registra a las otras personas
4. Cada persona inicia sesión con su correo y contraseña
5. Cada una verá solo sus propios movimientos y cuentas

**Nota:** Todos los usuarios comparten el mismo dispositivo (los datos se guardan localmente en el teléfono).
