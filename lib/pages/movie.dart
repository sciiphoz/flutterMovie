import 'package:flutter/material.dart';
import 'package:flutter_guitar/video/player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoviePage extends StatefulWidget {
  final int? id;
  const MoviePage({super.key, this.id});

  @override
  State<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends State<MoviePage> {
  final _supabase = Supabase.instance.client;

  int? _id;
  List<Map<String, dynamic>> movie = [];

  @override
  void initState() {
    super.initState();
    _id = widget.id;
    getMovie();
  }

  Future<void> getMovie() async {
    try {
      final response = await _supabase
          .from('films')
          .select(
              'id, name_film, url_film, url_img, producer(name), genre(genre_name), place, year, age_rating, desc, rating, rating_num')
          .eq('id', _id as Object);

      setState(() {
        movie = response.map((item) {
          final producer = item['producer'] as Map<String, dynamic>;
          final genre = item['genre'] as Map<String, dynamic>;

          // Рассчитываем рейтинг с проверкой на null и деление на ноль
          double? calculatedRating;
          if (item['rating'] != null && item['rating_num'] != null && item['rating_num'] != 0) {
            calculatedRating = (item['rating'] as num) / (item['rating_num'] as num);
          }

          return {
            'id': item['id'] as int? ?? 0,
            'name_film': item['name_film']?.toString() ?? '',
            'url_img': item['url_img']?.toString() ?? '',
            'name': producer['name']?.toString() ?? '',
            'genre_name': genre['genre_name']?.toString() ?? '',
            'place': item['place']?.toString() ?? '',
            'year': item['year']?.toString() ?? '',
            'age_rating': item['age_rating']?.toString() ?? '',
            'desc': item['desc']?.toString() ?? '',
            'rating': calculatedRating,
            'rating_num': item['rating_num']?.toString() ?? '0',
          };
        }).toList();
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
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
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                movie[0]['name_film'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              movie[0]['url_img'],
                              height: MediaQuery.of(context).size.height * 0.5,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.of(context).size.width * 0.15,
                              0,
                              MediaQuery.of(context).size.width * 0.15,
                              0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              Center(
                                child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  VideoPage(id: movie[0]['id'])));
                                    },
                                    child: Text("Смотреть")),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      movie[0]['rating'] != null
                                          ? '${movie[0]['rating']!.toStringAsFixed(1)}/5 (${movie[0]['rating_num']} оценок)'
                                          : 'Рейтинг отсутствует',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              Text("Детали",
                                  style: TextStyle(
                                      fontSize: 38, fontWeight: FontWeight.w500)),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              _buildInfoRow(
                                  Icons.movie, 'Год выпуска: ${movie[0]['year']}'),
                              _buildInfoRow(
                                  Icons.person, 'Продюсер: ${movie[0]['name']}'),
                              _buildInfoRow(Icons.location_on,
                                  'Место съемок: ${movie[0]['place']}'),
                              _buildInfoRow(
                                  Icons.category, 'Жанр: ${movie[0]['genre_name']}'),
                              _buildInfoRow(Icons.warning_amber_rounded,
                                  'Возрастной рейтинг: ${movie[0]['age_rating']}'),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              Text(
                                'Описание',
                                style: TextStyle(
                                    fontSize: 38, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                              Text(
                                movie[0]['desc'],
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
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
    return SizedBox(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}