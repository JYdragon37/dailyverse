import SwiftUI

struct EmailAuthView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    enum Mode { case signIn, signUp }
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 탭 전환
                    Picker("", selection: $mode) {
                        Text("로그인").tag(Mode.signIn)
                        Text("회원가입").tag(Mode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    VStack(spacing: 14) {
                        TextField("이메일", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        SecureField("비밀번호 (6자 이상)", text: $password)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        if mode == .signUp {
                            SecureField("비밀번호 확인", text: $confirmPassword)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)

                    // 에러
                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    // 실행 버튼
                    Button {
                        Task {
                            isLoading = true
                            if mode == .signUp {
                                guard password == confirmPassword else {
                                    authManager.authError = "비밀번호가 일치하지 않아요"
                                    isLoading = false
                                    return
                                }
                                await authManager.signUpWithEmail(email: email, password: password)
                            } else {
                                await authManager.signInWithEmail(email: email, password: password)
                            }
                            isLoading = false
                            if authManager.isLoggedIn { dismiss() }
                        }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().progressViewStyle(.circular).tint(.white)
                            } else {
                                Text(mode == .signIn ? "로그인" : "회원가입")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 24)
                    }
                    .disabled(email.isEmpty || password.count < 6 || isLoading)
                }
            }
            .navigationTitle(mode == .signIn ? "로그인" : "회원가입")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .onChange(of: authManager.isLoggedIn) { loggedIn in
                if loggedIn { dismiss() }
            }
        }
    }
}

#Preview {
    EmailAuthView()
        .environmentObject(AuthManager())
}
