import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_state.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_sidebar.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_chat_window.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_info_panel.dart';
import 'package:to_do_app/features/social/presentation/widgets/messages/message_dialogs.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final leftWidth = ref.watch(leftSidebarWidthProvider);
    final rightWidth = ref.watch(rightSidebarWidthProvider);
    final rightVisible = ref.watch(isRightSidebarVisibleProvider);
    final activeId = ref.watch(activeThreadIdProvider);
    final isCallActive = ref.watch(isCallActiveProvider);
    final isCallMinimized = ref.watch(isCallMinimizedProvider);
    final showCallFullscreen = isCallActive && !isCallMinimized;
    final videoViewer = ref.watch(activeVideoViewerProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          // Trigger search bar focus via search state
          ref.read(isSearchFocusedProvider.notifier).state = true;
        },
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          showDialog(
            context: context,
            builder: (_) => const CreateChatDialog(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          // Pop any dialogs or clear selection
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const DesktopTopbar(),
            Expanded(
              child: Container(
                color: const Color(0xFF18191A),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Column 1: Left Conversations Sidebar (hidden if full screen call overlay)
                        if (!showCallFullscreen) ...[
                          SizedBox(
                            width: leftWidth,
                            child: const MessageSidebar(),
                          ),
                          
                          // Left Resize Handle
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              final newWidth = (leftWidth + details.delta.dx).clamp(280.0, 400.0);
                              ref.read(leftSidebarWidthProvider.notifier).state = newWidth;
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: Container(
                                width: 4,
                                color: const Color(0xFF303031),
                              ),
                            ),
                          ),
                        ],

                        // Column 2: Center Chat Window
                        const Expanded(
                          child: MessageChatWindow(),
                        ),

                        // Right Resize Handle & Column 3: Info Panel (hidden if full screen call overlay)
                        if (!showCallFullscreen && activeId != null && rightVisible) ...[
                          GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              // Dragging right changes width (negative delta adds width for right-anchored panel)
                              final newWidth = (rightWidth - details.delta.dx).clamp(280.0, 360.0);
                              ref.read(rightSidebarWidthProvider.notifier).state = newWidth;
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: Container(
                                width: 4,
                                color: const Color(0xFF303031),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: rightWidth,
                            child: const MessageInfoPanel(),
                          ),
                        ],
                      ],
                    ),
                    if (videoViewer != null)
                      Positioned.fill(
                        child: ChatVideoViewer(viewerState: videoViewer),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
