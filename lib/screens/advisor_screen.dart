import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/advisor_service.dart';
import '../services/finance_service.dart';
import '../theme/app_theme.dart';

/// AI financial consultant: chat about purchases, loans, and investments,
/// grounded in the user's real data, with a visual impact report for
/// final recommendations.
class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _starterPrompts = [
    'Can I buy a laptop for \$1,800 now or should I wait?',
    'Is it a good time to take a loan?',
    'How much can I safely invest this month?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final advisor = context.read<AdvisorService>();
    final finance = context.read<FinanceService>();
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    advisor.send(text, finance);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppTheme.motionMedium,
          curve: AppTheme.motionCurve,
        );
      }
    });
  }

  void _openHistory(BuildContext context, AdvisorService advisor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => _HistorySheet(advisor: advisor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdvisorService>(
      builder: (context, advisor, _) {
        _scrollToBottom();
        return Scaffold(
          appBar: AppBar(
            flexibleSpace: Theme.of(context).brightness == Brightness.dark
                ? Container(
                    decoration:
                        const BoxDecoration(gradient: AppTheme.primaryGradient))
                : null,
            title: const Text('Advisor'),
            automaticallyImplyLeading: false,
            actions: [
              if (advisor.history.isNotEmpty)
                IconButton(
                  tooltip: 'Chat history',
                  icon: const Icon(Icons.history),
                  onPressed: () => _openHistory(context, advisor),
                ),
              if (advisor.messages.isNotEmpty)
                IconButton(
                  tooltip: 'New chat',
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: advisor.startNewChat,
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: advisor.messages.isEmpty
                    ? _EmptyState(onPromptTap: (p) => _send(p))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: advisor.messages.length +
                            (advisor.isThinking ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == advisor.messages.length) {
                            return const _ThinkingBubble();
                          }
                          final msg = advisor.messages[i];
                          return _MessageBubble(message: msg)
                              .animate()
                              .fadeIn(duration: 250.ms)
                              .slideY(begin: 0.1);
                        },
                      ),
              ),
              if (advisor.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.rose, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          advisor.error!,
                          style: const TextStyle(
                              color: AppTheme.rose, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              _InputBar(
                controller: _controller,
                enabled: !advisor.isThinking,
                onSend: _send,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onPromptTap;
  const _EmptyState({required this.onPromptTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 32),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.greenAccentGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.glowShadow(AppTheme.primary),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 34),
        ).animate().scale(duration: 400.ms, curve: AppTheme.motionCurve),
        const SizedBox(height: 20),
        Text(
          'Your Financial Consultant',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Ask about purchases, loans, or investments.\nAdvice is based on your real budgets, income and goals.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        ..._AdvisorScreenState._starterPrompts.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PromptChip(
                  text: e.value,
                  onTap: () => onPromptTap(e.value),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 150 + e.key * 80))
                    .slideY(begin: 0.2),
              ),
            ),
      ],
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PromptChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 16, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final AdvisorMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.greenAccentGradient : null,
                color: isUser
                    ? null
                    : (isDark ? AppTheme.surfaceVariant : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusMd),
                  topRight: const Radius.circular(AppTheme.radiusMd),
                  bottomLeft: Radius.circular(isUser ? AppTheme.radiusMd : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppTheme.radiusMd),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline),
              ),
              child: SelectableText(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      height: 1.5,
                    ),
              ),
            ),
          ),
        if (message.impact != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ImpactCard(report: message.impact!),
          ),
      ],
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceVariant : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Text('Analyzing your finances…',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
        begin: 0.6, end: 1, duration: 700.ms);
  }
}

// ── Impact report card ───────────────────────────────────────────────────────
class _ImpactCard extends StatelessWidget {
  final ImpactReport report;
  const _ImpactCard({required this.report});

  Color get _verdictColor => switch (report.verdict) {
        'go' => AppTheme.primary,
        'avoid' => AppTheme.rose,
        _ => AppTheme.amber,
      };

  String get _verdictLabel => switch (report.verdict) {
        'go' => 'GOOD TO GO',
        'avoid' => 'NOT ADVISED',
        _ => 'WAIT',
      };

