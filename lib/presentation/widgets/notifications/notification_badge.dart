import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/presentation/blocs/in_app_notification/in_app_notification_bloc.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const NotificationBadge({
    super.key,
    required this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InAppNotificationBloc, InAppNotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is InAppNotificationLoaded) {
          unreadCount = state.unreadCount;
        }

        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: size,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onTap,
        );
      },
    );
  }
}
