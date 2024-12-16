import 'package:flutter/material.dart';
import 'package:nissy_bakes_app/components/coming_soon.dart';

import '../database/dbhelper.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {

  final DbHelper _dbhelper = DbHelper();

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  DateTime _date = DateTime.now();

  String _filter = 'Today';
  final List<String> _allFilters = ['All', 'Today', 'Tomorrow'];
  int _filterIndex = 1;

  /* Future<List<Map<String, dynamic>>> getDeliveryLine() async {

  } */
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 25, right: 25, top: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // close button
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    //display();
                  },
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 30,
                ),
                // title
                Padding(
                  padding: const EdgeInsets.only(left: 80),
                  child: Text(
                    'Delivery',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_allFilters.contains(_filter)){
                        _filterIndex = (_filterIndex + 1) % (_allFilters.length);
                        _filterIndex == 1 ? _date = DateTime.now() : _date = DateTime.now().add(Duration(days: 1));
                      }
                      else{
                        _filterIndex = 1;
                        _date = DateTime.now();
                      }
                      setState(() {
                        _filter = _allFilters[_filterIndex];
                      });
                    },
                    onLongPress: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(3000),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _date = pickedDate;
                          _filter = '${_date.day.toString().padLeft(2, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.year.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _filter,
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
            // heading line
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),
              child: Divider(
                thickness: 2.5,
                color: _grey,
                height: 35, // Space above and below the line
              ),
            ),
            /* Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getDeliveryLine(), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error : ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No items found'),
                    );
                  }
                  final items = snapshot.data!;
                  return ListTile(
                    title: Text('data'),
                  );
                }
              )
            ) */
          ],
        ),
      ),
    );
  }
}