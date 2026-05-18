import CoreAudio
import Foundation

enum CoreAudioError: LocalizedError {
    case osStatus(String, OSStatus)
    case unsupportedFormat
    case noDefaultOutputDevice
    case processObjectNotFound(pid_t)

    var errorDescription: String? {
        switch self {
        case .osStatus(let op, let status):
            return "\(op) falló (\(status))"
        case .unsupportedFormat:
            return "Formato de audio no soportado"
        case .noDefaultOutputDevice:
            return "No hay dispositivo de salida por defecto"
        case .processObjectNotFound(let pid):
            return "Core Audio no encontró el proceso con PID \(pid)"
        }
    }
}

enum CoreAudio {

    static func check(_ status: OSStatus, _ op: String) throws {
        if status != noErr {
            throw CoreAudioError.osStatus(op, status)
        }
    }

    static func translatePIDToProcessObject(_ pid: pid_t) throws -> AudioObjectID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslatePIDToProcessObject,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var processObject = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var inPID = pid
        let status = withUnsafePointer(to: &inPID) { pidPtr in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &addr,
                UInt32(MemoryLayout<pid_t>.size),
                pidPtr,
                &size,
                &processObject
            )
        }
        try check(status, "TranslatePIDToProcessObject")
        guard processObject != kAudioObjectUnknown else {
            throw CoreAudioError.processObjectNotFound(pid)
        }
        return processObject
    }

    static func deviceNominalSampleRate(_ deviceID: AudioObjectID) throws -> Double {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rate: Float64 = 0
        var size = UInt32(MemoryLayout<Float64>.size)
        try check(
            AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &rate),
            "NominalSampleRate"
        )
        return rate
    }

    static func deviceInputStreamFormat(_ deviceID: AudioObjectID) throws -> AudioStreamBasicDescription {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamFormat,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var asbd = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        try check(
            AudioObjectGetPropertyData(deviceID, &addr, 0, nil, &size, &asbd),
            "DeviceInputStreamFormat"
        )
        return asbd
    }

    static func defaultOutputDeviceID() throws -> AudioObjectID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        try check(
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID),
            "DefaultOutputDevice"
        )
        guard deviceID != kAudioObjectUnknown else { throw CoreAudioError.noDefaultOutputDevice }
        return deviceID
    }

    static func defaultOutputDeviceUID() throws -> String {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        try check(
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID),
            "DefaultOutputDevice"
        )
        guard deviceID != kAudioObjectUnknown else { throw CoreAudioError.noDefaultOutputDevice }

        var uidAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: CFString = "" as CFString
        size = UInt32(MemoryLayout<CFString>.size)
        try withUnsafeMutablePointer(to: &uid) { ptr in
            try check(
                AudioObjectGetPropertyData(deviceID, &uidAddr, 0, nil, &size, ptr),
                "DeviceUID"
            )
        }
        return uid as String
    }

}
