import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nissy_bakes_app/database/dbhelper.dart';

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  final DbHelper _dbHelper = DbHelper();
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding:
            const EdgeInsets.only(top: 30, bottom: 20, left: 10, right: 10),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 10),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Divider(
                thickness: 2,
                color: _grey,
                height: 10,
                indent: 10,
                endIndent: 10,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                onTap: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/customers');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pushNamed(context, '/menuitemspage');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: const Row(
                  children: [
                    Icon(
                      Icons.storage,
                      size: 30,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      'Database Backup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _dbHelper.copyDatabaseToDesktop();
                  Fluttertoast.showToast(
                    msg: 'Database Copied !!',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 20,
                  );
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
