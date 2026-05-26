import 'package:flutter/material.dart';

class CalendarMobileLayout extends StatelessWidget {
  const CalendarMobileLayout({
    required this.title,
    required this.weekSelector,
    required this.timelineAgenda,
    required this.bottomNavigation,
    this.onAdd,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget weekSelector;
  final Widget timelineAgenda;
  final Widget bottomNavigation;
  final VoidCallback? onAdd;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: 88 + MediaQuery.paddingOf(context).top),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 118 + bottomInset),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalendarGlassPanel(child: weekSelector),
                    const SizedBox(height: 18),
                    CalendarGlassPanel(child: timelineAgenda),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CalendarMobileAppBar(title: title, actions: actions),
        ),
        Positioned(
          right: 20,
          bottom: 86 + bottomInset,
          child: CalendarMobileFab(onPressed: onAdd),
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: bottomNavigation),
      ],
    );
  }
}

class CalendarMobileAppBar extends StatelessWidget {
  const CalendarMobileAppBar({
    required this.title,
    this.actions = const [],
    super.key,
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .62),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: .08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class CalendarHorizontalWeekSelector extends StatelessWidget {
  const CalendarHorizontalWeekSelector({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class CalendarTimelineAgenda extends StatelessWidget {
  const CalendarTimelineAgenda({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Agenda',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class CalendarMobileFab extends StatelessWidget {
  const CalendarMobileFab({this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 12,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      child: const Icon(Icons.add_rounded),
    );
  }
}

class CalendarGlassPanel extends StatelessWidget {
  const CalendarGlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .56),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}
