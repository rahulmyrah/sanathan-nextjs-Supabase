// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_number_hint/phone_number_hint.dart';
import '../../services/apiHelper.dart';
import 'signup_controller.dart';

class LoginOtpController extends GetxController {
  SignupController signupController = Get.find<SignupController>();
  String screen = 'login_otp_controller.dart';
  double second = 0;
  var maxSecond;
  Timer? time;
  Timer? time2;
  final TextEditingController cMobileNumber = TextEditingController();
  final phoneNumberHintPlugin = PhoneNumberHint();
  FocusNode phonefocus = FocusNode();
  dynamic smsCode = '';
  APIHelper apiHelper = APIHelper();

  String? phonenois;
  String? countrycodeis;

  String countryCode = "+91";
  bool countryvalidator = false;

  bool validedPhone() {
    return countryvalidator;
  }

  Future<void> getNumberFromHintPlugin() async {
    try {
      print('triger the getNumberFromHintPlugin');
      final result = await phoneNumberHintPlugin.requestHint() ?? '';
      if (result.isNotEmpty) {
        cMobileNumber.text =
            result.replaceFirst(RegExp(r'^\+?\d{1,3}(?=\d{10}$)'), '');
        print('Phone Number form hint: $result');
      }
    } catch (e) {
      debugPrint('Error in getNumberFromHintPlugin(): $e');
    } finally {
      update();
    }
  }

  updateCountryCode(String? value) {
    countryCode = value ?? "+91";
    log('country code is $countryCode');
    update();
  }

  init() {}

  timer() {
    maxSecond = 60;
    time = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (maxSecond > 0) {
        maxSecond--;
        update();
      } else {
        time!.cancel();
        update();
      }
    });
  }
}
