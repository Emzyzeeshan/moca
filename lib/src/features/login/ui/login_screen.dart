import 'package:mocadb/src/core/utils/extension.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constants_index.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../core/utils/print.dart';
import '../../../core/utils/routes.dart';
import '../../widgets/custom_text_form.dart';
import '../../widgets/submit_btn.dart';
import '../login_index.dart';

class LoginScreenWidget extends StatefulWidget {
  const LoginScreenWidget({super.key});

  @override
  State<LoginScreenWidget> createState() => _LoginScreenWidgetState();
}

class _LoginScreenWidgetState extends State<LoginScreenWidget> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future _login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final loginProvider = context.read<LoginProvider>();

    EasyLoading.show(status: 'Logging in...');

    try {
      // Pass the username and password to the provider
      loginProvider.userNameController.text = _usernameController.text.trim();
      loginProvider.passwordController.text = _passwordController.text.trim();

      await loginProvider.postLoginApiCall(context);

      // if (loginProvider.) {
      //   NavigateRoutes.navigateTo();
      // }
    } catch (e) {
      EasyLoading.showError('Login failed');
    } finally {
      EasyLoading.dismiss();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: context.height * 0.1),
            Center(
              child: Image.asset(
                Assets.appLogo,
                height: context.width * .3,
                width: context.width * .4,
                fit: BoxFit.fill,
              ),
            ),
            SizedBox(height: context.height * 0.05),

            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  /// **Username Field**
                  CustomTextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    focusNode: _usernameFocus,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter username'
                        : null,
                    labelText: 'Username',
                    hintText: 'Enter your username',
                  ),
                  16.ph,

                  /// **Password Field**
                  _buildPasswordField(),

                  24.ph,

                  /// **Login Button**
                  SubmitButtonFillWidget(
                    onTap: () async {
                      printDebug('Logging in...');
                      await _login(context);
                    },
                    text: Constants.login,
                    btnColor: ThemeColors.primaryColor,
                    textPadding: EdgeInsets.all(context.height * .015),
                    isEnabled: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return CustomTextFormField(
      controller: _passwordController,
      keyboardType: TextInputType.visiblePassword,
      obscureText: !_isPasswordVisible,
      focusNode: _passwordFocus,
      validator: (value) =>
      value?.isEmpty ?? true ? 'Please enter password' : null,
      labelText: 'Password',
      hintText: 'Enter your password',
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
    );
  }
}
