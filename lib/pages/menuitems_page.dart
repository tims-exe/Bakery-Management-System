import 'package:flutter/material.dart';

class MenuitemsPage extends StatefulWidget {
  const MenuitemsPage({super.key});

  @override
  State<MenuitemsPage> createState() => _MenuitemsPageState();
}

class _MenuitemsPageState extends State<MenuitemsPage> {
  final Color _orange = const Color.fromRGBO(230, 84, 0, 1);
  final Color _lightOrange = const Color.fromRGBO(255, 168, 120, 1);
  final Color _grey = const Color.fromARGB(255, 212, 212, 212);

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
                        Navigator.pushNamed(context, '/homepage');
                      },
                      icon: const Icon(Icons.arrow_back),
                      iconSize: 30,
                    ),
                  ),
                  // title
                  Text(
                    'Menu Item',
                    style: TextStyle(
                      fontSize: 30,
                      color: _orange,
                    ),
                  ),
                  // search button
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: IconButton(
                      onPressed: () {},
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
                  height: 35,
                ),
              ),
              // Two sections with vertical divider
              SizedBox(
                height: MediaQuery.of(context).size.height -
                    150, // Adjust height as needed
                child: Row(
                  children: [
                    // Left section
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Section 1',
                              style: TextStyle(
                                fontSize: 20,
                                color: _orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Add your left section content here
                        ],
                      ),
                    ),
                    // Vertical Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: VerticalDivider(
                        thickness: 2.5,
                        color: _grey,
                        width: 40,
                      ),
                    ),
                    // Right section
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Section 2',
                              style: TextStyle(
                                fontSize: 20,
                                color: _orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Add your right section content here
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
