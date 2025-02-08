import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_app/screens/film_detail_screen.dart';

class TvShowsTab extends StatefulWidget {
  const TvShowsTab({super.key});

  @override
  _TvShowsTabState createState() => _TvShowsTabState();
}

class _TvShowsTabState extends State<TvShowsTab> {
  int page = 1;
  List movies = [];
  bool isLoading = false;
  bool hasMore = true;
  bool isRefreshing = false;
  final ScrollController _scrollController = ScrollController();
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    fetchMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMovies() async {
    if (isLoading || !hasMore || !_mounted) return;

    if (_mounted) setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://phimapi.com/v1/api/danh-sach/tv-shows?page=$page'),
      );

      if (response.statusCode == 200 && _mounted) {
        final data = json.decode(response.body);
        List newMovies = data['data']['items'];

        if (newMovies.isEmpty) {
          if (_mounted) setState(() => hasMore = false);
        } else {
          if (_mounted) {
            setState(() {
              movies = page == 1 ? newMovies : [...movies, ...newMovies];
              page++;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
    } finally {
      if (_mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !isLoading &&
        hasMore) {
      fetchMovies();
    }
  }

  Future<void> refreshList() async {
    setState(() {
      isRefreshing = true;
      page = 1;
      hasMore = true;
      movies = [];
    });
    await fetchMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chương Trình Truyền Hình')),
      body: RefreshIndicator(
        onRefresh: refreshList,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.58,
          ),
          itemCount: movies.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == movies.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final movie = movies[index];
            return _buildMovieItem(movie);
          },
        ),
      ),
    );
  }

  Widget _buildMovieItem(dynamic movie) {
    String movieName = movie['name'];
    List<String> words = movieName.split(' ');
    String truncatedName =
        words.length > 4 ? '${words.sublist(0, 4).join(' ')}...' : movieName;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(
              movieId: movie['slug'],
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8), topRight: Radius.circular(8)),
              child: Image.network(
                "https://img.phimapi.com/${movie['poster_url']}",
                width: 110,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 50),
              ),
            ),
          ),
          Container(
            width: 110,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8)),
            ),
            child: Column(
              children: [
                Text(
                  truncatedName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${movie['episode_current']}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
