import "package:flow/entity/budget.dart";
import "package:flow/l10n/extensions.dart";
import "package:flow/theme/theme.dart";
import "package:flow/widgets/general/surface.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";
import "package:moment_dart/moment_dart.dart";

class BudgetCard extends StatelessWidget {
  final Budget budget;

  final BorderRadius borderRadius;

  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    this.onTap,
    this.borderRadius = const .all(Radius.circular(16.0)),
  });

  @override
  Widget build(BuildContext context) {
    final TimeRange timeRange = budget.timeRange;
    final bool isActive = timeRange.contains(DateTime.now());

    final String rangeLabel = timeRange.format();

    return Surface(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      builder: (context) => InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                isActive
                    ? Symbols.check_circle_rounded
                    : Symbols.cancel_rounded,
                color: isActive
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withAlpha(0x80),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      budget.name,
                      style: context.textTheme.titleSmall,
                    ),
                    Text(
                      rangeLabel,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurface.withAlpha(0x99),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: .end,
                children: [
                  Text(
                    "${budget.currency} ${budget.amount.toStringAsFixed(2)}",
                    style: context.textTheme.titleSmall,
                  ),
                  Text(
                    isActive
                        ? "budget.active".t(context)
                        : "budget.inactive".t(context),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface.withAlpha(0x80),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
