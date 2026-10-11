import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: EbbApp()));

/// Placeholder shell until the M2 UI lands.
class EbbApp extends StatelessWidget {
  const EbbApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(title: 'Ebb', home: Scaffold());
}
