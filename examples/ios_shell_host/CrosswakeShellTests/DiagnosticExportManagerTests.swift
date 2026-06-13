import XCTest
import MetricKit
@testable import CrosswakeShell

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("Received unexpected request with no handler set")
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
    }
}

class MockCrashDiagnostic: MXCrashDiagnostic {
}

class MockHangDiagnostic: MXHangDiagnostic {
}

class MockDiagnosticPayload: MXDiagnosticPayload {
    var mockedCrashDiagnostics: [MXCrashDiagnostic]?
    var mockedHangDiagnostics: [MXHangDiagnostic]?
    
    override var crashDiagnostics: [MXCrashDiagnostic]? {
        return mockedCrashDiagnostics
    }
    
    override var hangDiagnostics: [MXHangDiagnostic]? {
        return mockedHangDiagnostics
    }
}

final class DiagnosticExportManagerTests: XCTestCase {
    var manager: DiagnosticExportManager!
    var session: URLSession!
    
    override func setUp() {
        super.setUp()
        manager = DiagnosticExportManager.shared
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        
        manager.urlSession = session
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testCrashDiagnosticExport() throws {
        let expectation = XCTestExpectation(description: "Wait for network request")
        
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/diagnostics/export")
            XCTAssertEqual(request.httpMethod, "POST")
            
            if let httpBody = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
                
                // Assert required contract fields
                XCTAssertEqual(json["schema_version"] as? String, "1.0")
                XCTAssertEqual(json["layer"] as? String, "native")
                XCTAssertEqual(json["platform"] as? String, "ios")
                XCTAssertEqual(json["kind"] as? String, "crash")
                XCTAssertNotNil(json["correlation_id"])
                XCTAssertNotNil(json["observed_at"])
                
                // Assert native_diagnostic structure
                let nativeDiag = json["native_diagnostic"] as? [String: Any]
                XCTAssertNotNil(nativeDiag)
                XCTAssertEqual(nativeDiag?["source"] as? String, "metrickit")
                XCTAssertEqual(nativeDiag?["exit_reason"] as? String, "crash")
                
                // Assert that raw exception payloads are not included to enforce fail-closed redaction logic
                XCTAssertNil(json["raw_payload"])
                XCTAssertNil(nativeDiag?["raw_payload"])
                
            } else {
                XCTFail("Could not parse HTTP body as JSON")
            }
            
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let mockCrash = MockCrashDiagnostic()
        let mockPayload = MockDiagnosticPayload()
        mockPayload.mockedCrashDiagnostics = [mockCrash]
        
        manager.didReceive([mockPayload])
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testHangDiagnosticExport() throws {
        let expectation = XCTestExpectation(description: "Wait for hang network request")
        
        MockURLProtocol.requestHandler = { request in
            if let httpBody = request.httpBody,
               let json = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
                XCTAssertEqual(json["kind"] as? String, "hang")
                
                let nativeDiag = json["native_diagnostic"] as? [String: Any]
                XCTAssertEqual(nativeDiag?["exit_reason"] as? String, "hang")
            }
            
            expectation.fulfill()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }
        
        let mockHang = MockHangDiagnostic()
        let mockPayload = MockDiagnosticPayload()
        mockPayload.mockedHangDiagnostics = [mockHang]
        
        manager.didReceive([mockPayload])
        
        wait(for: [expectation], timeout: 2.0)
    }
}
