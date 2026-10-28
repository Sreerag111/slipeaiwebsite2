import 'package:flutter/material.dart';

class EnhancerErrorNotice {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    ));
  }
}
