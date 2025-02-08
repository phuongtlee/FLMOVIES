import 'package:flutter/material.dart';
import 'package:movie_app/screens/New_film.dart';
import 'package:movie_app/screens/cartoon_anime.dart';
import 'package:movie_app/screens/movie_tabs.dart';
import 'package:movie_app/screens/tv_series.dart';
import 'package:movie_app/screens/tv_show.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Trang Chủ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0, // Removes shadow
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.black,
            indicatorColor: Colors.blue.shade200,
            labelStyle: const TextStyle(fontSize: 16.0),
            indicatorPadding: const EdgeInsets.symmetric(horizontal: 8.0),
            labelPadding: const EdgeInsets.symmetric(horizontal: 15.0),
            tabs: const [
              Tab(text: "Phim Mới"),
              Tab(text: "Hoạt Hình"),
              Tab(text: "Phim Bộ"),
              Tab(text: "Phim Lẻ"),
              Tab(text: "Tv Show"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NewFilm(),
            CartoonAnime(),
            TvSeriesTab(),
            MoviesTab(),
            TvShowsTab(),
          ],
        ),
      ),
    );
  }
}
