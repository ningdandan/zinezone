import SwiftUI
import _AuthenticationServices_SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @StateObject var authViewModel = AuthViewModel()
    @EnvironmentObject var appState: AppStateViewModel
    
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
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    // 后面做Apple Sign-In
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
}
