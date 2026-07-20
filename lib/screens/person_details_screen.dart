import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:easy_localization/easy_localization.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/person.dart';
import '../models/credit_transaction.dart';
import '../providers/credit_provider.dart';
import 'add_credit_transaction_screen.dart';
import '../widgets/premium_header.dart';

class PersonDetailsScreen extends StatefulWidget {
  final Person person;

  const PersonDetailsScreen({super.key, required this.person});

  @override
  State<PersonDetailsScreen> createState() => _PersonDetailsScreenState();
}

class _PersonDetailsScreenState extends State<PersonDetailsScreen> {
  bool _showArchived = false;

  Future<void> _generatePdf(
    BuildContext context,
    List<CreditTransaction> transactions,
    double balance,
  ) async {
    try {
      final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final ttf = pw.Font.ttf(fontData);

      final isArabic = context.locale.languageCode == 'ar';
      final String phoneLabel = 'phone'.tr();
      final String totalReceivedStr = 'total_received'.tr();
      final String totalGivenStr = 'total_given'.tr();

      final String title = 'account_statement'.tr(args: [widget.person.name]);
      final String dateStr = 'date_of_statement'.tr(args: [DateFormat('dd/MM/yyyy').format(DateTime.now())]);
      final String balanceStr = 'balance'.tr();
      final String currentBalanceStr = 'current_balance'.tr();
      final String historyTitle = 'transactions_history'.tr();
      
      final String dateLabel = 'date'.tr();
      final String typeHeader = 'type'.tr();
      final String noteHeader = 'note'.tr();
      final String amountHeader = 'amount_dh'.tr();
      final String photoLabel = 'photo'.tr();
      
      final String receivedStr = 'received'.tr();
      final String givenStr = 'given'.tr();

      // Pre-load images
      final Map<int, pw.MemoryImage> loadedImages = {};
      for (var t in transactions) {
        if (t.photoPath != null && t.photoPath!.isNotEmpty) {
          final file = File(t.photoPath!);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            loadedImages[t.id] = pw.MemoryImage(bytes);
          }
        }
      }

      final pdf = pw.Document();

      final imageByteData = await rootBundle.load('assets/images/logo.jpeg');
      final imageBytes = imageByteData.buffer.asUint8List();
      final logoImage = pw.MemoryImage(imageBytes);

      final textDirection = isArabic
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr;

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
          textDirection: textDirection,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
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
                        title,
                        style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '$phoneLabel : ${widget.person.phone ?? "--"}  |  $dateLabel : ${DateTime.now().toString().substring(0, 10)}',
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
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(10),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          totalReceivedStr,
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${totalRecu.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          totalGivenStr,
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${totalDonne.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          currentBalanceStr,
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          '${balance.toStringAsFixed(2)} DH',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                historyTitle,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(3),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(dateLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(typeHeader, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(noteHeader, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(amountHeader, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(photoLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf))),
                    ],
                  ),
                  ...transactions.map((t) {
                    return pw.TableRow(
                      verticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(t.date), style: pw.TextStyle(font: ttf))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t.isReceived ? receivedStr : givenStr, style: pw.TextStyle(font: ttf))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t.note, style: pw.TextStyle(font: ttf))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${t.amount.toStringAsFixed(2)} DH', style: pw.TextStyle(font: ttf))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5), 
                          child: (t.photoPath != null && loadedImages.containsKey(t.id)) 
                            ? pw.Center(child: pw.Image(loadedImages[t.id]!, width: 40, height: 40, fit: pw.BoxFit.cover))
                            : pw.Text('', style: pw.TextStyle(font: ttf))
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = widget.person.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final file = File('${dir.path}/Releve_$sanitizedName.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Voici le relevé de ${widget.person.name}.');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création du PDF: $e')),
        );
      }
    }
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
    final allTransactions =
        creditProvider.transactions
            .where((t) => t.person.value?.id == widget.person.id)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final transactions = allTransactions.where((t) => _showArchived ? true : !t.isArchived).toList();

    final balance = creditProvider.getPersonBalance(widget.person.id);

    return Scaffold(
      body: Column(
        children: [
          PremiumHeader(
            title: widget.person.name,
            leading: const BackButton(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(
                  _showArchived ? Icons.archive : Icons.archive_outlined,
                  color: _showArchived ? Colors.orange : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showArchived = !_showArchived;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () => _generatePdf(context, transactions, balance),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('confirm'.tr()),
                      content: Text('delete_person_confirm'.tr(args: [widget.person.name])),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () async {
                            await creditProvider.deletePerson(widget.person.id);
                            if (ctx.mounted) Navigator.pop(ctx); // Close dialog
                            if (context.mounted) Navigator.pop(context); // Go back to CarnetScreen
                          },
                          child: Text(
                            'delete'.tr(),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            widget.person.phone ?? '--',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (widget.person.phone != null && widget.person.phone!.isNotEmpty)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.phone, color: Colors.blue),
                                  onPressed: () =>
                                      _launchUrl('tel:${widget.person.phone}'),
                                  tooltip: 'Appeler',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.message,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () =>
                                      _launchUrl('sms:${widget.person.phone}'),
                                  tooltip: 'SMS',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat, color: Colors.green),
                                  onPressed: () =>
                                      _launchUrl('https://wa.me/${widget.person.phone}'),
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
                  if (widget.person.address != null && widget.person.address!.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.person.address!, style: const TextStyle(fontSize: 15))),
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () => _launchUrl('https://maps.google.com/?q=${Uri.encodeComponent(widget.person.address!)}'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Ouvrir Maps',
                        )
                      ],
                    ),
                  ],
                  if (widget.person.email != null && widget.person.email!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.person.email!, style: const TextStyle(fontSize: 15))),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: () => _launchUrl('mailto:${widget.person.email}'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Envoyer Email',
                        )
                      ],
                    ),
                  ],
                  if (widget.person.note != null && widget.person.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.person.note!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15))),
                      ],
                    ),
                  ],
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
                      return Opacity(
                        opacity: t.isArchived ? 0.5 : 1.0,
                        child: ListTile(
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.note.isNotEmpty
                                      ? t.note
                                      : (t.isReceived ? 'received'.tr() : 'given'.tr()),
                                ),
                              ),
                              if (t.isArchived)
                                const Text(
                                  ' (Archivé)',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                            ],
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
                                            person: widget.person,
                                            transaction: t,
                                          ),
                                    ),
                                  );
                                } else if (value == 'archive') {
                                  creditProvider.archiveTransaction(t.id, !t.isArchived);
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('confirm'.tr()),
                                      content: Text(
                                        'delete_transaction_confirm'.tr(),
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
                                          child: Text(
                                            'delete'.tr(),
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('edit'.tr()),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text(t.isArchived ? 'Désarchiver' : 'Archiver'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('delete'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  ),
          ),
        ],
      ),
      ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddCreditTransactionScreen(person: widget.person),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
