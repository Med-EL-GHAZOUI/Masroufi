import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/person.dart';
import '../providers/credit_provider.dart';

class AddPersonScreen extends StatefulWidget {
  final bool isClient;

  const AddPersonScreen({super.key, required this.isClient});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _phone = '';

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final person = Person()
        ..name = _name
        ..phone = _phone
        ..isClient = widget.isClient;

      Provider.of<CreditProvider>(context, listen: false).addPerson(person);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isClient ? 'add_client'.tr() : 'add_supplier'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'name'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Champs obligatoire'
                    : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'phone'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) => _phone = value ?? '',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('save'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
