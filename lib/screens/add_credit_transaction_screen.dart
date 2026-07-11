import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/person.dart';
import '../models/credit_transaction.dart';
import '../providers/credit_provider.dart';

class AddCreditTransactionScreen extends StatefulWidget {
  final Person person;
  final CreditTransaction? transaction;

  const AddCreditTransactionScreen({
    super.key,
    required this.person,
    this.transaction,
  });

  @override
  State<AddCreditTransactionScreen> createState() =>
      _AddCreditTransactionScreenState();
}

class _AddCreditTransactionScreenState
    extends State<AddCreditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  double _amount = 0.0;
  String _note = '';
  bool _isReceived = true;
  String? _photoPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amount = widget.transaction!.amount;
      _note = widget.transaction!.note;
      _isReceived = widget.transaction!.isReceived;
      _photoPath = widget.transaction!.photoPath;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _photoPath = image.path;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (widget.transaction != null) {
        // Edit existing
        final tx = widget.transaction!
          ..amount = _amount
          ..note = _note
          ..isReceived = _isReceived
          ..photoPath = _photoPath;
        Provider.of<CreditProvider>(
          context,
          listen: false,
        ).updateTransaction(tx);
      } else {
        // Create new
        final tx = CreditTransaction()
          ..amount = _amount
          ..note = _note
          ..isReceived = _isReceived
          ..photoPath = _photoPath
          ..date = DateTime.now();

        tx.person.value = widget.person;
        Provider.of<CreditProvider>(context, listen: false).addTransaction(tx);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.person.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(
                        'received'.tr(),
                        style: const TextStyle(color: Colors.green),
                      ),
                      value: true,
                      groupValue: _isReceived,
                      onChanged: (val) => setState(() => _isReceived = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(
                        'given'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                      value: false,
                      groupValue: _isReceived,
                      onChanged: (val) => setState(() => _isReceived = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'amount_dh'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'DH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                initialValue: _amount == 0.0 ? '' : _amount.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'required_field'.tr();
                  if (double.tryParse(value) == null) return 'invalid_amount'.tr();
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _note,
                decoration: InputDecoration(
                  labelText: 'note_description'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.note),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                onSaved: (value) => _note = value ?? '',
              ),
              if (_photoPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photoPath!),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _photoPath = null),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'save'.tr(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
