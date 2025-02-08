import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:movie_app/index/auth_service.dart';
import 'package:movie_app/screens/film_detail_screen.dart';
import 'package:movie_app/screens/login.dart';
import 'package:movie_app/screens/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userId;
  List<Map<String, dynamic>> watchHistory = [];
  Map<String, Map<String, dynamic>> lastWatchedEpisodes = {};
  List<Map<String, dynamic>> favoriteMovies = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadWatchHistory();
    _loadFavorites();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId =
          prefs.getString('user'); // Kiểm tra xem có user đã đăng nhập không
    });
  }

  Future<void> _loadWatchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('movie_history');

    if (historyJson != null) {
      final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
        json.decode(historyJson).map((x) => Map<String, dynamic>.from(x))
      );

      // Load last watched episode for each movie
      for (var movie in history) {
        final String? lastWatchedJson = prefs.getString('lastWatched_${movie['name']}');
        if (lastWatchedJson != null) {
          movie['lastWatched'] = json.decode(lastWatchedJson);
        }
      }

      // Sort history by last watched timestamp in descending order (newest first)
      history.sort((a, b) {
        final aTime = a['lastWatched']?['timestamp'] ?? a['timestamp'];
        final bTime = b['lastWatched']?['timestamp'] ?? b['timestamp'];
        return bTime.compareTo(aTime); // Reverse order (newest first)
      });

      setState(() {
        watchHistory = history;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = prefs.getString('favorite_movies');
    
    if (favoritesJson != null) {
      setState(() {
        favoriteMovies = List<Map<String, dynamic>>.from(
          json.decode(favoritesJson).map((x) => Map<String, dynamic>.from(x))
        );
      });
    }
  }

  void _logout() async {
    await AuthService().signOut();
    setState(() => userId = null); // Cập nhật UI sau khi đăng xuất
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then(
        (_) => _checkLoginStatus()); // Kiểm tra lại trạng thái sau khi quay lại
  }

  Widget _buildHistoryList() {
    return watchHistory.isEmpty
        ? const Center(
            child: Text(
              'Chưa có phim nào trong lịch sử',
              style: TextStyle(fontSize: 16),
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await _loadWatchHistory();
            },
            child: ListView.builder(
              itemCount: watchHistory.length,
              itemBuilder: (context, index) {
                final movie = watchHistory[index];
                final lastWatched = movie['lastWatched'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        movie['poster_url'],
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      movie['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: lastWatched != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tập xem cuối: ${lastWatched['episodeName']}'),
                              Text(
                                  'Thời gian: ${DateTime.fromMillisecondsSinceEpoch(lastWatched['timestamp']).toString().split('.')[0]}'),
                            ],
                          )
                        : const Text('Chưa xem tập nào'),
                    onTap: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final response = await http.get(
                          Uri.parse('https://phimapi.com/phim/${movie['id']}'),
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          if (data['status'] == true && data['movie'] != null) {
                            final episodes = data['episodes'] ?? [];

                            if (lastWatched != null && episodes.isNotEmpty) {
                              final lastWatchedEpisodeName =
                                  lastWatched['episodeName'];
                              String? episodeUrl;

                              // Load all watched episodes for this movie
                              final List<String>? savedWatchedEpisodes = 
                                  prefs.getStringList('watchedEpisodes_${movie['name']}');
                              final Set<String> watchedEpisodes = savedWatchedEpisodes != null 
                                  ? Set<String>.from(savedWatchedEpisodes)
                                  : <String>{};

                              // Search for the last watched episode URL
                              for (var server in episodes) {
                                final serverData = server['server_data'] as List;
                                final episode = serverData.firstWhere(
                                  (ep) => ep['name'] == lastWatchedEpisodeName,
                                  orElse: () => null,
                                );

                                if (episode != null) {
                                  episodeUrl = episode['link_embed'];
                                  break;
                                }
                              }

                              if (episodeUrl != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerScreen(
                                      videoUrl: episodeUrl!,
                                      movieName: movie['name'],
                                      episodeName: lastWatchedEpisodeName,
                                      allEpisodes: episodes,
                                      watchedEpisodes: watchedEpisodes, // Pass all watched episodes
                                    ),
                                  ),
                                );
                                return;
                              }
                            }
                          }
                        }
                      } catch (e) {
                        debugPrint('Error fetching movie details: $e');
                      }

                      // Fallback to movie detail screen
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MovieDetailScreen(movieId: movie['id']),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
  }

  Widget _buildFavoritesList() {
    return favoriteMovies.isEmpty
        ? const Center(
            child: Text(
              'Chưa có phim yêu thích nào',
              style: TextStyle(fontSize: 16),
            ),
          )
        : RefreshIndicator(
            onRefresh: () async {
              await _loadFavorites();
            },
            child: ListView.builder(
              itemCount: favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = favoriteMovies[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        movie['poster_url'],
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      movie['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // subtitle: Text(
                    //   'Thời gian: ${DateTime.fromMillisecondsSinceEpoch(movie['timestamp']).toString().split('.')[0]}',
                    // ),
                    trailing: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 28,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieDetailScreen(
                            movieId: movie['id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tài khoản"),
          bottom: userId != null 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(72), // Height for both username and tabs
                  child: Column(
                    children: [
                      // Username text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "Xin chào!!",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Tabs
                      const TabBar(
                        tabs: [
                          Tab(text: 'Lịch sử'),
                          Tab(text: 'Yêu thích'),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
          actions: [
            if (userId != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    watchHistory.clear();
                    favoriteMovies.clear();
                  });
                  _loadWatchHistory();
                  _loadFavorites();
                },
              ),
          ],
        ),
        body: userId == null
            ? Center(
                child: ElevatedButton(
                  onPressed: _navigateToLogin,
                  child: const Text("Đăng nhập"),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildHistoryList(),
                        _buildFavoritesList(),
                      ],
                    ),
                  ),
                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Đăng xuất",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
