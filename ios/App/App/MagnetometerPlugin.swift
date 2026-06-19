import Foundation
import Capacitor
import CoreMotion

@objc(MagnetometerPlugin)
public class MagnetometerPlugin: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "MagnetometerPlugin"
    public let jsName = "Magnetometer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop",  returnType: CAPPluginReturnPromise),
    ]

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    // ─── start ────────────────────────────────────────────────────
    @objc func start(_ call: CAPPluginCall) {
        let hz = call.getDouble("frequency") ?? 20.0
        let interval = 1.0 / hz
        motionManager.magnetometerUpdateInterval  = interval
        motionManager.accelerometerUpdateInterval = interval
        motionManager.deviceMotionUpdateInterval  = interval

        guard motionManager.isMagnetometerAvailable else {
            call.reject("Magnetometer not available on this device")
            return
        }

        // ── Magnétomètre brut ──────────────────────────────────────
        // X/Y/Z en µT via CMMagnetometer — pour le calcul du cap azimut
        motionManager.startMagnetometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let mag = data, error == nil else { return }
            self.notifyListeners("magnetometerData", data: [
                "x": mag.magneticField.x,
                "y": mag.magneticField.y,
                "z": mag.magneticField.z
            ])
        }

        // ── Accéléromètre brut ─────────────────────────────────────
        // X/Y/Z en g — pour la compensation de tilt du magnétomètre
        if motionManager.isAccelerometerAvailable {
            motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
                guard let self = self, let acc = data, error == nil else { return }
                self.notifyListeners("accelerometerData", data: [
                    "x": acc.acceleration.x,
                    "y": acc.acceleration.y,
                    "z": acc.acceleration.z
                ])
            }
        }

        // ── CMDeviceMotion — altitude polaire précise ──────────────
        // Fusion gyroscope + accéléromètre (AHRS Apple)
        // pitch = inclinaison avant/arrière = altitude polaire
        // roll  = inclinaison gauche/droite = niveau E-O
        // Résolution : ~0.01° — bien supérieure à DeviceOrientationEvent (~0.1°)
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(
                using: .xMagneticNorthZVertical,
                to: queue
            ) { [weak self] data, error in
                guard let self = self, let motion = data, error == nil else { return }

                // Conversion radians → degrés
                let pitch = motion.attitude.pitch * 180.0 / .pi  // inclinaison N-S
                let roll  = motion.attitude.roll  * 180.0 / .pi  // inclinaison E-O
                let yaw   = motion.attitude.yaw   * 180.0 / .pi  // cap (non utilisé ici)

                self.notifyListeners("deviceMotion", data: [
                    "pitch": pitch,
                    "roll":  roll,
                    "yaw":   yaw
                ])
            }
        }

        call.resolve()
    }

    // ─── stop ─────────────────────────────────────────────────────
    @objc func stop(_ call: CAPPluginCall) {
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        motionManager.stopDeviceMotionUpdates()
        call.resolve()
    }
}
