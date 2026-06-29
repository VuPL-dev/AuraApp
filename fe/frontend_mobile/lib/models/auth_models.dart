class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class LoginResponse {
  final bool success;
  final String? accessToken;
  final String? message;
  final String? role;

  LoginResponse({
    required this.success,
    this.accessToken,
    this.message,
    this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] == true || json['token'] != null,
      accessToken: json['token'] ?? json['access_token'],
      message: json['message'] ?? json['error'],
      role: json['user']?['role'],
    );
  }
}

class RegisterRequest {
  final String email;
  final String password;

  RegisterRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterResponse {
  final bool success;
  final String? message;

  RegisterResponse({required this.success, this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['error'] == null, // if no error, it is success
      message: json['message'] ?? json['error'],
    );
  }
}

class VerifyEmailRequest {
  final String email;
  final String otpCode;

  VerifyEmailRequest({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'otp_code': otpCode,
    };
  }
}
