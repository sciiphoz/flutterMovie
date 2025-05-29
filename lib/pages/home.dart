import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_guitar/database/auth.dart';
import 'package:flutter_guitar/database/user_requests.dart';
import 'package:flutter_guitar/pages/drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_guitar/pages/movie.dart';
import 'package:flutter_guitar/video/player.dart';
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
  bool _sortAscending = true;
  String? _selectedGenre;
  
  AuthService authService = AuthService();
  UserRequests userRequests = UserRequests();
   
  List<Map<String, dynamic>> movie = []; 
  List<Map<String, dynamic>> likedMovies = [];

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
            'id': item['id'] as int? ?? 0,
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

  List<Map<String, dynamic>> get filteredMovies {
    List<Map<String, dynamic>> result = movie
      .where((movie) =>
        movie['name_film']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        movie['name']!.toLowerCase().contains(_searchController.text.toLowerCase()))
      .toList();

    // Сортировка по году
    result.sort((a, b) {
      final yearA = int.tryParse(a['year'] ?? '0') ?? 0;
      final yearB = int.tryParse(b['year'] ?? '0') ?? 0;
      return _sortAscending ? yearA.compareTo(yearB) : yearB.compareTo(yearA);
    });

    // Фильтрация по жанру
    if (_selectedGenre != null && _selectedGenre!.isNotEmpty) {
      result = result.where((m) => m['genre_name'] == _selectedGenre).toList();
    }

    return result;
  }

  Set<String> get allGenres {
    return movie
      .map((m) => m['genre_name'] as String? ?? '')
      .where((genre) => genre.isNotEmpty)
      .toSet();
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: MouseRegion(
        onEnter: (_) => setState(() => movie['hovered'] = true),
        onExit: (_) => setState(() => movie['hovered'] = false),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MoviePage(id: movie['id']!)
              )
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: movie['hovered'] == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 1.75,
                            sigmaY: 1.75,
                          ),
                          child: Image.network(
                            movie['url_img']!,
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie['url_img']!,
                          height: MediaQuery.of(context).size.height * 0.3,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              if (movie['hovered'] == true)
                AnimatedOpacity(
                  opacity: movie['hovered'] == true ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          movie['name_film']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${movie['year']!} • ${movie['name']!}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            minimumSize: Size(120, 40),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MoviePage(id: movie['id']!)
                              ),
                            );
                          },
                          child: Text('Смотреть'),
                        ),
                        SizedBox(height: 8),
                        IconButton(
                          onPressed: () async {
                            final movieId = movie['id'] as int;
                            
                            final response = await _supabase
                                .from('usertable')
                                .select()
                                .eq('id_user', currentUser)
                                .eq('id_film', movieId);
                            
                            if (response.isEmpty) {
                              await _supabase
                                  .from('usertable')
                                  .insert({
                                    'id_user': currentUser,
                                    'id_film': movieId,
                                  });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Фильм добавлен в фильмотеку.', style: TextStyle(color: Colors.white)),
                                backgroundColor: Color.fromARGB(255, 25, 25, 40),
                              )); 
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Фильм уже в Вашей фильмотеке.', style: TextStyle(color: Colors.white)),
                                backgroundColor: Color.fromARGB(255, 25, 25, 40),
                              )); 
                            }
                          },
                          icon: Icon(
                            CupertinoIcons.heart_fill,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
          colors: [Color.fromARGB(255, 45, 20, 20), 
          Color.fromARGB(255, 35, 35, 60), ]
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
                child: Row(
                  children: [
                    // Поисковая строка
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Colors.blueGrey[600]),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          labelText: 'Поиск по названию или продюсеру',
                          labelStyle: TextStyle(color: Colors.white),
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    // Фильтр по жанру
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedGenre,
                        hint: Text('Жанр', style: TextStyle(color: Colors.white70)),
                        dropdownColor: Color.fromARGB(255, 45, 20, 20),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        underline: SizedBox(),
                        isExpanded: false,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Все жанры', style: TextStyle(color: Colors.white)),
                          ),
                          ...allGenres.map((genre) {
                            return DropdownMenuItem(
                              value: genre,
                              child: Text(genre, style: TextStyle(color: Colors.white)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGenre = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    // Кнопка сортировки по году
                    Tooltip(
                      message: 'Сортировать по году',
                      child: IconButton(
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Фильмы",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedGenre != null)
                      Text(
                        "Жанр: $_selectedGenre",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: filteredMovies.map((movie) => _buildMovieCard(movie)).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          title: Text("Главная", style: TextStyle(color: Colors.white)),
        ),
        drawer: DrawerPage(),
      ),
    );
  }
}