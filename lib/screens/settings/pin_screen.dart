import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinScreen extends StatefulWidget {
  final bool isSettingPin;
  final String? expectedPin;
  final bool isVerifyingToChange;

  const PinScreen({
    super.key,
    this.isSettingPin = false,
    this.expectedPin,
    this.isVerifyingToChange = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorText = '';

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    if (!widget.isSettingPin) {
      _checkBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final useBiometrics = prefs.getBool('useBiometrics') ?? false;

    if (useBiometrics) {
      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Veuillez vous authentifier pour accéder à l\'application',
          biometricOnly: false,
        );
        if (didAuthenticate && mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        // Biometrics failed or canceled, fall back to PIN
      }
    }
  }

  void _onKeyPress(String value) {
    if (_pin.length < 4 && !_isConfirming) {
      setState(() {
        _pin += value;
        _errorText = '';
      });
      if (_pin.length == 4) {
        _handlePinComplete();
      }
    } else if (_confirmPin.length < 4 && _isConfirming) {
      setState(() {
        _confirmPin += value;
        _errorText = '';
      });
      if (_confirmPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDeletePress() {
    if (!_isConfirming && _pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorText = '';
      });
    } else if (_isConfirming && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        _errorText = '';
      });
    }
  }

  void _handlePinComplete() async {
    if (widget.isSettingPin) {
      if (!_isConfirming) {
        setState(() {
          _isConfirming = true;
        });
      } else {
        if (_pin == _confirmPin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('appPin', _pin);
          await prefs.setBool('usePin', true);
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _errorText = 'Les codes PIN ne correspondent pas';
            _confirmPin = '';
          });
        }
      }
    } else {
      // Verifying PIN
      final prefs = await SharedPreferences.getInstance();
      final savedPin = widget.expectedPin ?? prefs.getString('appPin');
      
      if (_pin == savedPin) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _errorText = 'Code PIN incorrect';
          _pin = '';
        });
      }
    }
  }

  Widget _buildDot(int index, String currentPin) {
    bool isFilled = index < currentPin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? Colors.green : Colors.transparent,
        border: Border.all(color: Colors.green, width: 2),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 1; j <= 3; j++)
                _buildPadButton((i * 3 + j).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPadButton(''),
            _buildPadButton('0'),
            _buildPadButton('<', isDelete: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPadButton(String text, {bool isDelete = false}) {
    if (text.isEmpty) {
      return const SizedBox(width: 80, height: 80);
    }
    return Container(
      margin: const EdgeInsets.all(8),
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: isDelete ? _onDeletePress : () => _onKeyPress(text),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        child: isDelete
            ? const Icon(Icons.backspace, size: 24, color: Colors.black54)
            : Text(
                text,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentPin = _isConfirming ? _confirmPin : _pin;
    
    String titleText = 'Entrez votre code PIN';
    if (widget.isSettingPin) {
      titleText = _isConfirming ? 'Confirmez le code PIN' : 'Créez un code PIN';
    } else if (widget.isVerifyingToChange) {
       titleText = 'Code PIN actuel requis';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              titleText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _buildDot(index, currentPin)),
            ),
            const SizedBox(height: 16),
            Text(
              _errorText,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            _buildNumberPad(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
