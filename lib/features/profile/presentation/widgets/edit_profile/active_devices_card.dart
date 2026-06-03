import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class ActiveDevicesCard extends StatefulWidget {
  const ActiveDevicesCard({super.key});

  @override
  State<ActiveDevicesCard> createState() => _ActiveDevicesCardState();
}

class _ActiveDevicesCardState extends State<ActiveDevicesCard> {
  final List<_DeviceSession> _devices = [
    _DeviceSession(
      name: 'Studio Pro 16"',
      meta: 'Current Session • Neo-Tokyo',
      icon: Icons.desktop_mac,
      isCurrent: true,
    ),
    _DeviceSession(
      name: 'iPhone 15 Pro',
      meta: 'Active 4h ago • London',
      icon: Icons.smartphone,
      isCurrent: false,
    ),
    _DeviceSession(
      name: 'MacBook Air M3',
      meta: 'Active 2d ago • San Francisco',
      icon: Icons.laptop_mac,
      isCurrent: false,
    ),
  ];

  void _revokeSession(int index) {
    setState(() {
      _devices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACTIVE DEVICE SESSIONS',
            style: TextStyle(
              color: EditProfileColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              if (isWide) {
                return Row(
                  children: _devices.map((device) {
                    final idx = _devices.indexOf(device);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _buildDeviceCard(device, idx),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: _devices.map((device) {
                  final idx = _devices.indexOf(device);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDeviceRow(device, idx),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(_DeviceSession device, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EditProfileColors.borderSides),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(device.icon, color: device.isCurrent ? EditProfileColors.primary : EditProfileColors.textSecondary, size: 24),
              if (device.isCurrent)
                const Icon(Icons.circle, color: EditProfileColors.success, size: 10)
              else
                IconButton(
                  onPressed: () => _revokeSession(index),
                  icon: const Icon(Icons.logout, color: EditProfileColors.error, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EditProfileColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            device.meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EditProfileColors.textOutline,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(_DeviceSession device, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EditProfileColors.borderSides),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(device.icon, color: device.isCurrent ? EditProfileColors.primary : EditProfileColors.textSecondary, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      color: EditProfileColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.meta,
                    style: const TextStyle(
                      color: EditProfileColors.textOutline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (device.isCurrent)
            const Icon(Icons.circle, color: EditProfileColors.success, size: 10)
          else
            IconButton(
              onPressed: () => _revokeSession(index),
              icon: const Icon(Icons.logout, color: EditProfileColors.error, size: 16),
            ),
        ],
      ),
    );
  }
}

class _DeviceSession {
  _DeviceSession({
    required this.name,
    required this.meta,
    required this.icon,
    required this.isCurrent,
  });

  final String name;
  final String meta;
  final IconData icon;
  final bool isCurrent;
}
