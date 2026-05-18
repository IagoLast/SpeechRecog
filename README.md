# SpeechRecog

Grabadora y transcriptora de audio del sistema para macOS, viviendo en la barra
de menú. Hace de "man-in-the-middle" usando un **Process Tap** + **Aggregate
Device** de Core Audio (API moderna de macOS 14.2+): el audio sigue sonando
con normalidad por la salida de siempre y a la vez se graba a un `.m4a`. Al
parar la grabación, se lanza la transcripción y se genera un `.srt`.

Pensada para grabar reuniones / llamadas (Zoom, Meet, Slack huddles, FaceTime,
etc.) sin instalar drivers extras ni cambiar manualmente la salida.

## Cómo funciona

1. **Process tap global** — Se crea un `CATapDescription` que captura todo el
   audio de salida del sistema, **excluyendo el PID de la propia app** para no
   capturar sus propios sonidos de UI.
2. **Aggregate device privado** — Se crea con `AudioHardwareCreateAggregateDevice`
   teniendo como *main sub-device* la salida por defecto del sistema (auriculares,
   altavoces, lo que esté activo). El tap se añade como `kAudioAggregateDeviceTapListKey`.
   El dispositivo es privado (`kAudioAggregateDeviceIsPrivateKey = true`), así que
   no aparece en *Ajustes del sistema → Sonido*.
3. **IOProc + ExtAudioFile** — Un `AudioDeviceIOProc` recibe los buffers del tap
   y los escribe vía `ExtAudioFileWriteAsync` directamente a un `.m4a` (AAC).
4. **Transcripción** — Al detener, se cierra el fichero y se invoca el motor de
   transcripción configurado (WhisperKit por defecto, Apple Speech como opción)
   para escribir el `.srt` junto al `.m4a`.

Los archivos se guardan en `~/Documents/SpeechRecog/recording-<timestamp>.m4a`
y `.srt`.

## Requisitos

- macOS **14.2** o superior (la API de Process Taps llegó ahí).
- Xcode 15.2+ / Command Line Tools con Swift 5.9+.
- La primera vez que se inicia una grabación macOS pedirá permiso para grabar
  audio del sistema; hay que aceptarlo en *Ajustes → Privacidad y Seguridad → Grabación de audio*.

## Compilar

```bash
./scripts/build-app.sh
open build/SpeechRecog.app
```

El script:
1. Lanza `swift build -c release` con arquitecturas `arm64` + `x86_64`.
2. Monta un bundle `.app` con `Info.plist` (LSUIElement = true → no aparece en el Dock).
3. Firma localmente (ad-hoc). Para distribución, exporta `CODESIGN_IDENTITY="Developer ID Application: TU NOMBRE (TEAMID)"` antes de ejecutarlo.

Para abrirlo en Xcode como proyecto (más cómodo para iterar):

```bash
open Package.swift
```

Xcode lo reconoce como paquete SwiftPM y permite ejecutarlo con ⌘R.

## Usar

1. Lanza la app. Aparece un icono de onda en la barra superior, al lado del reloj.
2. Click → **Iniciar grabación**. El icono pasa a círculo rojo.
3. Haz tu llamada / reunión con normalidad.
4. Click → **Detener grabación**. El icono pasa a "lupa sobre onda" mientras transcribe.
5. Al terminar, el icono vuelve a su estado idle. Click → **Abrir carpeta de grabaciones**
   para ver el `.m4a` + `.srt` recién creados.

### Preferencias

- **Motor de transcripción**: WhisperKit (recomendado) o Apple Speech.
- **Modelo Whisper**: tiny / base / small / medium / large-v3. Los modelos se
  descargan automáticamente la primera vez desde Hugging Face vía WhisperKit.
- **Idioma**: código BCP-47 (`es`, `en-US`, `pt-BR`, …). Vacío → auto-detección
  (WhisperKit lo soporta nativamente; Apple Speech usa el idioma del sistema).

## Limitaciones conocidas

- **Solo audio del sistema** (lo que sonaría por los altavoces). Para grabar
  también el micrófono y mezclar las dos pistas habría que ampliar el aggregate
  device para incluir el dispositivo de entrada del sistema y mezclar las
  pistas con un `AVAudioMixerNode`. Está en la lista de mejoras.
- Si cambias la salida de audio del sistema en medio de una grabación, la
  grabación se queda atada al dispositivo que estuviera activo al pulsar
  *Iniciar*. Reiniciar la grabación recoge el dispositivo nuevo.
- Sin sandbox: para usar Process Taps el binario debe estar firmado con
  `com.apple.security.device.audio-input` y, en builds sandbox-eadas,
  permisos extra que Apple aún no expone limpiamente.

## Estructura del proyecto

```
Sources/SpeechRecog/
├── main.swift                         · Entry point AppKit
├── AppDelegate.swift
├── MenuBarController.swift            · NSStatusItem + menú
├── RecordingCoordinator.swift         · State machine grabar / transcribir
├── Audio/
│   ├── CoreAudioBridge.swift          · Helpers para propiedades de Core Audio
│   └── SystemAudioCapture.swift       · Process Tap + Aggregate Device + ExtAudioFile
├── Transcription/
│   ├── TranscriptionEngine.swift      · Protocolo + factory
│   ├── WhisperKitEngine.swift         · Backend por defecto
│   ├── AppleSpeechEngine.swift        · SFSpeechRecognizer
│   └── SRTWriter.swift
├── Storage/
│   ├── RecordingsStore.swift          · ~/Documents/SpeechRecog
│   └── Settings.swift                 · UserDefaults
└── UI/
    └── PreferencesWindow.swift        · SwiftUI
```

## Licencia

MIT. WhisperKit usa la licencia MIT; los modelos Whisper son de OpenAI (MIT).
