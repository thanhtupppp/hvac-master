import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'ac':
      return Icons.ac_unit;
    case 'fridge':
      return Icons.kitchen;
    case 'washing-machine':
      return Icons.local_laundry_service;
    case 'microwave':
      return Icons.microwave;
    default:
      return Icons.construction;
  }
}

String getCategoryDisplayName(String key) {
  switch (key) {
    case 'all':
      return 'Tất cả';
    case 'ac':
      return 'Điều hòa';
    case 'fridge':
      return 'Tủ lạnh';
    case 'washing-machine':
      return 'Máy giặt';
    case 'microwave':
      return 'Lò vi sóng';
    default:
      return key.toUpperCase();
  }
}
