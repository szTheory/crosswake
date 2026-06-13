import Foundation
import MetricKit

@objc
public class DiagnosticExportManager: NSObject, MXMetricManagerSubscriber {
    public static let shared = DiagnosticExportManager()
    
    // In a real implementation this would come from the bundled manifest/config
    private let endpointURL = URL(string: "https://api.example.com/diagnostics/export")!
    private let schemaVersion = "1.0"
    private let runtimeVersion = "0.1.0"
    
    // Exposed for testing
    public var urlSession: URLSession = .shared

    private override init() {
        super.init()
    }
    
    public func start() {
        MXMetricManager.shared.add(self)
    }
    
    public func stop() {
        MXMetricManager.shared.remove(self)
    }
    
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            if let crashDiagnostics = payload.crashDiagnostics {
                for diagnostic in crashDiagnostics {
                    // MetricKit crash is mapped to 'crash' kind and reason
                    export(diagnostic: diagnostic, kind: "crash", reason: "crash")
                }
            }
            if let hangDiagnostics = payload.hangDiagnostics {
                for diagnostic in hangDiagnostics {
                    // MetricKit hang is mapped to 'hang' kind and reason
                    export(diagnostic: diagnostic, kind: "hang", reason: "hang")
                }
            }
            // Discarding CPU/Disk/etc for now to stick strictly to the phase 65 contract
        }
    }
    
    private func export(diagnostic: MXDiagnostic, kind: String, reason: String) {
        let correlationId = UUID().uuidString
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let observedAt = formatter.string(from: Date())
        
        let nativeDiagnostic: [String: Any] = [
            "source": "metrickit",
            "exit_reason": reason
        ]
        
        let envelope: [String: Any] = [
            "schema_version": schemaVersion,
            "layer": "native",
            "platform": "ios",
            "native_runtime_version": runtimeVersion,
            "kind": kind,
            "correlation_id": correlationId,
            "observed_at": observedAt,
            "native_diagnostic": nativeDiagnostic
        ]
        
        fireAndForgetPost(payload: envelope)
    }
    
    // Marked internal or exposed for test dependency injection if needed
    public func fireAndForgetPost(payload: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else { return }
        
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let task = urlSession.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Diagnostic export failed: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Diagnostic export response: \(httpResponse.statusCode)")
            }
        }
        task.resume()
    }
}
