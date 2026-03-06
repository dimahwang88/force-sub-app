import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var adminCode = ""
    @State private var showAdminCode = false

    private var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }

    private var formValid: Bool {
        !displayName.isEmpty && !email.isEmpty && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Create Account")
                .font(.largeTitle.bold())

            VStack(spacing: 16) {
                TextField("Display Name", text: $displayName)
                    .textContentType(.name)
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if !confirmPassword.isEmpty && !passwordsMatch {
                    Text("Passwords do not match")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                // Admin invite code (hidden by default)
                if showAdminCode {
                    TextField("Admin Invite Code", text: $adminCode)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    withAnimation {
                        showAdminCode.toggle()
                        if !showAdminCode { adminCode = "" }
                    }
                } label: {
                    Text(showAdminCode ? "Remove admin code" : "I have an admin invite code")
                        .font(.footnote)
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.horizontal)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await authViewModel.signUp(
                        email: email,
                        password: password,
                        displayName: displayName,
                        adminCode: adminCode.isEmpty ? nil : adminCode.trimmingCharacters(in: .whitespaces)
                    )
                    if authViewModel.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!formValid || authViewModel.isLoading)
            .padding(.horizontal)

            Spacer()
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}
