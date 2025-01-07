import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nissy_bakes_app/database/dbhelper.dart';
import '../components/search_customer.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  // initializing current customer
  Map<String, dynamic> currentCustomer = {
    'customer_name': null,
    'reference': null,
    'customer_address': null,
    'customer_phone': null,
    'customer_balance': 0,
    'modified_datetime': null,
  };

  int currentCustomerID = 0;

  DateTime modifiedDateTime = DateTime.now();

  // all textfield variables
  TextEditingController name = TextEditingController();
  TextEditingController reference = TextEditingController();
  TextEditingController address = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController balance = TextEditingController(text: '0');
  var phoneNumberDialCode = "+91";
  PhoneNumber phoneNumberIsoCode = PhoneNumber(isoCode: 'IN');

  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  final _dbhelper = DbHelper();

  bool _isEdit = false;

  // get all customers
  Future<List<Map<String, dynamic>>> getCustomers() async {
    List<Map<String, dynamic>> getcustomer =
        await _dbhelper.getCustomers('customer_master');

    return getcustomer;
  }

  // clear customer details
  void clearAll() {
    setState(() {
      currentCustomer['customer_name'] = null;
      currentCustomer['reference'] = null;
      currentCustomer['customer_address'] = null;
      currentCustomer['customer_phone'] = null;
      currentCustomer['customer_balance'] = 0;

      name.clear();
      address.clear();
      reference.clear();
      phone.clear();
      balance.text = '0';

      currentCustomerID = 0;

      _isEdit = false;
    });
  }

  // add new customer
  void addNewCustomer() async {
    print('Customer Added');

    currentCustomer['modified_datetime'] =
        '${modifiedDateTime.year.toString().padLeft(2, '0')}-${modifiedDateTime.month.toString().padLeft(2, '0')}-${modifiedDateTime.day.toString().padLeft(2, '0')} ${modifiedDateTime.hour.toString().padLeft(2, '0')}:${modifiedDateTime.minute.toString().padLeft(2, '0')}:${modifiedDateTime.second.toString().padLeft(2, '0')}';

    await _dbhelper.insertCustomer(currentCustomer);

    Fluttertoast.showToast(
      msg: "${currentCustomer['customer_name']} Added",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    clearAll();
  }

  // edit existing customer
  void editCustomer() async {
    print('Customer Edited');

    currentCustomer['modified_datetime'] =
        '${modifiedDateTime.year.toString().padLeft(2, '0')}-${modifiedDateTime.month.toString().padLeft(2, '0')}-${modifiedDateTime.day.toString().padLeft(2, '0')} ${modifiedDateTime.hour.toString().padLeft(2, '0')}:${modifiedDateTime.minute.toString().padLeft(2, '0')}:${modifiedDateTime.second.toString().padLeft(2, '0')}';

    await _dbhelper.updateCustomer(currentCustomer, currentCustomerID);

    Fluttertoast.showToast(
      msg: "${currentCustomer['customer_name']} Updated",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    clearAll();
  }

  // show red warning toast
  void showWarning(String m) {
    Fluttertoast.showToast(
      msg: m,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // delete pop up
  void deleteModal(int customerID, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                //width: 150,
                height: 30,
                alignment: Alignment.bottomCenter,
                child: const Text(
                  'Delete Customer ?',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
                iconSize: 30,
                onPressed: () async {
                  await _dbhelper.deleteCustomer('customer_master', customerID);
                  setState(() {
                    Navigator.of(context).pop();
                    showWarning('Deleted $name');
                    clearAll();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // close button
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        //Navigator.pushNamed(context, '/homepage');
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                  ),
                  // title
                  Text(
                    'Customers',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                  // search button
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      onPressed: () {
                        clearAll();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchCustomer(
                              getCustomer: currentCustomer,
                              getCustomerID: currentCustomerID,
                              onSave: (updatedCustomer, updatedCustomerID) {
                                setState(
                                  ///\\\
                                  () {
                                    currentCustomer = updatedCustomer;
                                    currentCustomerID = updatedCustomerID;

                                    List<String> currentPhoneNumber =
                                        currentCustomer['customer_phone']
                                            .split(' ');
                                    String currentIsoCode =
                                        PhoneNumber.getISO2CodeByPrefix('+91')!;
                                    if (currentPhoneNumber.length >= 2 &&
                                        currentPhoneNumber[0][0] == '+') {
                                      currentIsoCode =
                                          PhoneNumber.getISO2CodeByPrefix(
                                              currentPhoneNumber[0])!;
                                      phone.text = currentPhoneNumber
                                          .sublist(1)
                                          .join(' ');
                                    } else {
                                      phone.text =
                                          currentCustomer['customer_phone'];
                                    }
                                    phoneNumberIsoCode =
                                        PhoneNumber(isoCode: currentIsoCode);
                                    name.text =
                                        currentCustomer['customer_name'];
                                    reference.text =
                                        currentCustomer['reference'];
                                    address.text =
                                        currentCustomer['customer_address'];
                                    balance.text =
                                        currentCustomer['customer_balance']
                                            .toString();
                                    _isEdit = true;
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.search,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              // heading line
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Divider(
                  thickness: 2.5,
                  color: _grey,
                  height: 35, // Space above and below the line
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // all customers
                  Expanded(
                    child: SizedBox(
                      height: 620,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: getCustomers(),
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

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No items found'),
                            );
                          }
                          final data = snapshot.data!;
                          return ListView.builder(
                            itemCount: data.length,
                            itemBuilder: (context, index) {
                              final customer = data[index];
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 15,
                                      right: 25,
                                      top: 10,
                                    ),
                                    child: ListTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: 250,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (customer['reference'] != '')
                                                  Text(
                                                    '${customer['customer_name']} (${customer['reference']})',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    '${customer['customer_name']}',
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                const SizedBox(height: 10),
                                                if (customer[
                                                        'customer_address'] !=
                                                    '')
                                                  Text(
                                                      'Address : ${customer['customer_address']}'),
                                              ],
                                            ),
                                          ),
                                          if (customer['customer_phone'] != '')
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.phone,
                                                  size: 20,
                                                ),
                                                Text(
                                                    '  :  ${customer['customer_phone']}')
                                              ],
                                            )
                                          else
                                            const SizedBox(
                                              width: 20,
                                            ),
                                          Text(
                                              'Balance : ${customer['customer_balance']}')
                                        ],
                                      ),
                                      onLongPress: () {
                                        deleteModal(customer['customer_id'],
                                            customer['customer_name']);
                                      },
                                      onTap: () {
                                        setState(() {
                                          _isEdit = true;
                                          List<String> currentPhoneNumber =
                                              customer['customer_phone']
                                                  .split(' ');
                                          String currentIsoCode =
                                              PhoneNumber.getISO2CodeByPrefix(
                                                  '+91')!;
                                          if (currentPhoneNumber.length >= 2 &&
                                              currentPhoneNumber[0][0] == '+') {
                                            currentIsoCode =
                                                PhoneNumber.getISO2CodeByPrefix(
                                                    currentPhoneNumber[0])!;
                                            phone.text = currentPhoneNumber
                                                .sublist(1)
                                                .join(' ');
                                          } else {
                                            phone.text =
                                                customer['customer_phone'];
                                          }

                                          //String num = PhoneNumber.getISO2CodeByPrefix("+91")!;
                                          phoneNumberIsoCode = PhoneNumber(
                                              isoCode: currentIsoCode);
                                          print('*#*#*#  $phoneNumberIsoCode');
                                          currentCustomerID =
                                              customer['customer_id'];
                                          name.text = customer['customer_name'];
                                          reference.text =
                                              customer['reference'];
                                          address.text =
                                              customer['customer_address'];
                                          //phone.text = currentPhoneNumber[1];
                                          balance.text =
                                              customer['customer_balance']
                                                  .toString();
                                        });
                                      },
                                    ),
                                  ),
                                  Divider(
                                    thickness: 0.5,
                                    color: _grey,
                                    height: 2,
                                    indent: 10,
                                    endIndent: 40,
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  // Customer Data
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Container(
                      width: 450,
                      height: 620,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_isEdit)
                                      Text(
                                        "${name.text}'s Details",
                                        style: const TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w500),
                                      )
                                    else
                                      const Text(
                                        'Customer Details',
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    IconButton(
                                      onPressed: () {
                                        if (!_isEdit) {
                                          clearAll();
                                        } else {
                                          if (name.text != '') {
                                            deleteModal(
                                                currentCustomerID, name.text);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.delete),
                                      iconSize: 30,
                                      color: Colors.red,
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Name : ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(
                                      width: 250,
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: name,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: _orange)),
                                          hintText: '...',
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Reference : ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(
                                      width: 250,
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: reference,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: _orange)),
                                          hintText: '...',
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Address : ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(
                                      width: 250,
                                      child: TextField(
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        controller: address,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: _orange)),
                                          hintText: '...',
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                //\\
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Phone Number : ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(
                                        width: 250,
                                        child: InternationalPhoneNumberInput(
                                          onInputChanged: (value) {
                                            print(value.dialCode);
                                            if (value.dialCode != null) {
                                              phoneNumberDialCode =
                                                  value.dialCode!;
                                            } else {
                                              phoneNumberDialCode = '+91';
                                            }
                                          },
                                          initialValue: phoneNumberIsoCode,
                                          selectorConfig: const SelectorConfig(
                                            selectorType:
                                                PhoneInputSelectorType.DIALOG,
                                            useBottomSheetSafeArea: true,
                                          ),
                                          ignoreBlank: false,
                                          textFieldController: phone,
                                          formatInput: true,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                              signed: true, decimal: true),
                                          inputDecoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide:
                                                  BorderSide(color: _orange),
                                            ),
                                          ),
                                          onSaved: (PhoneNumber number) {
                                            print(
                                                'On Saved: $number, ${phone.text}');
                                          },
                                          onFieldSubmitted: (value) {
                                            print(
                                                '*********************$phoneNumberIsoCode');
                                            /* print('submitted');
                                          String ph = "+91 9495669555";
                                          String num = PhoneNumber.getISO2CodeByPrefix("+91")!;
                                          print(num); */
                                          },
                                        )

                                        /* IntlPhoneField(
                                        controller: phone,
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _orange),
                                          ),
                                        ),
                                        initialCountryCode: 'IN',
                                        onChanged: (value) {
                                          print(value.completeNumber);
                                          phoneNumber = value.completeNumber;
                                        },
                                        onSubmitted: (newValue) {
                                          print(phone.text);
                                        },
                                      ) */

                                        /* TextField(
                                        controller: phone,
                                        keyboardType: TextInputType
                                            .number, // Only shows number keypad
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ], // Only allows digits
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide:
                                                BorderSide(color: _orange),
                                          ),
                                          hintText: '...',
                                        ),
                                      ), */
                                        )
                                  ],
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Balance : ',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(
                                      width: 250,
                                      child: TextField(
                                        controller: balance,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                            decimal:
                                                true), // Enables decimal input
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(
                                              r'^\d*\.?\d*')), // Allows digits and one decimal point
                                        ],
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide:
                                                BorderSide(color: _orange),
                                          ),
                                          hintText: '...',
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            // footer buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: MaterialButton(
                                    onPressed: () {
                                      clearAll();
                                      print(_isEdit);
                                    },
                                    color: Colors.white,
                                    height: 70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: _grey, width: 2),
                                    ),
                                    elevation: 0,
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 25,
                                ),
                                Expanded(
                                  child: MaterialButton(
                                    onPressed: () {
                                      print(currentCustomerID);
                                      if (name.text != '' &&
                                          balance.text != '') {
                                        currentCustomer['customer_name'] =
                                            name.text;
                                        currentCustomer['reference'] =
                                            reference.text;
                                        currentCustomer['customer_address'] =
                                            address.text;
                                        currentCustomer['customer_balance'] =
                                            num.parse(balance.text);
                                        if (phone.text.isNotEmpty) {
                                          currentCustomer['customer_phone'] =
                                              '$phoneNumberDialCode ${phone.text}';
                                        } else {
                                          currentCustomer['customer_phone'] =
                                              phone.text;
                                        }
                                        print(
                                            currentCustomer['customer_phone']);
                                        print(phoneNumberDialCode);
                                        if (_isEdit) {
                                          editCustomer();
                                        } else {
                                          addNewCustomer();
                                        }
                                      } else {
                                        showWarning('Enter Customer');
                                      }
                                    },
                                    color: _lightOrange,
                                    height: 70,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12), // Border radius
                                    ),
                                    elevation: 0,
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
