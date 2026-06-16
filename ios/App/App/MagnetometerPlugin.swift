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
        motionManager.magnetometerUpdateInterval = 1.0 / hz

        // Accéléromètre — nécessaire pour la compensation de tilt côté JS
        motionManager.accelerometerUpdateInterval = 1.0 / hz

        guard motionManager.isMagnetometerAvailable else {
            call.reject("Magnetometer not available on this device")
            return
        }

        // ── Magnétomètre brut ──────────────────────────────────────
        motionManager.startMagnetometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let mag = data, error == nil else { return }
            self.notifyListeners("magnetometerData", data: [
                "x": mag.magneticField.x,
                "y": mag.magneticField.y,
                "z": mag.magneticField.z
            ])
        }

        // ── Accéléromètre brut ─────────────────────────────────────
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

        call.resolve()
    }

    // ─── stop ─────────────────────────────────────────────────────
    @objc func stop(_ call: CAPPluginCall) {
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        call.resolve()
    }
}
