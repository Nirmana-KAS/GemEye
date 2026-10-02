import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

/// Home hero card "Grade a Stone". Royal Blue → Primary Light gradient
/// (allowed exception, see CLAUDE.md) with the rotating sapphire animation
/// in a white icon frame. A null [onTap] disables it (e.g. while offline).
class QuickGradeCard extends StatelessWidget {
  final VoidCallback? onTap;

  const QuickGradeCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.xl);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Grade a Stone',
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Material(
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.transparent,
              highlightColor: AppColors.onPrimarySubtle,
              child: Stack(
                children: [
                  Positioned(
                    right: -36,
                    top: -36,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.onPrimarySubtle),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Lottie.asset(
                              'assets/animations/sapphire_rotate.json',
                              repeat: true,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/logo.png'),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grade a Stone',
                                style: AppText.screenTitle.copyWith(
                                  fontSize: 18,
                                  height: 1.2,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Capture or import a macro photo',
                                style: AppText.body14.copyWith(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.onPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
