import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showResetAlert = false
    @State private var resetSent = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Text("Force Submission")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.appPrimary)
                    Text("Brazilian Jiu Jitsu & MMA Academy")
                        .font(.subheadline)
                        .foregroundStyle(Color.appSecondary)
                }

                // Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)

                // Error
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Sign In button
                Button {
                    Task {
                        await authViewModel.signIn(email: email, password: password)
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                .padding(.horizontal)

                // Forgot password
                Button("Forgot Password?") {
                    showResetAlert = true
                }
                .font(.footnote)

                if resetSent {
                    Text("Password reset email sent. Check your inbox.")
                        .font(.footnote)
                        .foregroundStyle(.green)
                        .padding(.horizontal)
                }

                // Sign Up link
                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .font(.footnote)

                Spacer()
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Reset Password", isPresented: $showResetAlert) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Send Reset Link") {
                    Task {
                        await authViewModel.sendPasswordReset(email: email)
                        if authViewModel.errorMessage == nil {
                            resetSent = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email to receive a password reset link.")
            }
        }
    }
}
