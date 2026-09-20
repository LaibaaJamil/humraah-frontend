import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/resource.dart';

class ResourceCard extends StatelessWidget {
  final ResourceItem resource;
  final VoidCallback? onDownload;
  final VoidCallback? onTap;

  const ResourceCard({
    super.key,
    required this.resource,
    this.onDownload,
    this.onTap,
  });

  IconData _categoryIcon() {
    switch (resource.category) {
      case 'poster':
        return Icons.image_outlined;
      case 'video':
        return Icons.play_circle_outline;
      case 'research':
        return Icons.menu_book_outlined;
      case 'manual':
        return Icons.description_outlined;
      case 'infographic':
        return Icons.bar_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _categoryColor() {
    switch (resource.category) {
      case 'poster':
        return AppColors.accent;
      case 'video':
        return AppColors.danger;
      case 'research':
        return AppColors.primary;
      case 'manual':
        return AppColors.secondary;
      case 'infographic':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_categoryIcon(), color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            resource.category.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${resource.language}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (resource.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.download_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${resource.downloadCount}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                if (resource.fileSize > 0) ...[
                  const Icon(
                    Icons.data_usage_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatSize(resource.fileSize),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: onDownload,
                  icon: const Icon(Icons.cloud_download_outlined),
                  tooltip: 'Download',
                  iconSize: 18,
                  color: AppColors.primary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
