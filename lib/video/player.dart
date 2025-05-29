import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

class VideoPage extends StatefulWidget {
  final int? id;
  const VideoPage({super.key, required this.id});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late VideoPlayerController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic> _movie = {};
  bool _isControlsVisible = true;
  List<Map<String, dynamic>> _reviews = [];
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isCommentLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadReviews();
  }

  Future<void> _initializeVideo() async {
    try {
      final response = await _supabase
          .from('films')
          .select('url_film, name_film, year, age_rating, desc, rating, rating_num')
          .eq('id', widget.id as Object)
          .single();

      setState(() {
        _movie = response;
        _isLoading = false;
      });

      _controller = VideoPlayerController.networkUrl(Uri.parse(_movie['url_film']));
      _controller.addListener(() {
        if (mounted) setState(() {});
      });
      _controller.setLooping(true);
      await _controller.initialize();
      if (mounted) setState(() {});
      _controller.play();

    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
      print('Error loading video: $e');
    }
  }

  Future<void> _loadReviews() async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('id, review_text, rating, created_at, users(username)')
          .eq('id_film', widget.id as Object)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _reviews = response;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty || _selectedRating == 0) return;

    setState(() => _isCommentLoading = true);

    try {
      // Добавляем комментарий
      await _supabase.from('reviews').insert({
        'id_film': widget.id,
        'review_text': _commentController.text,
        'rating': _selectedRating,
        'id_user': _supabase.auth.currentUser?.id,
      });

      // Обновляем рейтинг фильма
      await _supabase.rpc('update_film_rating', params: {
        'film_id': widget.id,
        'new_rating': _selectedRating,
      });

      // Обновляем данные
      await _initializeVideo();
      await _loadReviews();

      // Очищаем форму
      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _isCommentLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Комментарий добавлен')),
      );
    } catch (e) {
      setState(() => _isCommentLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
      print('Error submitting comment: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _isControlsVisible = !_isControlsVisible);
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            if (_isControlsVisible) _VideoControlsOverlay(controller: _controller),
            if (_isControlsVisible) _TopAppBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _movie['name_film'] ?? 'Название не указано',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            children: [
              Text(
                '${_movie['year'] ?? ''}',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(width: 16.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '${_movie['age_rating'] ?? '0+'}',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Text(
            _movie['desc'] ?? 'Описание отсутствует',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.0,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentForm() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Оставить отзыв',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ваш отзыв...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 12.0),
          Text(
            'Оценка:',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  Icons.star,
                  color: _selectedRating > index ? Colors.amber : Colors.grey,
                  size: 30.0,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
              );
            }),
          ),
          SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCommentLoading ? null : _submitComment,
              child: _isCommentLoading
                  ? CircularProgressIndicator()
                  : Text('Отправить отзыв'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Пока нет отзывов. Будьте первым!',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final user = review['users'] as Map<String, dynamic>? ?? {};
        
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user['username'] ?? 'Аноним',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star,
                          color: i < (review['rating'] as int? ?? 0)
                              ? Colors.amber
                              : Colors.grey,
                          size: 16.0,
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 8.0),
                Text(
                  review['review_text'] ?? '',
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 8.0),
                Text(
                  '${review['created_at']?.toString().substring(0, 10) ?? ''}',
                  style: TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ошибка загрузки видео', style: TextStyle(color: Colors.white)),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _initializeVideo,
              child: Text('Повторить попытку'),
            ),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: MediaQuery.of(context).size.height * 0.4,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildVideoPlayer(),
          ),
          pinned: true,
        ),
        SliverToBoxAdapter(child: _buildMovieInfo()),
        SliverToBoxAdapter(child: _buildCommentForm()),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(left: 16.0, top: 24.0),
            child: Text(
              'Отзывы',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(delegate: SliverChildListDelegate([_buildReviewsList()])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }
}

class _VideoControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoControlsOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 50.0,
            ),
            onPressed: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: Colors.red,
              bufferedColor: Colors.grey,
              backgroundColor: Colors.grey,
            ),
            padding: EdgeInsets.all(8.0),
          ),
        ),
        Positioned(
          bottom: 40.0,
          right: 16.0,
          child: Text(
            '${controller.value.position.toString().split('.').first} / '
            '${controller.value.duration.toString().split('.').first}',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Positioned(
          top: 16.0,
          right: 16.0,
          child: PopupMenuButton<double>(
            icon: Icon(Icons.speed, color: Colors.white),
            itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0]
                .map((speed) => PopupMenuItem(
                      value: speed,
                      child: Text('${speed}x'),
                    ))
                .toList(),
            onSelected: (speed) => controller.setPlaybackSpeed(speed),
          ),
        ),
      ],
    );
  }
}

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () {
                  if (MediaQuery.of(context).orientation == Orientation.portrait) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          body: Center(
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: VideoPlayer(Provider.of<VideoPlayerController>(context)),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}