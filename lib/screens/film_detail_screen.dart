import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'video_player_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Map<String, dynamic>? movieDetails;
  List<dynamic> episodes = [];
  bool isLoading = true;
  Set<String> watchedEpisodes = {}; // Store watched episodes
  bool _isContentExpanded = false; // Add state variable for content expansion
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    fetchMovieDetails();
    _checkFavoriteStatus();
  }

  Future<void> fetchMovieDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://phimapi.com/phim/${widget.movieId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true && data['movie'] != null) {
          setState(() {
            movieDetails = data['movie'];
            episodes = data['episodes'] ?? [];
            isLoading = false;
          });
          _loadWatchedEpisodes(); // Load watched episodes
        }
      }
    } catch (e) {
      debugPrint('Error fetching movie details: $e');
    }
  }

  // Load watched episodes from SharedPreferences
  Future<void> _loadWatchedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedEpisodes =
        prefs.getStringList('watchedEpisodes_${widget.movieId}');

    if (savedEpisodes != null) {
      setState(() {
        watchedEpisodes = savedEpisodes.toSet();
      });
    }
  }

  // Save watched episodes to SharedPreferences
  Future<void> _saveWatchedEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'watchedEpisodes_${widget.movieId}', watchedEpisodes.toList());
  }

  // Add this method to _MovieDetailScreenState class
  Future<void> _saveMovieToHistory() async {
    final prefs = await SharedPreferences.getInstance();

    // Save movie details for history
    final movieHistory = {
      'id': widget.movieId,
      'name': movieDetails?['name'] ?? '',
      'poster_url': movieDetails?['poster_url'] ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // Get existing history
    final String? historyJson = prefs.getString('movie_history');
    List<Map<String, dynamic>> history = [];

    if (historyJson != null) {
      history = List<Map<String, dynamic>>.from(
          json.decode(historyJson).map((x) => Map<String, dynamic>.from(x)));
    }

    // Remove duplicate if exists
    history.removeWhere((movie) => movie['id'] == widget.movieId);

    // Add new entry at the beginning
    history.insert(0, movieHistory);

    // Save updated history
    await prefs.setString('movie_history', json.encode(history));
  }

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_movies');
    if (favoritesJson != null) {
      final List<dynamic> favorites = json.decode(favoritesJson);
      setState(() {
        isFavorite = favorites.any((movie) => movie['id'] == widget.movieId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_movies');
    List<Map<String, dynamic>> favorites = [];

    if (favoritesJson != null) {
      favorites = List<Map<String, dynamic>>.from(
        json.decode(favoritesJson).map((x) => Map<String, dynamic>.from(x))
      );
    }

    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        favorites.add({
          'id': widget.movieId,
          'name': movieDetails?['name'] ?? '',
          'poster_url': movieDetails?['poster_url'] ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        favorites.removeWhere((movie) => movie['id'] == widget.movieId);
      }
    });

    await prefs.setString('favorite_movies', json.encode(favorites));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(movieDetails?['name'] ?? "Chi tiết phim"),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    movieDetails?['poster_url'] ?? '',
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Movie title
              Text(
                movieDetails?['name'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

// Movie details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original name
                  if (movieDetails?['origin_name'] != null)
                    Text(
                      'Tên gốc: ${movieDetails?['origin_name']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                  // Director
                  if (movieDetails?['director'] != null &&
                      (movieDetails?['director'] as List).isNotEmpty)
                    Text(
                      'Đạo diễn: ${movieDetails?['director'].join(", ")}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  // Category
                  if (movieDetails?['category'] != null &&
                      (movieDetails?['category'] as List).isNotEmpty)
                    Text(
                      'Thể loại: ${movieDetails?['category'].map((c) => c['name']).join(", ")}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  // Time
                  if (movieDetails?['time'] != null)
                    Text(
                      'Thời lượng: ${movieDetails?['time']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (movieDetails?['quality'] != null)
                    Text(
                      'Chất lượng: ${movieDetails?['quality']}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  // Episode details
                  if (movieDetails?['episode_total'] != null &&
                      movieDetails?['episode_current'] != null)
                    Text(
                      'Tập: ${movieDetails?['episode_current']} / ${movieDetails?['episode_total']}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  // Year
                  if (movieDetails?['year'] != null)
                    Text(
                      'Năm sản xuất: ${movieDetails?['year']}',
                      style: const TextStyle(fontSize: 16),
                    ),

                  // Actors
                  if (movieDetails?['actor'] != null &&
                      (movieDetails?['actor'] as List).isNotEmpty)
                    Text(
                      'Diễn viên: ${movieDetails?['actor'].join(", ")}',
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              // Expandable movie description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isContentExpanded = !_isContentExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Text(
                          'Nội dung phim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isContentExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Text(
                      movieDetails?['content'] ?? 'Không có mô tả.',
                      style: const TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Text(
                      movieDetails?['content'] ?? 'Không có mô tả.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    crossFadeState: _isContentExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Watch button
              if (episodes.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Save to history first
                      await _saveMovieToHistory();

                      final firstEpisode = episodes.first['server_data'].first;
                      final List<String>? updatedEpisodes =
                          await Navigator.push<List<String>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(
                            videoUrl: firstEpisode['link_embed'],
                            movieName: movieDetails?['name'] ?? '',
                            episodeName: firstEpisode['name'],
                            allEpisodes: episodes,
                            watchedEpisodes: watchedEpisodes,
                          ),
                        ),
                      );

                      if (updatedEpisodes != null && mounted) {
                        setState(() {
                          watchedEpisodes = Set<String>.from(updatedEpisodes);
                        });
                        await _saveWatchedEpisodes();
                      }
                    },
                    icon: const Icon(Icons.play_circle_filled),
                    label: const Text(
                      'Xem Phim',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Episode button widget
  Widget buildEpisodeButton(dynamic episode) {
    final String episodeName = episode['name'] ?? "Tập không có tên";
    final bool isWatched = watchedEpisodes.contains(episodeName);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isWatched ? Colors.blue.shade700 : Colors.blue.shade200,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        setState(() {
          watchedEpisodes.add(episodeName);
        });
        await _saveWatchedEpisodes();

        if (!context.mounted) return;

        final List<String>? updatedEpisodes =
            await Navigator.push<List<String>>(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: episode['link_embed'],
              movieName: movieDetails?['name'] ?? '',
              episodeName: episodeName,
              allEpisodes: episodes,
              watchedEpisodes: watchedEpisodes,
            ),
          ),
        );

        // Update state only if we got valid data back
        if (updatedEpisodes != null && context.mounted) {
          setState(() {
            watchedEpisodes = Set<String>.from(updatedEpisodes);
          });
          await _saveWatchedEpisodes();
        }
      },
      child: Text(
        episodeName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isWatched ? Colors.white : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
