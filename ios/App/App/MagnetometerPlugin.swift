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

        print("[MagnetometerPlugin] start() called, hz=\(hz)")
        print("[MagnetometerPlugin] isMagnetometerAvailable=\(motionManager.isMagnetometerAvailable)")
        print("[MagnetometerPlugin] isAccelerometerAvailable=\(motionManager.isAccelerometerAvailable)")
        print("[MagnetometerPlugin] isDeviceMotionAvailable=\(motionManager.isDeviceMotionAvailable)")

        guard motionManager.isMagnetometerAvailable else {
            print("[MagnetometerPlugin] ERROR: Magnetometer not available")
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

        // ── CMDeviceMotion ─────────────────────────────────────────
        // Utilise .xMagneticNorthZVertical pour avoir le cap vrai
        // heading = cap magnétique nord dans le plan horizontal
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(
                using: .xMagneticNorthZVertical,
                to: queue
            ) { [weak self] data, error in
                guard let self = self, let motion = data, error == nil else { return }

                let pitch = motion.attitude.pitch * 180.0 / .pi
                let roll  = motion.attitude.roll  * 180.0 / .pi
                let yaw   = motion.attitude.yaw   * 180.0 / .pi

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
