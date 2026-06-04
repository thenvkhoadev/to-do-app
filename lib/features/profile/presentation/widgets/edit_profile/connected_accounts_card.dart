import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'edit_profile_shared.dart';

class ConnectedAccountsCard extends StatefulWidget {
  const ConnectedAccountsCard({super.key});

  @override
  State<ConnectedAccountsCard> createState() => _ConnectedAccountsCardState();
}

class _ConnectedAccountsCardState extends State<ConnectedAccountsCard> {
  final Map<String, _IntegrationState> _integrations = {
    'GitHub': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/github/github-original.svg',
      status: 'Synced',
      isConnected: true,
      isInvert: true,
    ),
    'Google': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/google/google-original.svg',
      status: 'Link',
      isConnected: false,
    ),
    'Slack': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/slack/slack-original.svg',
      status: 'Synced',
      isConnected: true,
    ),
    'Discord': _IntegrationState(
      logoUrl: 'https://unpkg.com/simple-icons@v11.0.0/icons/discord.svg',
      status: 'Connect',
      isConnected: false,
    ),
    'Figma': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/figma/figma-original.svg',
      status: 'Connect',
      isConnected: false,
    ),
    'LinkedIn': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/linkedin/linkedin-original.svg',
      status: 'Connect',
      isConnected: false,
    ),
    'Microsoft': _IntegrationState(
      logoUrl: 'https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/microsoftsqlserver/microsoftsqlserver-plain.svg',
      status: 'Connect',
      isConnected: false,
    ),
  };

  void _toggleConnect(String name) {
    setState(() {
      final current = _integrations[name]!;
      if (current.isConnected) {
        _integrations[name] = current.copyWith(
          isConnected: false,
          status: 'Connect',
        );
      } else {
        _integrations[name] = current.copyWith(
          isConnected: true,
          status: 'Synced',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: EditProfileColors.primary),
              SizedBox(width: 12),
              Text(
                'Integrations',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // responsive column count:
              final columns = width > 500
                  ? 4
                  : width > 300
                      ? 3
                      : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: _integrations.length + 1, // + 1 for Add Button
                itemBuilder: (context, index) {
                  if (index == _integrations.length) {
                    return _buildAddButton();
                  }

                  final name = _integrations.keys.elementAt(index);
                  final integration = _integrations[name]!;

                  return _buildBrandCard(name, integration);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(String name, _IntegrationState integration) {
    return GestureDetector(
      onTap: () => _toggleConnect(name),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: integration.isConnected
                ? EditProfileColors.primary.withValues(alpha: 0.3)
                : EditProfileColors.borderSides,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: integration.isConnected ? 1.0 : 0.4,
              child: SizedBox(
                width: 40,
                height: 40,
                child: integration.logoUrl.endsWith('.svg')
                    ? SvgPicture.network(
                        integration.logoUrl,
                        colorFilter: integration.isInvert
                            ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                            : null,
                        fit: BoxFit.contain,
                        placeholderBuilder: (BuildContext context) => Icon(
                          Icons.broken_image,
                          color: EditProfileColors.textOutline,
                          size: 20,
                        ),
                      )
                    : Image.network(
                        integration.logoUrl,
                        color: integration.isInvert ? Colors.white : null,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: EditProfileColors.textOutline,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: EditProfileColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              integration.status.toUpperCase(),
              style: TextStyle(
                color: integration.isConnected
                    ? EditProfileColors.success
                    : EditProfileColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EditProfileColors.borderSides,
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: EditProfileColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}

class _IntegrationState {
  _IntegrationState({
    required this.logoUrl,
    required this.status,
    required this.isConnected,
    this.isInvert = false,
  });

  final String logoUrl;
  final String status;
  final bool isConnected;
  final bool isInvert;

  _IntegrationState copyWith({
    String? logoUrl,
    String? status,
    bool? isConnected,
    bool? isInvert,
  }) {
    return _IntegrationState(
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      isConnected: isConnected ?? this.isConnected,
      isInvert: isInvert ?? this.isInvert,
    );
  }
}
