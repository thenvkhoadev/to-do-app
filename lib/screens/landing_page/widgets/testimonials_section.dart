import 'package:flutter/material.dart';
import 'design_system.dart';
import 'testimonial_card.dart';

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  late final ScrollController _scrollController;
  bool _scrolling = true;

  final List<Map<String, String>> _items = [
    {
      'text': 'Nexus AI didn\'t just organize my tasks; it changed how I perceive productivity. The XP system is weirdly addictive.',
      'name': 'Erik Larsson',
      'role': 'CTO at TechFlow',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuC8jB1xqV6Xx8RYSbbtZT0UznnDP4_uIzjqqz-WH-i8lSEbSSoV9K7vYI_3ybCRgvUBsJOSpL7w2ztxD0cHdOdIE75udrhTyRGKeRMRTfBsj5PN-o3MscS8LsNYND_gzVkSweBcR9MzpFI8LYFCFDtXPcFpjaH9iWfBCxHOD7xwPXB-UGjLPST2YSoFar2MQZHpROfK9o-uf-lbyioAMTdibygrXhDo2_NgVmAnms9zKuCkf5ZDakEM3kwcasWPMdWCmGfk6khUDuBm',
    },
    {
      'text': 'The AI Intelligence feature is spooky accurate. It knows when I\'m burning out before I even do.',
      'name': 'Sarah Chen',
      'role': 'Creative Director at Nexus',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDAV_yAvjti-YJ11VtAFmMUljDq8EZ1yFLrDbmkMP6ttJN_uaJxBn69kvELjoW7kQQQ8AGkRCWuM8sYmyaM6YxMmbb3tt3fpG6Ts1p7ybai2oVthtuF_9UAzMWHskyaGu_ACK8cQx74P-ooE7ofKTtIVcRjmhhnl0DL0pHSNNODq3WtrWJQE6qHRzeFMouQ8IxUbd-yEe3kgg9rpw2_abiDpj5kEUvOJ2QyLi45HyPpgCkR1vK3dYHAOlFUO5pMuqnv0g-H56io7LZo',
    },
    {
      'text': 'Finally, a tool that respects the flow state. The glassmorphism UI is just the icing on the cake.',
      'name': 'James Miller',
      'role': 'Product Manager',
      'avatar': 'https://lh3.googleusercontent.com/aida-public/AB6AXuA4qd4reM7GVwKDg_tZPDel9UVpH5__pKrhqWBZfNtCwMFGQrMyolJ5jLBxVYK42bQZIDpcwLUZhgslH82kSSkRacNWfwWzmLlOfoPccSSq6sllWYVWYa_f275r3WzULG-NCvb6YqwgEIGkf90E1ZqdrypU4GEKpZvABMh-tALiRvypx_eA-paIwkDw2rcaw-ARve0vgCnV-CCv_HAOEbxjkBXvZ5Pabyujr83SlxJ1wSKM32UZNgYJ2uwZe99Kv6XSjGvyIoNe8x3k',
    },
  ];

  late final List<Map<String, String>> _marqueeItems;

  @override
  void initState() {
    super.initState();
    // Repeat items 4 times to fill screen buffer and scroll smoothly
    _marqueeItems = [..._items, ..._items, ..._items, ..._items];
    _scrollController = ScrollController();
    
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final currentScroll = _scrollController.position.pixels;
      final double setWidth = (360.0 + 24.0) * 3; // Width + gap of one complete set of testimonials
      
      // If we scroll past the second set, reset back to the first set seamlessly
      if (currentScroll >= setWidth * 2) {
        _scrollController.jumpTo(currentScroll - setWidth);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    if (!mounted || !_scrolling) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final remainingDistance = maxScroll - currentScroll;
    
    // Constant speed of 30 pixels per second
    final durationMs = (remainingDistance / 30.0) * 1000;
    
    if (durationMs > 0) {
      _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: durationMs.toInt()),
        curve: Curves.linear,
      ).then((_) {
        if (mounted && _scrolling) {
          // If we completed scroll, reset to beginning (listener will handle adjustments)
          _scrollController.jumpTo(0);
          _startScrolling();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrolling = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        children: [
          // Header
          Text(
            'What Power Users Say',
            style: getLandingGeistStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.w600,
              color: LandingColors.textPrimary,
              letterSpacing: -0.64,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32.0),

          // Carousel
          MouseRegion(
            onEnter: (_) {
              setState(() {
                _scrolling = false;
              });
              _scrollController.position.hold(() {}); // Pause scroll animation
            },
            onExit: (_) {
              setState(() {
                _scrolling = true;
              });
              _startScrolling(); // Resume scroll animation
            },
            child: SizedBox(
              height: 280.0,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(), // User can still swipe/drag
                itemCount: _marqueeItems.length,
                itemBuilder: (context, index) {
                  final item = _marqueeItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: TestimonialCard(
                      text: item['text']!,
                      name: item['name']!,
                      role: item['role']!,
                      avatarUrl: item['avatar']!,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
