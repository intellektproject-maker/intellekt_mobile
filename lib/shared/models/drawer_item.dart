import 'package:flutter/material.dart';

class DrawerItemModel {
  final String title;
  final IconData icon;
  final String route;
  final bool adminOnly;
  final List<DrawerItemModel> children;

  const DrawerItemModel({
    required this.title,
    required this.icon,
    required this.route,
    this.adminOnly = false,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;
}