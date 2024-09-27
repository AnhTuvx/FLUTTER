import 'dart:io';

import 'package:chat_app/widgets/user_imgpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;
// luu mot gia tri voi lop xac thuc firebaseAuth

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enterEmail = "";
  var _enterPassword = "";
  var _enterUsername = "";
  File? _selectedImage;

  void _submit() async {
    //phuong thuc nhap
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      // kiem tra dau vao co hop le khong
      return;
    }

    _formKey.currentState!.save();
    //Luu lai gia tri
    try {
      if (_isLogin) {
        // kiem tra dang nhap
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
      } else {
        // luu tao tai khoan vao firebase
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enterEmail, password: _enterPassword);
        // luu anh vao firestore va tao mot anh id nguoi dung.jpg
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_img')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        // down url va luu tru tren firebase
        final imageURL = await storageRef.getDownloadURL();
        FirebaseFirestore.instance
            .collection("users")
            .doc(userCredentials.user!.uid)
            .set({
          "username": _enterUsername,
          "email": _enterEmail,
          "image_url": imageURL,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == "Email đã được sử dụng  ") {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? "Authentication failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_isLogin)
                      UserImgPicker(
                        onpickedImage: (pickedImage) {
                          _selectedImage = pickedImage;
                        },
                      ),
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: " Email",
                      ),
                      // tham so xac thuc
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            !value.contains(
                                "@")) //trim khoang trang truy cap da bi xoa
                        {
                          return "Không tìm thấy địa chỉ email của bạn";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enterEmail = value!;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: " Mật Khẩu ",
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null ||
                            value.trim().length <
                                6) //trim khoang trang truy cap da bi xoa
                        {
                          return "Mật khẩu có độ dài bằng 6";
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enterPassword = value!;
                      },
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    if (!_isLogin)
                      TextFormField(
                        decoration: InputDecoration(labelText: "Tên của bạn"),
                        enableSuggestions: false,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length < 4) {
                            return "Không để trống tên người dùng";
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enterUsername = value!;
                        },
                      ),
                    ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        ),
                        child: Text(_isLogin ? "Đăng nhập" : "Đăng ký")),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(_isLogin
                            ? "Tạo tài khoản mới"
                            : "Bạn đã có tài khoản?")),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
