import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/tx_filter.dart';
import 'package:account_new/providers/transaction_provider.dart';
import 'package:account_new/screens/detail/detail_screen.dart';
import 'package:account_new/screens/detail/transaction_edit_screen.dart';
import 'package:account_new/screens/profile/profile_screen.dart';
import 'package:account_new/screens/stats/stats_screen.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hosts the three primary tabs and the "记一笔" floating button.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => RootShellState();
}

class RootShellState extends State<RootShell> {
  int _index = 0;

  void selectTab(int index) => setState(() => _index = index);

  /// Switches to the 明细 tab and filters it by [categoryId].
  void openCategoryInDetail(int? categoryId) {
    final tx = context.read<TransactionProvider>();
    setState(() => _index = 0);
    tx.setFilter(TxFilter(
      categoryIds: categoryId == null ? const <int>{} : {categoryId},
    ));
  }

  Future<void> openAddEntry() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TransactionEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final selecting = context.select<TransactionProvider, bool>(
        (provider) => provider.selectionActive);
    final showFab = _index == 0 && !selecting;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ImmersiveBackground(brightness: brightness),
          ),
          IndexedStack(
            index: _index,
            children: const [
              DetailScreen(),
              StatsScreen(),
              ProfileScreen(),
            ],
          ),
        ],
      ),
      floatingActionButton: IgnorePointer(
        ignoring: !showFab,
        child: AnimatedOpacity(
          opacity: showFab ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: showFab ? 1 : 0.8,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: FloatingActionButton.extended(
              onPressed: openAddEntry,
              icon: const Icon(Icons.add),
              label: Text(t.t('add_entry')),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: t.t('tab_detail'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: t.t('tab_stats'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.t('tab_profile'),
          ),
        ],
      ),
    );
  }
}
