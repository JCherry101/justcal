import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String viewId;

  const SidebarItem(this.icon, this.label, this.viewId);
}

const _items = [
  SidebarItem(Icons.dashboard_rounded, 'Dashboard', 'dashboard'),
  SidebarItem(Icons.checklist_rounded, 'My Tasks', 'tasks'),
  SidebarItem(Icons.calendar_month_rounded, 'Calendar', 'calendar'),
  SidebarItem(Icons.chat_bubble_outline_rounded, 'Assistant', 'chat'),
  SidebarItem(Icons.description_outlined, 'Documents', 'documents'),
  SidebarItem(Icons.settings_outlined, 'Settings', 'settings'),
];

class Sidebar extends StatelessWidget {
  final String activeView;
  final ValueChanged<String> onNavigate;

  const Sidebar({
    super.key,
    required this.activeView,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.bgSurface,
      child: Column(
        children: [
          const SizedBox(height: 28),
          // Logo / title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'J',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'JustCal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Nav items
          for (final item in _items)
            _NavTile(
              icon: item.icon,
              label: item.label,
              active: activeView == item.viewId,
              onTap: () => onNavigate(item.viewId),
            ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'v0.1.0',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accentMuted : Colors.transparent,
            border: Border(
              left: BorderSide(
                width: 3,
                color: active ? AppColors.accent : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
