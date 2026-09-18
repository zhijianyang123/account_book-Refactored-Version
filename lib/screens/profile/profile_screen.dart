import 'package:account_new/l10n/app_localizations.dart';
import 'package:account_new/models/app_settings.dart';
import 'package:account_new/providers/settings_provider.dart';
import 'package:account_new/providers/stats_provider.dart';
import 'package:account_new/screens/data/data_manage_screen.dart';
import 'package:account_new/screens/manage/budget_manage_screen.dart';
import 'package:account_new/screens/manage/category_manage_screen.dart';
import 'package:account_new/screens/settings/about_screen.dart';
import 'package:account_new/screens/settings/settings_screen.dart';
import 'package:account_new/utils/money.dart';
import 'package:account_new/widgets/immersive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 我的 Tab.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = context
        .select<SettingsProvider, AppSettings>((provider) => provider.settings);
    final stats = context.watch<StatsProvider>();

    final expenseColor = Color(settings.expenseColor);
    final incomeColor = Color(settings.incomeColor);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
        children: [
          _topCard(context, t, stats, expenseColor, incomeColor),
          const SizedBox(height: 18),
          _groupLabel(context, t.t('group_records')),
          _group([
            _row(
              context,
              Icons.category_outlined,
              t.t('category_manage'),
              () => _open(context, const CategoryManageScreen()),
            ),
          ]),
          _groupLabel(context, t.t('group_plan')),
          _group([
            _row(
              context,
              Icons.savings_outlined,
              t.t('budget_manage'),
              () => _open(context, const BudgetManageScreen()),
            ),
          ]),
          _groupLabel(context, t.t('group_data')),
          _group([
            _row(
              context,
              Icons.folder_outlined,
              t.t('data_manage'),
              () => _open(context, const DataManageScreen()),
              subtitle: t.t('data_manage_sub'),
            ),
          ]),
          _groupLabel(context, t.t('group_settings')),
          _group([
            _row(
              context,
              Icons.settings_outlined,
              t.t('app_settings'),
              () => _open(context, const SettingsScreen()),
            ),
            _row(
              context,
              Icons.info_outline,
              t.t('about'),
              () => _open(context, const AboutScreen()),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _topCard(BuildContext context, AppLocalizations t, StatsProvider stats,
      Color expenseColor, Color incomeColor) {
    final scheme = Theme.of(context).colorScheme;
    return LightFollowCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      child: Column(
        children: [
          Row(
            children: [
              Text(t.t('profile_title'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: () => _open(context, const SettingsScreen()),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _stat(t.t('profile_this_month_expense'),
                  stats.currentMonthExpenseCents, expenseColor, scheme),
              _stat(t.t('profile_this_month_income'),
                  stats.currentMonthIncomeCents, incomeColor, scheme),
              _stat(
                t.t('balance'),
                stats.currentMonthBalanceCents,
                stats.currentMonthBalanceCents < 0
                    ? expenseColor
                    : scheme.onSurface,
                scheme,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(
                t.t('profile_budget_remaining'),
                stats.activeBudget == null ? null : stats.budgetRemainingCents,
                stats.budgetOverspent ? expenseColor : scheme.onSurface,
                scheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int? cents, Color color, ColorScheme scheme) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              cents == null ? '—' : Money.formatBalance(cents),
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 6, top: 14, bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _group(List<Widget> children) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1)
                const Divider(indent: 56, endIndent: 16),
            ],
          ],
        ),
      );

  Widget _row(BuildContext context, IconData icon, String title,
      VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
