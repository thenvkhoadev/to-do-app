import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ConnectedAccountsCard extends StatefulWidget {
  const ConnectedAccountsCard({super.key});

  @override
  State<ConnectedAccountsCard> createState() => _ConnectedAccountsCardState();
}

class _ConnectedAccountsCardState extends State<ConnectedAccountsCard> {
  final Map<String, _IntegrationState> _integrations = {
    'GitHub': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA1w_NMAQhniRNMchGKHOJS3JWF_DjeHM2bHxnhE3nTIPaGcSK3pQmUrFcSQ5n07ZBgBeSwgf0VXtA5mpZWVrRhQzXWGXsgiq-RjoUjEXOTI8-5-UabXPHMcX8-w7VBcPcwUTEq3ZnxQggJsTwWId1fOs6hpOfxsjJhPXF-41RKSEMnmn2rVP1AdRzHZE5XanG0Dc-TDYDkNjIBPlD32vHfB-cSe2kU5AFy_1HTbGp-JMrc6nl6qgmJYpFQj6KNehulPprB4nvzKXvP',
      status: 'Synced',
      isConnected: true,
      isInvert: true,
    ),
    'Google': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAYdsIHVyqiN9Iv-YgltsTddSR-pbJb5l3J7ZspD7eunQfaeHmUF5yi9PwEdCq9epWaDCj9V-EGuLtzMxqVRvSbhG79aEE0RCT7cwPsmOjnlPATPsEyKmp8J566tS2VLw_h0Y4x_Eokb7s7rqCTAzH4BOUXmEpakB9LETfI_EiTWAxIFAQnQIBAjob4JcniMF40rEudFec-Pys0IFbBiGIIieKzQTpAfCM7xH5Z1vCAPJ8-HmRzR4qvs_eHNYC1BO-WYomV9H_ustYn',
      status: 'Link',
      isConnected: false,
    ),
    'Slack': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCnv3UySAS7u8t4j2hEkeSn2fLbJN_6-ANoe7Vs07vnICHLRYCgPPYNjNdVBDmqe_GPzd6lNTiQ7tZt5Tj6-PTb2q9vMCnIZkTjrEY8aRturKKLuf8-V2xCYw8WF5bUUIwPxpGfbd4KEKclgOHqM1Sb-Qvwxbk6pGEe9dK6EhwIyULLI62sgJlBWN05UAJUsJ6cCGO2JgIKD06RerY5GCKveF1ux6ibcZ2_uCP7GX4-vC7uAMDX88wV-TcTLTLF0cwCsKHFXk8UC1GA',
      status: 'Synced',
      isConnected: true,
    ),
    'Discord': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCbtyEvtiOj-ZKXUOgeSmHzIjHPw0O03bm1HkJqy4CihAP0UvmRBL6Z0LwsFUCiQWNOBOwwvcH25EmCaFn3qLv9g9EQUqg6rsXXNFicX9ksalBXn5zE4_mHpVlleFluBJjieK33cOKAYtJbyXTYoJ2IaNakp1XmwDPk-Nes53KPkhMA06-euNU619h03ZsNTBpAXkeN8lwslVsC5K1VTnsAbbFjaCBd4hInfT_cY_eiLAWdFgLSJ3-R4cibS1w_LAn0J2VJjmpkPmN7',
      status: 'Connect',
      isConnected: false,
    ),
    'Figma': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBIskSmqmuRt94UkIYDDyObUrRI3--wvdafKEwKnYKYqYMas_XXNbxxTLRjgGS8bgjZCggyVxqLxWM6WSbkE6mDc8AMHRpR8WhhDPj4qdFLHeOsUfTBm55pfj8-elzRveQkxcKe3X7qYPKQ36AwMq_8zd4HvSZyKrV_9ULPpV6k48vQz4t3XUaYfiutPVU1tAMS_8NB0Y2W7xNd6wUsXPneT6AzHop_IPMyUjfIP1LzDTLAV5BCL0QNHJkqMRbX_EH2fj2mq-vs2I0V',
      status: 'Connect',
      isConnected: false,
    ),
    'LinkedIn': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA3-ND-BbrODiJsgJf_b_XD1iP7ZBArQp8ieU-QQY6s3J_VLnGzweLox7TqfHMIvcXC1oh2o3HVV_7rXZFLYNP3n8I3QJU2chMVS9aFG5QP1CyShnF-MSZj3EKNJLei2W3z8OKdVW-r-UWo9QMfD18pe2TiDe2vndmCizo9hwf921eWi1z1_4hPpbdUw2nd2lm9cXKH4pqW6zeLgZi_9uaHYZEpFWCaRf0OSX1wNHBv-MatlVAjrIB75PegvfJDN0m1ItmJcYVS20Rq',
      status: 'Connect',
      isConnected: false,
    ),
    'Microsoft': _IntegrationState(
      logoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCBqAMZCkrGIsu7CybiwE7QgaQdxUHll2XBIKZLZcK_0S1aBBJxSDk6NoZggcnrzX0CSyOZ_ilvZc-tyk9ODRbJYK-5CV4QIML60lcTP3u88KK-PFX_-cfQuxzX_IPDfvq6kpUfM4NNoTU2sHIfBlNOWpeT8xYMxhvbWXurmL9V-RY1w-7HXvbfZqebFtUob3hsni6kB6gBDWjqKR6__XxzY3E0glZJhHgKK2vsJJUJSNneAhKGuUBInYq993pfLDeZfqy1bIKQwQwC',
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
                child: Image.network(
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
