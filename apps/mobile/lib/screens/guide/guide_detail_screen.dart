import 'dart:ui' as ui show ImageFilter, TextDirection;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../core/routes/app_routes.dart';
import '../../models/article.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuideDetailScreen extends StatefulWidget {
  final Article article;

  const GuideDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  bool _isBookmarked = false;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
    _incrementViewCount();
    _checkIfBookmarked();
  }

  void _checkIfBookmarked() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(widget.article.id)
            .get();
        if (docSnap.exists && mounted) {
          setState(() {
            _isBookmarked = true;
          });
        }
      }
    } catch (e) {
      // Ignored
    }
  }

  void _incrementViewCount() {
    try {
      FirebaseFirestore.instance
          .collection('articles')
          .doc(widget.article.id)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      // Ignored if update fails or field doesn't exist
    }
  }

  void _initVideoPlayer() {
    if (widget.article.videoUrl != null && widget.article.videoUrl!.isNotEmpty && !widget.article.isPremium) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.article.videoUrl!));
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _stripHtml(String htmlString) {
    String result = htmlString
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'<p>'), '')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<ul>|</ul>|<li>'), '');
    
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    
    result = result
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
        
    return result.trim();
  }

  bool _isImageUrl(String text) {
    final clean = text.trim();
    return (clean.startsWith('http') && (clean.contains('cloudinary.com') || clean.endsWith('.png') || clean.endsWith('.jpg') || clean.endsWith('.jpeg') || clean.endsWith('.webp')));
  }

  String? _extractMarkdownImageUrl(String text) {
    final match = RegExp(r'!\[.*?\]\((https?:\/\/.*?)\)').firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
    if (_isImageUrl(text)) {
      return text.trim();
    }
    return null;
  }

  Map<String, String>? _extractMarkdownPdfLink(String text) {
    final match = RegExp(r'\[(.*?)\]\((https?:\/\/.*?)\)').firstMatch(text);
    if (match != null) {
      final label = match.group(1) ?? 'Tài liệu PDF';
      final url = match.group(2) ?? '';
      if (label.toLowerCase().contains('pdf') || url.toLowerCase().contains('.pdf') || url.toLowerCase().contains('/raw/upload/')) {
        return {'label': label, 'url': url};
      }
    }
    return null;
  }

  Widget _buildInlinePdfCard(BuildContext context, String label, String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withAlpha(51), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TÀI LIỆU HƯỚNG DẪN HÃNG',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (label.toLowerCase() == 'pdf' || label.toLowerCase() == 'tài liệu pdf')
                      ? 'Tài liệu hướng dẫn kỹ thuật'
                      : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () {
              if (widget.article.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tài liệu VIP - Vui lòng nâng cấp tài khoản để xem')),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                AppRoutes.pdfViewer,
                arguments: {
                  'pdfUrl': url,
                  'title': label,
                },
              );
            },
            child: const Text('Đọc ngay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineImage(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 3.0,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF388AF6)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const SizedBox(
              height: 100,
              child: Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(String causes, String steps, String notes, bool hasVideo, bool hasPdf) {
    if (_activeTabIndex == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (causes.isNotEmpty) ...[
            _buildCausesSection(causes),
            const SizedBox(height: 24),
          ],
          if (steps.isNotEmpty) ...[
            _buildStepsSection(steps),
            const SizedBox(height: 24),
          ],
          if (notes.isNotEmpty) ...[
            _buildNotesSection(notes),
            const SizedBox(height: 24),
          ],
        ],
      );
    }

    if (_activeTabIndex == 1) {
      if (hasVideo) {
        return _buildVideoPlayerSection(context);
      } else if (hasPdf) {
        return _buildPdfDocumentCard(context);
      }
    }

    if (_activeTabIndex == 2 && hasPdf) {
      return _buildPdfDocumentCard(context);
    }

    return const SizedBox();
  }

  Widget _buildStructuredContent(String causes, String steps, String notes) {
    final hasVideo = widget.article.videoUrl != null && widget.article.videoUrl!.isNotEmpty;
    final hasPdf = widget.article.pdfUrl != null && widget.article.pdfUrl!.isNotEmpty;
    
    final hasInlinePdf = causes.contains('[') && causes.contains(']') && (causes.contains('.pdf') || causes.contains('/raw/upload/')) ||
                         steps.contains('[') && steps.contains(']') && (steps.contains('.pdf') || steps.contains('/raw/upload/')) ||
                         notes.contains('[') && notes.contains(']') && (notes.contains('.pdf') || notes.contains('/raw/upload/'));

    final tabCount = (hasVideo ? 1 : 0) + (hasPdf ? 1 : 0) + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tabCount > 1) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2A4A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 0 ? const Color(0xFF388AF6) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'QUY TRÌNH',
                          style: TextStyle(
                            color: _activeTabIndex == 0 ? Colors.white : const Color(0xFF5A6B8F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasVideo) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1 ? const Color(0xFF388AF6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'CLIP HƯỚNG DẪN',
                            style: TextStyle(
                              color: _activeTabIndex == 1 ? Colors.white : const Color(0xFF5A6B8F),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasPdf) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTabIndex = hasVideo ? 2 : 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == (hasVideo ? 2 : 1) ? const Color(0xFF388AF6) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'TÀI LIỆU HÃNG',
                            style: TextStyle(
                              color: _activeTabIndex == (hasVideo ? 2 : 1) ? Colors.white : const Color(0xFF5A6B8F),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        // Tab Content
        if (tabCount > 1) 
          _buildActiveTabContent(causes, steps, notes, hasVideo, hasPdf)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (causes.isNotEmpty) ...[
                _buildCausesSection(causes),
                const SizedBox(height: 24),
              ],
              if (steps.isNotEmpty) ...[
                _buildStepsSection(steps),
                const SizedBox(height: 24),
              ],
              if (notes.isNotEmpty) ...[
                _buildNotesSection(notes),
                const SizedBox(height: 24),
              ],
            ],
          ),

        // Bottom PDF fallback check for non-tabbed view
        if (tabCount == 1 && widget.article.pdfUrl != null && widget.article.pdfUrl!.isNotEmpty && !hasInlinePdf) ...[
          _buildPdfDocumentCard(context),
        ],
      ],
    );
  }

  Widget _buildVideoPlayerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.video_library_outlined, color: Color(0xFF388AF6), size: 20),
            SizedBox(width: 8),
            Text(
              'VIDEO HƯỚNG DẪN THỰC TẾ',
              style: TextStyle(
                color: Color(0xFF388AF6),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.article.isPremium
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey[950],
                          child: const Center(
                            child: Icon(Icons.play_circle_outline, color: Colors.white30, size: 64),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(102),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, color: Colors.orange, size: 24),
                                SizedBox(height: 8),
                                Text(
                                  'Video Premium (VIP)',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _isVideoInitialized && _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const Center(
                        child: CircularProgressIndicator(color: Color(0xFF388AF6)),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfDocumentCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withAlpha(51), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TÀI LIỆU PDF ĐÍNH KÈM',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.article.titleVi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              if (widget.article.isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tài liệu VIP - Vui lòng nâng cấp tài khoản để xem')),
                );
                return;
              }
              Navigator.pushNamed(
                context,
                AppRoutes.pdfViewer,
                arguments: {
                  'pdfUrl': widget.article.pdfUrl!,
                  'title': widget.article.titleVi,
                },
              );
            },
            child: const Text('Đọc ngay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCausesSection(String causes) {
    final cleanText = _stripHtml(causes);
    final lines = cleanText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5722).withAlpha(13), // 0.05 alpha approximately 13
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF5722).withAlpha(51), // 0.2 alpha approximately 51
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Color(0xFFFF7043), size: 20),
              SizedBox(width: 8),
              Text(
                'NGUYÊN NHÂN GÂY LỖI',
                style: TextStyle(
                  color: Color(0xFFFF7043),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            var displayText = line.trim();
            final imgUrl = _extractMarkdownImageUrl(displayText);
            if (imgUrl != null) {
              return _buildInlineImage(imgUrl);
            }
            final pdfLink = _extractMarkdownPdfLink(displayText);
            if (pdfLink != null) {
              return _buildInlinePdfCard(context, pdfLink['label']!, pdfLink['url']!);
            }
            if (displayText.startsWith('-') || displayText.startsWith('*')) {
              displayText = displayText.substring(1).trim();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFFFF7043), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepsSection(String steps) {
    final cleanText = _stripHtml(steps);
    final lines = cleanText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: Color(0xFF388AF6), size: 20),
            SizedBox(width: 8),
            Text(
              'QUY TRÌNH HƯỚNG DẪN XỬ LÝ',
              style: TextStyle(
                color: Color(0xFF388AF6),
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(lines.length, (index) {
          final line = lines[index].trim();
          final isLast = index == lines.length - 1;
          final imgUrl = _extractMarkdownImageUrl(line);

          if (imgUrl != null) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 28), // Matches width of step circle
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildInlineImage(imgUrl),
                    ),
                  ),
                ],
              ),
            );
          }

          final pdfLink = _extractMarkdownPdfLink(line);
          if (pdfLink != null) {
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 28), // Matches width of step circle
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildInlinePdfCard(context, pdfLink['label']!, pdfLink['url']!),
                    ),
                  ),
                ],
              ),
            );
          }

          final stepPattern = RegExp(r'^(bước|step|b)\s*\d+[:\s\.]*', caseSensitive: false);
          String stepNumber = '${index + 1}';
          String stepText = line;
          
          if (stepPattern.hasMatch(line)) {
            final match = stepPattern.firstMatch(line);
            if (match != null) {
              final digitPattern = RegExp(r'\d+');
              final digitMatch = digitPattern.firstMatch(match.group(0) ?? '');
              if (digitMatch != null) {
                stepNumber = digitMatch.group(0) ?? stepNumber;
              }
              stepText = line.substring(match.end).trim();
            }
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF388AF6).withAlpha(38), // 0.15 alpha
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF388AF6), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          stepNumber,
                          style: const TextStyle(
                            color: Color(0xFF388AF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          color: const Color(0xFF388AF6).withAlpha(76), // 0.3 alpha
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D2A4A).withAlpha(102), // 0.4 alpha
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(8)), // 0.03 alpha
                    ),
                    child: Text(
                      stepText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNotesSection(String notes) {
    final cleanText = _stripHtml(notes);
    final lines = cleanText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withAlpha(13), // 0.05 alpha
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB300).withAlpha(51), // 0.2 alpha
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFFFB300), size: 20),
              SizedBox(width: 8),
              Text(
                'LƯU Ý AN TOÀN KỸ THUẬT',
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            var displayText = line.trim();
            final imgUrl = _extractMarkdownImageUrl(displayText);
            if (imgUrl != null) {
              return _buildInlineImage(imgUrl);
            }
            final pdfLink = _extractMarkdownPdfLink(displayText);
            if (pdfLink != null) {
              return _buildInlinePdfCard(context, pdfLink['label']!, pdfLink['url']!);
            }
            if (displayText.startsWith('-') || displayText.startsWith('*')) {
              displayText = displayText.substring(1).trim();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFFB300), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: Colors.yellow[100],
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getCategoryDisplayName(String key) {
    switch (key) {
      case 'ac':
        return 'Điều hòa';
      case 'fridge':
        return 'Tủ lạnh';
      case 'washing-machine':
        return 'Máy giặt';
      case 'microwave':
        return 'Lò vi sóng';
      default:
        return key.replaceAll('-', ' ').split(' ').map((str) => str[0].toUpperCase() + str.substring(1)).join(' ');
    }
  }

  void _showFullscreenBlueprint(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF070B14),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A0F1D),
              title: const Text('Sơ đồ mạch điện full-size'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 6.0,
                child: widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty
                    ? Image.network(
                        widget.article.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF388AF6),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'Lỗi tải hình ảnh sơ đồ',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          );
                        },
                      )
                    : CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: const CircuitDiagramPainter(),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langCode = context.locale.languageCode;
    final title = widget.article.getTitle(langCode);
    final causes = widget.article.getCauses(langCode);
    final steps = widget.article.getSteps(langCode);
    final notes = widget.article.getNotes(langCode);
    final previewText = causes.isNotEmpty ? causes : (steps.isNotEmpty ? steps : notes);
    final categoryName = _getCategoryDisplayName(widget.article.category);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0A0F1D),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _isBookmarked ? const Color(0xFF388AF6) : Colors.white,
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng đăng nhập để lưu bài viết.')),
                      );
                      return;
                    }

                    final newBookmarkStatus = !_isBookmarked;
                    setState(() {
                      _isBookmarked = newBookmarkStatus;
                    });

                    try {
                      final docRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('bookmarks')
                          .doc(widget.article.id);

                      if (newBookmarkStatus) {
                        await docRef.set({
                          'title_vi': widget.article.titleVi,
                          'category': widget.article.category,
                          'brand': widget.article.brand,
                          'imageUrl': widget.article.imageUrl,
                          'isPremium': widget.article.isPremium,
                          'savedAt': FieldValue.serverTimestamp(),
                        });
                      } else {
                        await docRef.delete();
                      }
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              newBookmarkStatus 
                                  ? 'Đã lưu hướng dẫn này' 
                                  : 'Đã hủy lưu hướng dẫn',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        _isBookmarked = !newBookmarkStatus;
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi cập nhật yêu thích: $e')),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang chuẩn bị link chia sẻ...')),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 16),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0A162B), Color(0xFF0A0F1D)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Cloudinary Image as cover background with opacity blending
                    if (widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty)
                      Opacity(
                        opacity: 0.25,
                        child: Image.network(
                          widget.article.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(),
                        ),
                      ),
                    // Grid background
                    Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: const BlueprintGridPainter(gridStep: 16.0),
                      ),
                    ),
                    // Content Header Details
                    Positioned(
                      left: 56,
                      bottom: 40,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF388AF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF388AF6).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              categoryName.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF388AF6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Article Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2A4A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.article.isPremium) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[800],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Circuit Schematic Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.article.isPremium 
                        ? 'SƠ ĐỒ MẠCH ĐIỆN (PREMIUM)' 
                        : 'SƠ ĐỒ MẠCH ĐIỆN',
                    style: const TextStyle(
                      color: Color(0xFF5A6B8F),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (!widget.article.isPremium)
                    GestureDetector(
                      onTap: () => _showFullscreenBlueprint(context),
                      child: const Row(
                        children: [
                          Icon(Icons.fullscreen, color: Color(0xFF388AF6), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Phóng to',
                            style: TextStyle(
                              color: Color(0xFF388AF6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Schematic Viewport
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E36),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: widget.article.isPremium
                      ? Stack(
                          children: [
                            ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      widget.article.imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 250,
                                    )
                                  : CustomPaint(
                                      size: const Size(double.infinity, 250),
                                      painter: const CircuitDiagramPainter(),
                                    ),
                            ),
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.4),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _PulsatingLock(),
                                      SizedBox(height: 16),
                                      Text(
                                        'SƠ ĐỒ MẠCH ĐIỆN KHÓA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Nâng cấp VIP để mở khóa',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : InteractiveViewer(
                          panEnabled: true,
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: widget.article.imageUrl != null && widget.article.imageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.article.imageUrl!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 250,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF388AF6),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Text(
                                        'Lỗi tải hình ảnh',
                                        style: TextStyle(color: Colors.redAccent),
                                      ),
                                    );
                                  },
                                )
                              : CustomPaint(
                                  size: const Size(double.infinity, 250),
                                  painter: const CircuitDiagramPainter(),
                                ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Content Area
              widget.article.isPremium
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUY TRÌNH HƯỚNG DẪN XỬ LÝ',
                          style: TextStyle(
                            color: Color(0xFF5A6B8F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Blurred snippet
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  previewText.length > 150 
                                      ? previewText.substring(0, 150) 
                                      : previewText,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(38), // 0.15 alpha
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, const Color(0xFF0A0F1D).withAlpha(230)], // 0.9 alpha
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Paywall CTA Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFF9800).withAlpha(26), // 0.1 alpha
                                const Color(0xFFFF5722).withAlpha(26), // 0.1 alpha
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange[800]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.orange, size: 32),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Yêu cầu nâng cấp VIP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Xem toàn bộ hướng dẫn sửa chữa & sơ đồ điện.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[800],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Tính năng thanh toán Premium đang phát triển...'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Nâng cấp VIP ngay',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildStructuredContent(causes, steps, notes),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw a technical blueprint grid
class BlueprintGridPainter extends CustomPainter {
  final double gridStep;
  const BlueprintGridPainter({this.gridStep = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter to draw a detailed vector circuit schematic
class CircuitDiagramPainter extends CustomPainter {
  const CircuitDiagramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0F1E36);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wirePaint = Paint()
      ..color = const Color(0xFF388AF6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final componentPaint = Paint()
      ..color = const Color(0xFF5BA4F8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Draw schematic wiring lines
    canvas.drawPath(
      Path()
        ..moveTo(20, 80)
        ..lineTo(80, 80)
        ..lineTo(80, 140)
        ..lineTo(160, 140),
      wirePaint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(160, 80)
        ..lineTo(220, 80)
        ..lineTo(220, 160)
        ..lineTo(320, 160),
      wirePaint,
    );

    // Draw resistor R1
    canvas.drawRect(Rect.fromCenter(center: const Offset(120, 80), width: 30, height: 12), componentPaint);
    textPainter.text = const TextSpan(
      text: 'R1 (10 kΩ)',
      style: TextStyle(color: Color(0xFF5BA4F8), fontSize: 9, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(105, 60));

    // Draw capacitor C1
    canvas.drawLine(const Offset(155, 125), const Offset(155, 155), componentPaint);
    canvas.drawLine(const Offset(165, 125), const Offset(165, 155), componentPaint);
    canvas.drawLine(const Offset(140, 140), const Offset(155, 140), wirePaint);
    canvas.drawLine(const Offset(165, 140), const Offset(180, 140), wirePaint);
    textPainter.text = const TextSpan(
      text: 'C1 (100 μF)',
      style: TextStyle(color: Color(0xFF5BA4F8), fontSize: 9, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(132, 105));

    // Draw IC Box
    canvas.drawRect(Rect.fromCenter(center: const Offset(250, 120), width: 70, height: 60), componentPaint);
    textPainter.text = const TextSpan(
      text: 'MCU CHIP',
      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(225, 115));

    // Draw connections/labels inside IC
    textPainter.text = const TextSpan(
      text: 'VCC',
      style: TextStyle(color: Color(0xFF5BA4F8), fontSize: 7, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(220, 95));

    textPainter.text = const TextSpan(
      text: 'GND',
      style: TextStyle(color: Color(0xFF5BA4F8), fontSize: 7, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(220, 135));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Pulsating Radar/Ripple Lock Icon for Premium Paywall
class _PulsatingLock extends StatefulWidget {
  const _PulsatingLock();

  @override
  State<_PulsatingLock> createState() => _PulsatingLockState();
}

class _PulsatingLockState extends State<_PulsatingLock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72 * _controller.value,
              height: 72 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange[800]?.withValues(alpha: 1.0 - _controller.value),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 24),
            ),
          ],
        );
      },
    );
  }
}
