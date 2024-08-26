import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class Destination {
  const Destination(this.title, this.page, this.icon);
  final String title;
  final String page;
  final IconData icon;
}

class NavShell extends StatefulWidget {
  final Widget child;

  const NavShell({super.key, required this.child});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _focusDestination = 0;

  final List<Destination> _allDestinations = <Destination>[
    Destination('explore'.tr, 'explore', Icons.explore),
    Destination('settings'.tr, 'settings', Icons.settings)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        currentIndex: _focusDestination,
        items: _allDestinations
            .map((x) => BottomNavigationBarItem(
                  icon: Icon(x.icon),
                  label: x.title,
                ))
            .toList(),
        onTap: (value) {
          GoRouter.of(context).goNamed(_allDestinations[value].page);
          setState(() => _focusDestination = value);
        },
      ),
    );
  }
}
