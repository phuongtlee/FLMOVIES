import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String movieName;
  final String episodeName;
  final List<dynamic> allEpisodes;
  final Set<String> watchedEpisodes;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.movieName,
    required this.episodeName,
    required this.allEpisodes,
    required this.watchedEpisodes,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  late String currentEpisodeName;
  late Set<String> watchedEpisodes;
  late int currentIndex;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.videoUrl));

    currentEpisodeName = widget.episodeName;
    // Create a new Set to avoid reference issues
    watchedEpisodes = Set<String>.from(widget.watchedEpisodes);
    currentIndex = widget.allEpisodes
        .expand((server) => server['server_data'])
        .toList()
        .indexWhere((episode) => episode['name'] == widget.episodeName);

    // Add current episode to watched list
    watchedEpisodes.add(widget.episodeName);
    _saveWatchedEpisodes(); // Save initial state
  }

  // Lưu danh sách tập đã xem vào SharedPreferences
  Future<void> _saveWatchedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    // Save watched episodes list
    await prefs.setStringList(
        'watchedEpisodes_${widget.movieName}', watchedEpisodes.toList());

    // Save last watched episode info
    final lastWatchedInfo = {
      'episodeName': currentEpisodeName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(
        'lastWatched_${widget.movieName}', json.encode(lastWatchedInfo));
  }

  // Đọc danh sách tập đã xem từ SharedPreferences
  Future<void> _loadWatchedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedEpisodes =
        prefs.getStringList('watchedEpisodes_${widget.movieName}');

    if (savedEpisodes != null) {
      setState(() {
        watchedEpisodes = savedEpisodes.toSet();
      });
    }
  }

  // Chuyển sang tập tiếp theo
  void _nextEpisode() {
    setState(() {
      currentIndex = (currentIndex + 1) %
          widget.allEpisodes.expand((server) => server['server_data']).length;
      final nextEpisode = widget.allEpisodes
          .expand((server) => server['server_data'])
          .toList()[currentIndex];

      currentEpisodeName = nextEpisode['name'] ?? "Tập ?";
      _controller.loadRequest(Uri.parse(nextEpisode['link_embed']));
      watchedEpisodes.add(currentEpisodeName); // Mark as watched
      _saveWatchedEpisodes(); // Save to SharedPreferences
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movieName),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Player
          Container(
            height: MediaQuery.of(context).size.height * 0.26,
            decoration: BoxDecoration(color: Colors.black),
            child: WebViewWidget(controller: _controller),
          ),

          // Tên tập phim đang xem
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Text(
              "Đang xem: $currentEpisodeName",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Danh sách tập phim
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 5 nút mỗi hàng
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1.5,
                ),
                itemCount: widget.allEpisodes
                    .expand((server) => server['server_data'])
                    .length,
                itemBuilder: (context, index) {
                  final episode = widget.allEpisodes
                      .expand((server) => server['server_data'])
                      .toList()[index];

                  final String episodeName = episode['name'] ?? "Tập ?";
                  final bool isWatched =
                      watchedEpisodes.contains(episodeName) ||
                          episodeName ==
                              currentEpisodeName; // Check both conditions
                  final bool isCurrentEpisode =
                      episodeName == currentEpisodeName;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentEpisode
                          ? Colors.grey
                          : isWatched
                              ? Colors.blue.shade700
                              : Colors.blue.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    // Disable button if it's the current episode
                    onPressed: isCurrentEpisode
                        ? null
                        : () async {
                            setState(() {
                              currentEpisodeName = episodeName;
                              watchedEpisodes.add(episodeName);
                            });

                            // Save to SharedPreferences
                            await _saveWatchedEpisodes();

                            // Load the new episode without navigation
                            _controller
                                .loadRequest(Uri.parse(episode['link_embed']));

                            // Send back updated watched episodes to parent screen
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context, watchedEpisodes.toList());
                              // Push new screen with updated state
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    videoUrl: episode['link_embed'],
                                    movieName: widget.movieName,
                                    episodeName: episodeName,
                                    allEpisodes: widget.allEpisodes,
                                    watchedEpisodes: watchedEpisodes,
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(
                      episodeName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        // Update text color for disabled state
                        color: isCurrentEpisode
                            ? Colors.grey.shade600
                            : (isWatched ? Colors.white : Colors.black),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),

          // Button to go to the next episode
        ],
      ),
    );
  }
}
