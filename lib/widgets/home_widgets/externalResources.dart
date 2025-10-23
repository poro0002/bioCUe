import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalResources extends StatefulWidget {
  const ExternalResources({super.key});

  @override
  State<ExternalResources> createState() => _ExternalResourcesState();
}

class _ExternalResourcesState extends State<ExternalResources> {
  final Uri _resourceUrl = Uri.parse(
    'https://www.sciencedaily.com/news/health_medicine/',
  );

  Future<void> _launchResource() async {
    if (!await launchUrl(_resourceUrl, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open resource')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchResource,
      child: SizedBox(
        height: 132,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                child: Icon(
                  Icons.newspaper,
                  size: 28,
                  color: Color(0xFFFF6F61),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Chronic Illness News',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to explore the latest research and updates from ScienceDaily.',
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