  IconData get _verdictIcon => switch (report.verdict) {
        'go' => Icons.check_circle,
        'avoid' => Icons.cancel,
        _ => Icons.schedule,
      };

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceService>();
    final symbol = finance.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: _verdictColor.withValues(alpha: 0.5)),
        boxShadow: AppTheme.glowShadow(_verdictColor, opacity: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verdict header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _verdictColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_verdictIcon, color: _verdictColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _verdictLabel,
                      style: TextStyle(
                        color: _verdictColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.title,
              style: Theme.of(context).textTheme.headlineSmall),
          if (report.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(report.summary,
                style: Theme.of(context).textTheme.bodySmall),
          ],
          if (report.oneTimeCost != null || report.monthlyCost != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (report.oneTimeCost != null)
                  _CostPill(
                      label: 'One-time',
                      value:
                          '$symbol${report.oneTimeCost!.toStringAsFixed(0)}'),
                if (report.oneTimeCost != null && report.monthlyCost != null)
                  const SizedBox(width: 8),
                if (report.monthlyCost != null)
                  _CostPill(
                      label: 'Monthly',
                      value:
                          '$symbol${report.monthlyCost!.toStringAsFixed(0)}/mo'),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Now vs After comparison
          Text('IMPACT ON YOUR FINANCES',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(letterSpacing: 1)),
          const SizedBox(height: 10),
          _CompareRow(
            label: 'Net savings / month',
            before: '$symbol${report.current.netSavings.toStringAsFixed(0)}',
            after: '$symbol${report.projected.netSavings.toStringAsFixed(0)}',
            worse: report.projected.netSavings < report.current.netSavings,
          ),
          _CompareRow(
            label: 'Budget used',
            before: '${report.current.budgetUsedPct.toStringAsFixed(0)}%',
            after: '${report.projected.budgetUsedPct.toStringAsFixed(0)}%',
            worse:
                report.projected.budgetUsedPct > report.current.budgetUsedPct,
          ),
          _CompareRow(
            label: 'Emergency buffer',
            before: '${report.current.bufferMonths.toStringAsFixed(1)} mo',
            after: '${report.projected.bufferMonths.toStringAsFixed(1)} mo',
            worse:
                report.projected.bufferMonths < report.current.bufferMonths,
          ),
          _CompareRow(
            label: 'Health score',
            before: report.current.healthScore.toStringAsFixed(0),
            after: report.projected.healthScore.toStringAsFixed(0),
            worse:
                report.projected.healthScore < report.current.healthScore,
          ),

          // Savings timeline chart
          if (report.timeline.length >= 2) ...[
            const SizedBox(height: 18),
            Text('PROJECTED SAVINGS',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(letterSpacing: 1)),
            const SizedBox(height: 12),
            SizedBox(height: 160, child: _TimelineChart(report: report)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: AppTheme.sky, label: 'Without'),
                const SizedBox(width: 16),
                _LegendDot(color: _verdictColor, label: 'With decision'),
              ],
            ),
          ],

          // Suggestions
          if (report.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('SUGGESTIONS',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(letterSpacing: 1)),
            const SizedBox(height: 8),
            ...report.suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.arrow_right,
                          size: 16, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(s,
                            style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CostPill extends StatelessWidget {
  final String label;
  final String value;
  const _CostPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontSize: 10)),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppTheme.primary)),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String before;
  final String after;
  final bool worse;

  const _CompareRow({
    required this.label,
    required this.before,
    required this.after,
    required this.worse,
  });

  @override
  Widget build(BuildContext context) {
    final afterColor = worse ? AppTheme.rose : AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child:
                Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(before, style: Theme.of(context).textTheme.titleSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward,
                size: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
          ),
          Text(
            after,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: afterColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TimelineChart extends StatelessWidget {
  final ImpactReport report;
  const _TimelineChart({required this.report});

  @override
  Widget build(BuildContext context) {
    final points = report.timeline;
    final verdictColor = switch (report.verdict) {
      'go' => AppTheme.primary,
      'avoid' => AppTheme.rose,
      _ => AppTheme.amber,
    };

    LineChartBarData line(List<double> ys, Color color) => LineChartBarData(
          spots: [
            for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i]),
          ],
          isCurved: true,
          curveSmoothness: 0.3,
          color: color,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.08),
          ),
        );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    points[i].label.length > 3
                        ? points[i].label.substring(0, 3)
                        : points[i].label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          line([for (final p in points) p.without], AppTheme.sky),
          line([for (final p in points) p.withDecision], verdictColor),
        ],
      ),
    );
  }
}

// ── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // Leave room above the floating nav bar.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Ask about a purchase, loan, or investment…',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.greenAccentGradient,
                shape: BoxShape.circle,
                boxShadow:
                    enabled ? AppTheme.glowShadow(AppTheme.primary) : null,
              ),
              child: IconButton(
                onPressed: enabled ? onSend : null,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History sheet ────────────────────────────────────────────────────────────
class _HistorySheet extends StatelessWidget {
  final AdvisorService advisor;
  const _HistorySheet({required this.advisor});

  @override
  Widget build(BuildContext context) {
    final chats = advisor.history;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text('Chat History',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            Flexible(
              child: chats.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('No past conversations yet.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final chat = chats[i];
                        return _HistoryTile(
                          chat: chat,
                          onOpen: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              AppTheme.slideRoute(
                                _ArchivedChatView(
                                    advisor: advisor, chat: chat),
                              ),
                            );
                          },
                          onDelete: () => advisor.deleteChat(chat.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ArchivedChat chat;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.chat,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppTheme.surfaceVariant : Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border:
                Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy · h:mm a').format(chat.date),
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4)),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Archived conversation viewer ─────────────────────────────────────────────
class _ArchivedChatView extends StatelessWidget {
  final AdvisorService advisor;
  final ArchivedChat chat;

  const _ArchivedChatView({required this.advisor, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Theme.of(context).brightness == Brightness.dark
            ? Container(
                decoration:
                    const BoxDecoration(gradient: AppTheme.primaryGradient))
            : null,
        title: const Text('Past Advice'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: AppTheme.primary.withValues(alpha: 0.08),
            child: Text(
              DateFormat('EEEE, MMM d, yyyy · h:mm a').format(chat.date),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: chat.messages.length,
              itemBuilder: (context, i) =>
                  _MessageBubble(message: chat.messages[i]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Continue with today's finances"),
                  onPressed: () {
                    advisor.resumeChat(chat.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Conversation reopened — new advice will use your current finances.'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
