import LiveKitWebRTC

/// A delegate for `URLSession` that bypasses standard SSL certificate validation.
///
/// This class is useful for connecting to local robot servers that use self-signed certificates.
/// - Warning: Do not use this in a production environment as it poses security risks.
class SelfSignedCertDelegate: NSObject, URLSessionDelegate {

    /// Automatically accepts all server-provided certificates regardless of their trust status.
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        if let serverTrust = challenge.protectionSpace.serverTrust {
            // Accept the server trust for development purposes
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
