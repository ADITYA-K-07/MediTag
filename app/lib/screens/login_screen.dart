import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

const _errors = {
  'invalid-phone-number': "That phone number doesn't look right.",
  'invalid-verification-code': 'That code is wrong. Check the SMS and try again.',
  'session-expired': 'That code has expired. Send a new one.',
  'too-many-requests': 'Too many attempts. Wait a few minutes and try again.',
  'network-request-failed': 'No internet connection. Check your signal and try again.',
};

String _message(Object e) => e is FirebaseAuthException ? (_errors[e.code] ?? e.message ?? 'Something went wrong.') : 'Something went wrong.';

/// Phone OTP login: the same account as the website.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  String? _verificationId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final digits = _phone.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) return setState(() => _error = 'Enter your 10-digit mobile number.');
    setState(() {
      _busy = true;
      _error = null;
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91$digits',
      verificationCompleted: (credential) => FirebaseAuth.instance.signInWithCredential(credential), // Android auto-reads the SMS
      verificationFailed: (e) => setState(() {
        _busy = false;
        _error = _message(e);
      }),
      codeSent: (id, _) => setState(() {
        _busy = false;
        _verificationId = id;
      }),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text)) return setState(() => _error = 'Enter the 6-digit code.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithCredential(PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: _code.text));
    } catch (e) {
      setState(() {
        _busy = false;
        _error = _message(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final codeStep = _verificationId != null;
    return Scaffold(
      backgroundColor: MtColors.periwinklePastel,
      appBar: AppBar(backgroundColor: MtColors.periwinklePastel, title: const Text('Log in')),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), children: [
        Text(codeStep ? 'Enter the code' : 'Log in to MediTag',
            style: text.titleLarge!.copyWith(fontSize: 32, color: MtColors.navy, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(
          codeStep ? 'We sent a 6-digit code to +91 ${_phone.text}.' : "We'll text you a code. Same account as the website.",
          style: text.bodyMedium!.copyWith(color: MtColors.inkMuted),
        ),
        const SizedBox(height: 28),
        if (!codeStep)
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _field('Mobile number', prefix: '+91  '),
          )
        else
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 10),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _field('6-digit code'),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : (codeStep ? _verify : _sendCode),
          style: FilledButton.styleFrom(backgroundColor: MtColors.navy, minimumSize: const Size.fromHeight(56), shape: const StadiumBorder()),
          child: Text(_busy ? 'Please wait…' : (codeStep ? 'Verify and log in' : 'Send code'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        if (codeStep)
          TextButton(onPressed: () => setState(() => _verificationId = null), child: const Text('Change number')),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: MtColors.peachPastel, borderRadius: BorderRadius.circular(16)),
            child: Text(_error!, style: const TextStyle(color: MtColors.peachStrong, fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  InputDecoration _field(String label, {String? prefix}) => InputDecoration(
        labelText: label,
        prefixText: prefix,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );
}
