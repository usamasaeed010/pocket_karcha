import 'package:flutter/material.dart';
import 'package:pocket_karcha/core/constants/app_colors.dart';
import 'package:pocket_karcha/features/people/widgets/person_contact_tiles.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.initial,
    this.imageUrl,
    this.radius = 18,
    this.showBorder = false,
  });

  final String initial;
  final String? imageUrl;
  final double radius;
  final bool showBorder;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _imageFailed = false;
    }
  }

  bool get _showNetworkImage {
    final url = widget.imageUrl?.trim();
    return !_imageFailed && url != null && url.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showBorder) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.successLight, width: 2),
        ),
        child: PersonAvatar(name: widget.initial, radius: widget.radius),
      );
    }

    if (_showNetworkImage) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.dashboardGreenLight,
        backgroundImage: NetworkImage(widget.imageUrl!.trim()),
        onBackgroundImageError: (_, __) {
          if (mounted) setState(() => _imageFailed = true);
        },
      );
    }

    return PersonAvatar(name: widget.initial, radius: widget.radius);
  }
}
