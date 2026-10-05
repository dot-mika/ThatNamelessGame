import 'package:flutter/material.dart';

import 'legal_document_screen.dart';

class LicenseScreen extends StatelessWidget {
  const LicenseScreen({super.key});

  @override
  Widget build(BuildContext context) => const LegalDocumentScreen(
    documentBaseName: 'license',
  );
}
