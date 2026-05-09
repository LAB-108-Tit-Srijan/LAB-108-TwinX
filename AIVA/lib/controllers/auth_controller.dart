import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxString phoneNumber = ''.obs;
  final RxBool isLoading = false.obs;
  final RxInt resendTimer = 30.obs;

  void sendOtp(String phone) async {
    isLoading.value = true;
    phoneNumber.value = phone;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
  }

  void verifyOtp(String otp) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
    if (otp == '123456') {
      isLoggedIn.value = true;
      Get.offAllNamed('/home');
    } else {
      Get.snackbar(
        'Invalid OTP',
        'Please enter the correct OTP. Hint: 123456',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  void startResendTimer() async {
    resendTimer.value = 30;
    while (resendTimer.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      resendTimer.value--;
    }
  }
}
