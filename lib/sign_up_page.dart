import 'package:flutter/material.dart';
import 'config_service.dart';
import 'package:http/http.dart' as http;
class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

   bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  void _register() {
    String email = _emailController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;
    String verificationCode = _verificationCodeController.text;

    //检查邮箱格式
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email format',style: TextStyle(color: Colors.red)),),
      );
      return;
    }
    //非空检查
    if (password == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords is null',style: TextStyle(color: Colors.red))),
      );
      return;
    }
    if (username == "") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('username is null',style: TextStyle(color: Colors.red))),
      );
      return;
    }
    // 在这里添加注册逻辑，例如验证输入、网络请求等
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration successful!')),
    );
  }

  void _getVerificationCode(BuildContext context) async {

    Config config = await ConfigService.loadConfig();
    final serviceConfig = config.services['varifyServer'];
    final String apiUrl = serviceConfig?.apiUrl ?? '';
    final int port = serviceConfig?.port ?? 0;
    // 在这里添加获取验证码的逻辑，比如发送请求到服务器

    //final Uri url = Uri.parse('$apiUrl:$port/get_verify_code');
    final Uri url = Uri.parse('https://example.com');
    print(url);

    final dialog = showDialog(
    context: context,
    barrierDismissible: false, // 防止点击对话框外部区域关闭对话框
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading...'),
          ],
        ),
      );
    },
  );

    try {
    // 发送 HTTP GET 请求
    final response = await http.get(url);
    print("send ");
    if (response.statusCode == 200) {
      // 如果请求成功
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification code sent successfully!')),
      );
    } else {
      // 如果请求失败
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification code',style: TextStyle(color: Colors.red))),
      );
    }
  } catch (e) {
    // 处理请求错误
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending verification code: $e',style: TextStyle(color: Colors.red))),
    );
  }
  finally {
    // 确保对话框关闭，无论请求成功还是失败
    Navigator.of(context).pop();
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('注册'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
              onSubmitted: (value) => _register(),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
              ),
              onSubmitted: (value) => _register()
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              onSubmitted: (value) => _register()
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              onSubmitted: (value) => _register()
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                    ),
                    onSubmitted: (value) => _register()
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: (){ 
                    _getVerificationCode(context);
                  },
                  child: Text('获取验证码'),
                ),
              ],
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _register,
              child: Text('Confirm Registration'),
            ),
          ],
        ),
      ),
    );
  }
}
