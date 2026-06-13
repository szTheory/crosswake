import MetricKit

class MockCrashDiagnostic: MXCrashDiagnostic {
    // try to override something
}

class MockPayload: MXDiagnosticPayload {
    var mockedCrashDiagnostics: [MXCrashDiagnostic]?
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return mockedCrashDiagnostics
    }
}
