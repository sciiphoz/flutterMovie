import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoviePage extends StatefulWidget {
  final String? id;
  const MoviePage(
    {
      super.key,
      this.id
    });

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final _supabase = Supabase.instance.client;

  String? _id;
  List<Map<String, dynamic>> movie = [];

  @override
  void initState() {
    super.initState();
    _id = widget.id;
    getMovie();
  }

  Future<void> getMovie() async {
    try {
      final response = await _supabase.from('films').select('id, name_film, url_film, url_img, producer(name), genre(genre_name), place, year, age_rating, desc').eq('id', _id as Object);

      setState(() {
        movie = response.map((item) {
          final producer = item['producer'] as Map<String, dynamic>;
          final genre = item['genre'] as Map<String, dynamic>;

          return {
            'id': item['id']?.toString() ?? '',
            'name_film': item['name_film']?.toString() ?? '',
            'url_img': item['url_img']?.toString() ?? '',
            'name': producer['name']?.toString() ?? '',
            'genre_name': genre['genre_name']?.toString() ?? '',
            'place': item['place']?.toString() ?? '',
            'year': item['year']?.toString() ?? '',
            'age_rating': item['age_rating']?.toString() ?? '',
            'desc': item['desc']?.toString() ?? '',
          };
        }).toList();
      });
    }
    catch (e) { print(e); }
  } 
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 45, 20, 20),
            Color.fromARGB(255, 35, 35, 60),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: movie.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                movie[0]['name_film'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              movie[0]['url_img'],
                              height: 400,
                              width: 280,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.movie, 'Год выпуска: ${movie[0]['year']}'),
                        _buildInfoRow(Icons.person, 'Продюсер: ${movie[0]['name']}'),
                        _buildInfoRow(Icons.location_on, 'Место съемок: ${movie[0]['place']}'),
                        _buildInfoRow(Icons.category, 'Жанр: ${movie[0]['genre_name']}'),
                        _buildInfoRow(Icons.warning_amber_rounded, 'Возрастной рейтинг: ${movie[0]['age_rating']}+'),
                        const SizedBox(height: 25),
                        const Text(
                          'Описание',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          movie[0]['desc'],
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}