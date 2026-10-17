import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:schnell_luminator/login_page/login_controller.dart';
import 'package:schnell_luminator/utils/error_messages.dart';
import '../env.dart';
import '../utils/asset_folder.dart';
import '../utils/constants.dart';
import '../utils/custom_loading.dart';
import '../utils/dialog_box.dart';
import '../utils/utility.dart';
import 'login_model.dart';

class LoginPage extends ConsumerWidget {
  final GlobalKey<FormState> _key = GlobalKey();

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final bool visible = true;

  LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool passwordVisible = ref.watch(loginController).passwordVisible;
    UserModel loginUser = ref.watch(loginController).userLogin;

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        body: Form(
            key: _key, child: _body(context, ref, passwordVisible, loginUser)),
      ),
    );
  }

  _body(BuildContext context, WidgetRef ref, bool passwordVisible,
          UserModel loginUser) =>
      ListView(children: <Widget>[
        Container(
            padding: const EdgeInsets.all(15),
            alignment: Alignment.center,
            child: Column(children: <Widget>[
              _formUI(context, ref, passwordVisible, loginUser)
            ]))
      ]);

  _formUI(BuildContext context, WidgetRef ref, bool passwordVisible,
      UserModel loginUser) {
    bool isLoad = ref.watch(loginController).loginLoader;
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Container(
      width: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: height / 15,
          ),
          SizedBox(
            height: height / 3.9,
            width: width / 2,
            child: Image.asset(logoImage),
          ),
          SizedBox(height: height / 33),
          Text('Luminator', style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: height / 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _inputUser(context, ref, loginUser),
          ),
          const SizedBox(height: 12.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _inputPassword(context, ref, passwordVisible, loginUser),
          ),
          const SizedBox(height: 20.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: height / 17,
              width: double.infinity,
              child: isLoad
                  ? loginLoader
                  : ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Theme.of(context).primaryColor),
                        foregroundColor: WidgetStateProperty.all(
                            Theme.of(context).canvasColor),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0))),
                      ),
                      child: Text("login".toUpperCase()),
                      onPressed: () {
                        FocusScope.of(context).requestFocus(FocusNode());
                        _sendToServer(context, ref, loginUser);
                      },
                    ),
            ),
          ),
          SizedBox(
            height: height / 12,
          ),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                baseURL.contains('iotpro')
                    ? 'Version: $appVersion - Beta'
                    : 'Version: $appVersion',
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ))
        ],
      ),
    );
  }

  _inputUser(context, ref, UserModel loginUser) {
    return TextFormField(
      maxLength: 60,
      validator: (value) => EmailValidator.validate(loginUser.username)
          ? null
          : ErrorMessages.emailValidationError,
      initialValue: loginUser.username,
      onChanged: (value) =>
          ref.read(loginController).textFieldUpdate(value, true),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(16.0),
        hintText: 'Username',
        counterText: "",
        hintStyle: TextStyle(
            color: Theme.of(context).cardColor,
            fontSize: 15.0,
            fontWeight: FontWeight.bold),
        prefixIcon: _prefixIcon(context, Icons.person),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.19),
      ),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 16.0),
      keyboardType: TextInputType.text,
    );
  }

  _inputPassword(BuildContext context, WidgetRef ref, bool passwordVisible,
      UserModel loginUser) {
    return TextFormField(
      maxLength: 60,
      initialValue: loginUser.password,
      onChanged: (value) {
        ref.read(loginController).textFieldUpdate(value, false);
      },
      obscureText: passwordVisible,
      validator: validatePassword,
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16.0),
          hintText: 'Password',
          counterText: "",
          hintStyle: TextStyle(
              color: Theme.of(context).cardColor,
              fontSize: 15.0,
              fontWeight: FontWeight.bold),
          prefixIcon: _prefixIcon(
            context,
            Icons.lock,
          ),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.19),
          suffix: InkWell(
            child: passwordVisible
                ? Icon(
                    Icons.visibility_off,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  )
                : Icon(
                    Icons.visibility,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
            onTap: () {
              ref.read(loginController).passwordVisibleChange();
            },
          )),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 16.0),
    );
  }

  _prefixIcon(BuildContext context, IconData iconData) {
    return Container(
        padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
                bottomRight: Radius.circular(10.0))),
        child: Icon(
          iconData,
          size: 20,
          color: Theme.of(context).cardColor,
        ));
  }

  _sendToServer(
      BuildContext context, WidgetRef ref, UserModel loginUser) async {
    await Utility.isConnected().then((value) async {
      if (value) {
        if (_key.currentState!.validate()) {
          _key.currentState!.save();
          ref.read(loginController).loginLoadChange();
          if (context.mounted) {
            await ref.read(loginController).validateLogin(
                context, ref, loginUser.username, loginUser.password);
          }
        }
      } else {
        if (context.mounted) {
          await snackBar(context, ErrorMessages.offlineErrorTitle,
              ErrorMessages.offlineErrorMessage);
        }
      }
    });
  }

  String? validatePassword(String? value) {
    if (value!.isEmpty) {
      return ErrorMessages.passwordValidationError;
    }
    return null;
  }
}
