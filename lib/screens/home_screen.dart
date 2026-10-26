import 'package:flutter/material.dart';
import 'package:admin_gudang/screens/master_barang_screen.dart';
import 'package:admin_gudang/screens/master_kategori_screen.dart';
import 'package:admin_gudang/screens/transaksi_screen.dart';
import 'package:admin_gudang/screens/import_screen.dart';
import 'package:admin_gudang/screens/laporan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    MasterBarangScreen(),
    MasterKategoriScreen(),
    TransaksiScreen(),
    ImportScreen(),
    LaporanScreen(),
  ];

  static const _navItems = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Master Barang'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: Text('Kategori'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.swap_horiz_outlined),
      selectedIcon: Icon(Icons.swap_horiz),
      label: Text('Transaksi'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.upload_file_outlined),
      selectedIcon: Icon(Icons.upload_file),
      label: Text('Import'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.assessment_outlined),
      selectedIcon: Icon(Icons.assessment),
      label: Text('Laporan'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            extended: MediaQuery.of(context).size.width > 900,
            destinations: _navItems,
            labelType: MediaQuery.of(context).size.width > 900
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.warehouse, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 4),
                  const Text('Gudang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
