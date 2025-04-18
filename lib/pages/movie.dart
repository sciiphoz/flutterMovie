import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blueGrey]
        )
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            children: [
              Row(
                
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Row(

              )
            ],
          ),
        ),
      ),
    );
  }
}