import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({
    super.key,
    this.title = 'Scan QR',
    this.instructions = 'Point the camera at a QR code.',
  });

  final String title;
  final String instructions;

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasScanned) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_controller.stop());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      if (_hasScanned || capture.barcodes.isEmpty) {
                        return;
                      }
                      final value = capture.barcodes.first.rawValue;
                      if (value == null || value.isEmpty) {
                        return;
                      }
                      _hasScanned = true;
                      Navigator.of(context).pop(value);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.instructions,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
