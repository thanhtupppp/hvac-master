import 'package:flutter/material.dart';

/// Supported unit systems for a tool.
enum ToolUnitSystem { imperial, metric, both }

/// VIP entitlement tiers.
enum VipTier { free, basic, pro }

/// Represents a single calculator/tool within a category.
class ToolItem {
  /// Stable identifier derived from route or title (slug format).
  /// Example: "duct-calculator", "pressure-loss"
  final String id;

  /// Parent category identifier.
  /// Example: "air-distribution", "refrigeration"
  final String? categoryId;

  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  /// Navigation route string (null = not implemented yet).
  final String? route;

  /// Whether this tool requires VIP subscription.
  final bool isVipOnly;

  /// VIP entitlement tier (if isVipOnly).
  final VipTier vipTier;

  /// Unit systems this tool supports.
  final ToolUnitSystem supportedUnits;

  /// Engineering standard this tool follows.
  /// Example: "SMACNA", "ASHRAE", "Darcy-Weisbach"
  final String? standard;

  /// Short capabilities summary for search/metadata.
  final List<String> capabilities;

  /// Whether the tool is fully implemented.
  /// false = "Sắp ra mắt" badge.
  final bool isReady;

  const ToolItem({
    required this.id,
    this.categoryId,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    this.route,
    this.isVipOnly = false,
    this.vipTier = VipTier.free,
    this.supportedUnits = ToolUnitSystem.both,
    this.standard,
    this.capabilities = const [],
    this.isReady = true,
  });

  bool get hasRoute => route != null;
  bool get isComingSoon => !isReady;
  bool get isLocked => isVipOnly || !isReady;
}

/// Represents a category of related tools.
class ToolCategory {
  /// Stable identifier (slug format).
  /// Example: "air-distribution", "refrigeration"
  final String id;

  final String name;
  final String emoji;
  final IconData icon;
  final Color accent;
  final List<ToolItem> tools;
  final String imageAsset;

  /// Display order in the tools grid (lower = first).
  final int sortOrder;

  const ToolCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.accent,
    required this.tools,
    required this.imageAsset,
    this.sortOrder = 99,
  });
}
