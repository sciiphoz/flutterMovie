import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:flutter_guitar/database/user_requests.dart';
import 'package:flutter_guitar/pages/drawer.dart';
import 'package:flutter_guitar/pages/movie.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final String currentUser = Supabase.instance.client.auth.currentUser!.id.toString();  
  
  AuthService authService = AuthService();
  UserRequests userRequests = UserRequests();
   
  List<Map<String, dynamic>> movie = []; 
  List<Map<String, dynamic>> likedMovies = [];

  bool isPlaying = true;

  @override
  void initState() {
    super.initState();
    
    getMovie();
  }

  Future<void> getMovie() async {
    try {
      final response = await _supabase.from('films').select('id, name_film, url_img, producer(name), genre(genre_name), place, year, age_rating');

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
          };
        }).toList();
      });
    }
    catch (e) { print(e); }
  } 

  List<Map<String, dynamic>> get filteredMovies => movie
    .where((movie) =>
      movie['name_film']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
      movie['name']!.toLowerCase().contains(_searchController.text.toLowerCase()))
    .toList();

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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
                    labelText: 'Поиск по названию или продюсеру',
                    labelStyle: TextStyle(color: Colors.blueGrey[600]),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white)
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.white)
                    )
                  ),
                  onChanged: (value) {
                    setState(() {
                  });
                },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  "Фильмы",
                  style: TextStyle(fontSize: 42),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            direction: Axis.vertical,
                            children: filteredMovies.map((movie) {
                              return SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(
                                            movie['image']!,
                                            height: MediaQuery.of(context).size.height * 0.3,
                                            width: MediaQuery.of(context).size.width * 0.6,
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                movie['name_film']!,
                                                style: TextStyle(fontSize: 24, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                movie['name']!,
                                                style: TextStyle(fontSize: 16, color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MoviePage(
                                                  id: movie['id']!
                                                )
                                              )
                                            );
                                          }, 
                                          child: Text("Смотреть")
                                        ),
                                        IconButton(
                                          onPressed: () async {
                                            if (await _supabase.from('usertable')
                                                .count()
                                                .eq('id_user', currentUser)
                                                .eq('id_film', movie['id'] as int) == 1) {
                                              print('film est');
                                              return;
                                            } else {
                                              userRequests.addUserMovie(movie['id'], currentUser);
                                            }
                                          }, 
                                          icon: Icon(
                                            movie['isLiked'] ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: Colors.white
                                          )
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),    
            ],
          ),
        ),
        appBar: AppBar(
          title: Text("Главная", style: TextStyle(color: Colors.white),),
        ),
        drawer: DrawerPage(),
      ),
    );
  }
}