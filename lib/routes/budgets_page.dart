import "package:flow/data/flow_icon.dart";
import "package:flow/entity/budget.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/objectbox.g.dart";
import "package:flow/widgets/budget_card.dart";
import "package:flow/widgets/general/button.dart";
import "package:flow/widgets/general/empty_state.dart";
import "package:flow/widgets/general/spinner.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons/symbols.dart";

enum _BudgetFilter { all, active, inactive }

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  _BudgetFilter _filter = _BudgetFilter.all;

  QueryBuilder<Budget> _qb() =>
      ObjectBox().box<Budget>().query().order(Budget_.createdDate);

  List<Budget> _applyFilter(List<Budget> budgets) {
    final DateTime now = DateTime.now();
    return switch (_filter) {
      _BudgetFilter.all => budgets,
      _BudgetFilter.active =>
        budgets.where((b) => b.timeRange.contains(now)).toList(),
      _BudgetFilter.inactive =>
        budgets.where((b) => !b.timeRange.contains(now)).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("budgets".t(context))),
      body: SafeArea(
        child: StreamBuilder<List<Budget>>(
          stream: _qb()
              .watch(triggerImmediately: true)
              .map((event) => event.find()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Spinner.center();
            }

            final List<Budget> all = snapshot.requireData;
            final List<Budget> filtered = _applyFilter(all);

            return Column(
              children: [
                _FilterRow(
                  current: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                Expanded(
                  child: switch ((all.isEmpty, filtered.isEmpty)) {
                    (true, _) => EmptyState(
                      icon: FlowIconData.icon(Symbols.account_balance_wallet_rounded),
                      title: Text("budget.noBudgets".t(context)),
                      trailing: Button(
                        onTap: () => context.push("/budget/new"),
                        leading: const Icon(Symbols.add_rounded),
                        child: Text("budget.new".t(context)),
                      ),
                    ),
                    (false, true) => EmptyState(
                      icon: FlowIconData.icon(Symbols.filter_alt_rounded),
                      title: Text(
                        _filter == _BudgetFilter.active
                            ? "budget.noActiveBudgets".t(context)
                            : "budget.noInactiveBudgets".t(context),
                      ),
                    ),
                    _ => ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        Button(
                          onTap: () => context.push("/budget/new"),
                          leading: const Icon(Symbols.add_rounded),
                          child: Text("budget.new".t(context)),
                        ),
                        const SizedBox(height: 16.0),
                        ...filtered.map(
                          (budget) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: BudgetCard(budget: budget),
                          ),
                        ),
                      ],
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final _BudgetFilter current;
  final ValueChanged<_BudgetFilter> onChanged;

  const _FilterRow({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        spacing: 8.0,
        children: _BudgetFilter.values.map((filter) {
          final String label = switch (filter) {
            _BudgetFilter.all => "budget.all".t(context),
            _BudgetFilter.active => "budget.active".t(context),
            _BudgetFilter.inactive => "budget.inactive".t(context),
          };
          return FilterChip(
            label: Text(label),
            selected: current == filter,
            onSelected: (_) => onChanged(filter),
          );
        }).toList(),
      ),
    );
  }
}
