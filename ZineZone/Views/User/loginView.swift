import SwiftUI
import _AuthenticationServices_SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift
import CryptoKit

struct LoginView: View {
    @StateObject var authViewModel = AuthViewModel()
    @EnvironmentObject var appState: AppStateViewModel
    @State private var currentNonce: String?
    
    var body: some View {
        
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                Text("Hello!")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                GoogleSignInButton(action: {
                    handleGoogleSignIn()
                })
                .frame(height: 50)
                .padding(.horizontal)

                SignInWithAppleButton(.signIn, onRequest: { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        handleAppleSignIn(result: authResults)
                    case .failure(let error):
                        print("Apple Sign-In Error: \(error.localizedDescription)")
                    }
                })
                .frame(height: 50)
                .padding(.horizontal)

                Spacer()
                
                // 小小的Loading提示
                if authViewModel.isLoggedIn {
                    NavigationLink(destination: InitialSetupView(), isActive: $authViewModel.isLoggedIn) {
                        EmptyView()
                    }
                }
            }
        }
    }
    
    private func handleAppleSignIn(result: ASAuthorization) {
        guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential else {
            print("AppleID Credential not found")
            return
        }
        
        guard let tokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8) else {
            print("Unable to fetch identity token")
            return
        }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: currentNonce ?? ""
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase Sign-In Error with Apple: \(error.localizedDescription)")
                return
            }
            
            if let user = authResult?.user {
                print("Apple Sign-In SUCCESS! UID: \(user.uid)")
                authViewModel.handleSignIn(user: user)
                self.appState.isLoggedIn = true
            }
        }
    }

    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Unable to access root view controller")
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Missing Client ID")
            return
        }

        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Google Sign-In Error: \(error.localizedDescription)")
                return
            }

            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Google Sign-In: Missing idToken")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In Error: \(error.localizedDescription)")
                    return
                }

                if let user = authResult?.user {
                    print("Google Sign-In SUCCESS! UID: \(user.uid)")
                    authViewModel.handleSignIn(user: user)
                    self.appState.isLoggedIn = true
                }
            }
        }
    }
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms = (0 ..< 16).map { _ in UInt8.random(in: 0...255) }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}
