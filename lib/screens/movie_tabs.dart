import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_app/screens/film_detail_screen.dart';

class MoviesTab extends StatefulWidget {
  const MoviesTab({super.key});

  @override
  _MoviesTabState createState() => _MoviesTabState();
}

class _MoviesTabState extends State<MoviesTab> {
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
        Uri.parse('https://phimapi.com/v1/api/danh-sach/phim-le?page=$page'),
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
      appBar: AppBar(title: const Text('Phim Lẻ')),
      body: RefreshIndicator(
        onRefresh: refreshList,
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // Số cột
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.58, // Tỷ lệ kích thước của mỗi ô
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
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                child: Image.network(
                  "https://img.phimapi.com/${movie['poster_url']}",
                  width: 110, // Đặt ảnh có chiều rộng cố định là 100
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            Container(
              width: 110, // Đảm bảo chiều rộng cố định cho phần này
              padding:
                  const EdgeInsets.all(4), // Thêm padding để tạo khoảng cách
              decoration: BoxDecoration(
                color: Colors.blue.shade200, // Màu nền mờ
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8)),
              ),
              child: Column(
                children: [
                  // Tên phim
                  Text(
                    truncatedName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Màu chữ
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis, // Cắt bớt nếu tên quá dài
                  ),
                  const SizedBox(height: 4), // Giảm khoảng cách giữa tên và tập
                  // Tập phim
                  Text(
                    "${movie['episode_current']}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black, // Màu chữ nhạt hơn cho tập
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
