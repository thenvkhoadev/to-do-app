import 'package:flutter/material.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart' show DesktopTopbar;

class EditTaskDesktopLayout extends StatelessWidget {
  const EditTaskDesktopLayout({
    required this.header,
    required this.overview,
    required this.generalInfo,
    required this.subtasks,
    required this.attachments,
    required this.aiAnalysis,
    required this.assignees,
    required this.bottomBar,
    required this.xpPreviewCard,
    required this.dependenciesCard,
    required this.activityTimelineCard,
    required this.healthCard,
    required this.smartSchedule,
    super.key,
  });

  final Widget header;
  final Widget overview;
  final Widget generalInfo;
  final Widget subtasks;
  final Widget attachments;
  final Widget aiAnalysis;
  final Widget assignees;
  final Widget bottomBar;
  final Widget xpPreviewCard;
  final Widget dependenciesCard;
  final Widget activityTimelineCard;
  final Widget healthCard;
  final Widget smartSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08090A),
      child: Column(
        children: [
          const DesktopTopbar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(40, 32, 40, 120),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            const SizedBox(height: 32),
                            // Overview cards (Starts directly here as in test.html)
                            overview,
                            const SizedBox(height: 32),
                            
                            // Two column layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Primary Content (8 Cols)
                                Expanded(
                                  flex: 8,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      generalInfo,
                                      const SizedBox(height: 24),
                                      subtasks,
                                      const SizedBox(height: 24),
                                      attachments,
                                      const SizedBox(height: 24),
                                      dependenciesCard,
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                // Right Column: AI Insights & Health (4 Cols)
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      healthCard,
                                      const SizedBox(height: 24),
                                      aiAnalysis,
                                      const SizedBox(height: 24),
                                      xpPreviewCard,
                                      const SizedBox(height: 24),
                                      smartSchedule,
                                      const SizedBox(height: 24),
                                      assignees,
                                      const SizedBox(height: 24),
                                      activityTimelineCard,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Sticky Floating Action Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: bottomBar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditTaskTabletLayout extends StatelessWidget {
  const EditTaskTabletLayout({
    required this.header,
    required this.overview,
    required this.generalInfo,
    required this.subtasks,
    required this.attachments,
    required this.aiAnalysis,
    required this.assignees,
    required this.bottomBar,
    required this.xpPreviewCard,
    required this.dependenciesCard,
    required this.activityTimelineCard,
    required this.healthCard,
    required this.smartSchedule,
    super.key,
  });

  final Widget header;
  final Widget overview;
  final Widget generalInfo;
  final Widget subtasks;
  final Widget attachments;
  final Widget aiAnalysis;
  final Widget assignees;
  final Widget bottomBar;
  final Widget xpPreviewCard;
  final Widget dependenciesCard;
  final Widget activityTimelineCard;
  final Widget healthCard;
  final Widget smartSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF08090A),
      child: Column(
        children: [
          const DesktopTopbar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: 24),
                        overview,
                        const SizedBox(height: 24),
                        
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  generalInfo,
                                  const SizedBox(height: 20),
                                  subtasks,
                                  const SizedBox(height: 20),
                                  attachments,
                                  const SizedBox(height: 20),
                                  dependenciesCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  healthCard,
                                  const SizedBox(height: 20),
                                  aiAnalysis,
                                  const SizedBox(height: 20),
                                  xpPreviewCard,
                                  const SizedBox(height: 20),
                                  smartSchedule,
                                  const SizedBox(height: 20),
                                  assignees,
                                  const SizedBox(height: 20),
                                  activityTimelineCard,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: bottomBar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditTaskMobileLayout extends StatelessWidget {
  const EditTaskMobileLayout({
    required this.header,
    required this.overview,
    required this.generalInfo,
    required this.subtasks,
    required this.attachments,
    required this.aiAnalysis,
    required this.assignees,
    required this.bottomBar,
    super.key,
  });

  final Widget header;
  final Widget overview;
  final Widget generalInfo;
  final Widget subtasks;
  final Widget attachments;
  final Widget aiAnalysis;
  final Widget assignees;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090A),
      appBar: null,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 16),
              overview,
              const SizedBox(height: 16),
              generalInfo,
              const SizedBox(height: 16),
              assignees,
              const SizedBox(height: 16),
              subtasks,
              const SizedBox(height: 16),
              attachments,
              const SizedBox(height: 16),
              aiAnalysis,
            ],
          ),
        ),
      ),
    );
  }
}

