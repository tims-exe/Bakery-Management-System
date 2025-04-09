import 'package:flutter/material.dart';

class MoreDetails extends StatefulWidget {
  final Map<String, dynamic> currentBill;
  final Function(Map<String, dynamic>) onSave;

  const MoreDetails(
      {super.key, required this.currentBill, required this.onSave});

  @override
  State<MoreDetails> createState() => _MoreDetailsState();
}

class _MoreDetailsState extends State<MoreDetails> {
  late Map<String, dynamic> updatedBill;
  TextEditingController commentsController = TextEditingController(text: ' ');

  final Color _orange = const Color.fromRGBO(255, 168, 120, 1);

  @override
  void initState() {
    super.initState();
    updatedBill = Map.from(widget.currentBill);
    commentsController.text = updatedBill['comments'] ?? ' ';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'More Details',
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 500,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 220,
                      child: CheckboxListTile(
                        activeColor: _orange,
                        title: const Text('Produced'),
                        value: updatedBill['produced'],
                        onChanged: (bool? value) {
                          setState(() {
                            updatedBill['produced'] = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile(
                        activeColor: _orange,
                        title: const Text('Sticker Print'),
                        value: updatedBill['sticker_print'],
                        onChanged: (bool? value) {
                          setState(() {
                            updatedBill['sticker_print'] = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 500,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 220,
                      child: CheckboxListTile(
                        activeColor: _orange,
                        title: const Text('Bill Sent'),
                        value: updatedBill['bill_sent'],
                        onChanged: (bool? value) {
                          setState(() {
                            updatedBill['bill_sent'] = value!;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: CheckboxListTile(
                        activeColor: _orange,
                        title: const Text('Delivered'),
                        value: updatedBill['delivered'],
                        onChanged: (bool? value) {
                          setState(() {
                            updatedBill['delivered'] = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 500,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 220,
                      child: CheckboxListTile(
                        activeColor: _orange,
                        title: const Text('Payment Done'),
                        value: updatedBill['payment_done'],
                        onChanged: (bool? value) {
                          setState(() {
                            updatedBill['payment_done'] = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 200,
                      child: Text(''),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextField(
                  controller: commentsController,
                  decoration: InputDecoration(
                    hintText: 'Enter Comments',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                          10), 
                      borderSide: const BorderSide(
                        color: Colors.grey, 
                        width: 1.0, 
                      ),
                    ),
                  ),
                  minLines: 1,
                  maxLines: null,
                  onSubmitted: (value) {},
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without saving
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          onPressed: () {
            updatedBill['comments'] = commentsController.text;
            widget.onSave(updatedBill); // Save changes
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
