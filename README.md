<p align="center">
  <img src="docs/logo.png" alt="SpeechRecog" width="128" />
</p>

<h1 align="center">SpeechRecog</h1>

<p align="center">
  Record system audio + microphone and auto-transcribe to subtitles.<br/>
  Lives in your menu bar. Apple Silicon, macOS 15+. No drivers needed.
</p>

<p align="center">
  <img src="docs/menu.png" alt="Menu bar" width="320" />
  &nbsp;&nbsp;
  <img src="docs/settings.png" alt="Settings" width="320" />
</p>

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/IagoLast/SpeechRecog/master/scripts/install.sh | bash
```

Requires an Apple Silicon Mac, macOS 15+, and Xcode with Swift 6.3+ and the Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`).

## Features

- **System audio capture** — Records everything playing on your Mac (meetings, music, videos) using Core Audio Process Taps. No virtual audio drivers needed.
- **Microphone mixing** — Optionally mix your microphone input into the recording so both sides of a conversation are captured in one file.
- **Auto-transcription** — Generates `.srt` subtitles automatically when you stop recording. Choose WhisperKit, Qwen3-ASR 1.7B, MOSS, or Apple Speech.
- **Qwen3-ASR 1.7B** — Local multilingual transcription with word alignment for subtitles. Speech detection and short chunks handle long recordings and silent gaps.
- **MOSS Transcribe Diarize** — Local transcription with timestamps and anonymous speaker labels. Long recordings are processed in 30-minute parts; speaker identities are scoped to each part and labeled accordingly.
- **Multiple Whisper models** — From Tiny (~75 MB, fast) to Large v3 (~3 GB, best quality). Models download automatically on first use.
- **Language detection** — Auto-detects the spoken language, or set a specific BCP-47 code (e.g. `es`, `en-US`, `pt-BR`).
- **Custom recordings folder** — Save recordings anywhere on your Mac.
- **Menu bar app** — Doesn't clutter your Dock. Keyboard shortcuts for everything.
- **Recordings library** — Open **Preferencias → Grabaciones** in the larger, resizable settings window to browse saved recordings and their subtitle status. Click **Transcribir…** or **Retranscribir…**, choose a model and language for that job, and follow its progress. This choice does not change your default model. The original `.m4a` audio stays unchanged; the `.srt` is replaced only after successful transcription. A failed job keeps the previous subtitles. The menu bar's **Re-transcribir** shortcut still uses your defaults.

## How it works

1. A **Process Tap** captures all system audio, excluding SpeechRecog's own PID
2. A private **Aggregate Device** keeps audio playing through your speakers/headphones normally
3. An **IOProc** writes the audio stream to `.m4a` (AAC), optionally mixing in microphone input
4. On stop, the configured transcription engine generates an `.srt` file alongside the recording

Recordings are saved to `~/Documents/SpeechRecog/` by default (configurable in Preferences).

## Usage

1. Launch the app — a waveform icon appears in the menu bar
2. Click **Start recording** (`Cmd+R`) — icon turns to a red circle
3. Have your meeting / call as usual
4. Click **Stop recording** — icon shows a progress indicator while transcribing
5. Click **Open recordings folder** (`Cmd+O`) to find your `.m4a` + `.srt`

## Preferences

| Setting | Description |
|---|---|
| **Include microphone** | Mix mic input into the system audio recording |
| **Transcription engine** | WhisperKit, Qwen3-ASR 1.7B, MOSS (with speaker labels), or Apple Speech |
| **Whisper model** | Tiny / Base / Small / Medium / Large v3 |
| **Language** | BCP-47 code or empty for auto-detection |
| **Recordings folder** | Where `.m4a` and `.srt` files are saved |

Qwen and MOSS run entirely on the Mac using [Speech Swift](https://github.com/soniqo/speech-swift).
Their models download on first use and are cached in `~/Library/Caches/qwen3-speech/` for offline reuse.
Qwen uses the 1.7B 8-bit model plus the 0.6B 8-bit forced aligner; MOSS uses the 0.9B INT8 MLX model.
The initial download takes several GB. The first transcription also includes model loading and GPU compilation.
The language setting accepts codes such as `es` or `es-ES`; leave it empty for automatic detection.

## Build from source

```bash
git clone https://github.com/IagoLast/SpeechRecog.git
cd SpeechRecog
make install              # build + copy to /Applications
```

Other targets:

```bash
make run                  # build + open from ./build (no install)
make uninstall            # remove from /Applications
make clean                # delete build artifacts
make test                 # audio mixing, concurrent buffering, and storage regressions
```

An optional model integration test uses a local audio fixture and real downloaded models:

```bash
SPEECHRECOG_TEST_AUDIO=/absolute/path/to/spanish-sample.m4a SPEECHRECOG_TEST_MODEL=qwen make test
SPEECHRECOG_TEST_AUDIO=/absolute/path/to/spanish-sample.m4a SPEECHRECOG_TEST_MODEL=moss make test
```

Use a Spanish sample saying “proyecto” and “viernes”; the tests check recognition and valid subtitle timestamps.

Install to a custom location:

```bash
make install INSTALL_DIR=~/Applications
```

The build automatically uses the first available Apple Development (or Mac Developer)
certificate, then a Developer ID Application certificate. Using the same certificate
keeps the app's identity stable so macOS can retain permissions across rebuilds.
If no certificate is available, the build falls back to an ad-hoc signature, which
may require granting permissions again after the executable changes.

Select a specific certificate (recommended if you have multiple signing identities):

```bash
CODESIGN_IDENTITY="Developer ID Application: ..." make install
```

## Permissions

Permissions are requested when you start recording, rather than when you launch the app:

- **System Audio Recording** — Core Audio requests access when first recording with a Process Tap; screen capture permission is not required ([Apple documentation](https://developer.apple.com/documentation/coreaudio/capturing-system-audio-with-core-audio-taps))
- **Microphone** — Required only if "Include microphone" is enabled

Existing microphone authorization is reused. If microphone access is denied, the
app records system audio only. You can change access in System Settings → Privacy
& Security. Switching from an ad-hoc signature to a certificate may require
granting permissions once for the new signing identity.

## Known limitations

- Changing the audio output device mid-recording won't be picked up — stop and restart the recording
- Not sandboxed: Process Taps require `com.apple.security.device.audio-input` entitlement outside the App Sandbox

## License

MIT
