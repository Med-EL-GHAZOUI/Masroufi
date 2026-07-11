import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/person.dart';
import '../models/credit_transaction.dart';
import '../providers/credit_provider.dart';
import 'add_credit_transaction_screen.dart';

class PersonDetailsScreen extends StatelessWidget {
  final Person person;

  const PersonDetailsScreen({super.key, required this.person});

  Future<void> _generatePdf(
    BuildContext context,
    List<CreditTransaction> transactions,
    double balance,
  ) async {
    final pdf = pw.Document();

    final imageByteData = await rootBundle.load('assets/images/logo.jpeg');
    final imageBytes = imageByteData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(imageBytes);

    double totalDonne = 0;
    double totalRecu = 0;
    for (var t in transactions) {
      if (t.isReceived) {
        totalRecu += t.amount;
      } else {
        totalDonne += t.amount;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Masroufi',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'Relevé de compte - ${person.name}',
                        style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Téléphone : ${person.phone ?? "--"}  |  Date : ${DateTime.now().toString().substring(0, 10)}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  pw.Image(logoImage, width: 80, height: 80),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Total Reçu', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        pw.Text(
                          '${totalRecu.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green600),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Total Donné', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        pw.Text(
                          '${totalDonne.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red600),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Solde Actuel', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                        pw.Text(
                          '${balance.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Historique des transactions:',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: ctx,
                headers: ['Date', 'Type', 'Note', 'Montant'],
                data: transactions.map(
                  (t) => [
                    DateFormat('dd/MM/yyyy HH:mm').format(t.date),
                    t.isReceived ? 'Reçu' : 'Donné',
                    t.note,
                    '${t.amount.toStringAsFixed(2)} DH',
                  ],
                ).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Releve_${person.name}.pdf',
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditProvider = Provider.of<CreditProvider>(context);

    // Transactions sorted by date descending
    final transactions =
        creditProvider.transactions
            .where((t) => t.person.value?.id == person.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final balance = creditProvider.getPersonBalance(person.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdf(context, transactions, balance),
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'phone'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        person.phone ?? '--',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (person.phone != null && person.phone!.isNotEmpty)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, color: Colors.blue),
                              onPressed: () =>
                                  _launchUrl('tel:${person.phone}'),
                              tooltip: 'Appeler',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.message,
                                color: Colors.orange,
                              ),
                              onPressed: () =>
                                  _launchUrl('sms:${person.phone}'),
                              tooltip: 'SMS',
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.green),
                              onPressed: () =>
                                  _launchUrl('https://wa.me/${person.phone}'),
                              tooltip: 'WhatsApp',
                            ),
                          ],
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'amount'.tr(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${balance.toStringAsFixed(2)} DH',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: transactions.isEmpty
                ? const Center(child: Text('Aucune transaction.'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final t = transactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: t.isReceived
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Icon(
                            t.isReceived
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: t.isReceived ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          t.note.isNotEmpty
                              ? t.note
                              : (t.isReceived ? 'received'.tr() : 'given'.tr()),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
                            if (t.photoPath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Image.file(File(t.photoPath!)),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Voir photo',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${t.amount.toStringAsFixed(2)} DH',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: t.isReceived ? Colors.green : Colors.red,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddCreditTransactionScreen(
                                            person: person,
                                            transaction: t,
                                          ),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirmer'),
                                      content: const Text(
                                        'Voulez-vous supprimer cette transaction ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text('cancel'.tr()),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Provider.of<CreditProvider>(
                                              context,
                                              listen: false,
                                            ).deleteTransaction(t.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            'Supprimer',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Modifier'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCreditTransactionScreen(person: person),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
