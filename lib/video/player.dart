import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final response = await _supabase
          .from('films')
          .select('url_film, name_film, year, age_rating, desc')
          .eq('id', widget.id as Object)
          .single();

      setState(() {
        _movie = response;
        _isLoading = false;
      });

    _controller = VideoPlayerController.networkUrl(Uri.parse(_movie['url_film']));
    _controller.addListener(() {
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();

    } catch (e) {
      setState(() { 
        _hasError = true;
        _isLoading = false;
      });
      print('Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
          SizedBox(height: 24.0),
          _ActionButtonsRow(),
        ],
      ),
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
                  Colors.black.withValues(alpha: 0.5),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? SizedBox.shrink()
              : Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 60.0,
                  ),
                ),
        ),
        VideoProgressIndicator(
          controller,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.red,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.grey,
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
    return SafeArea(
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
              onPressed: () => _toggleFullscreen(context),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFullscreen(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      MediaQuery.of(context).orientation == Orientation.landscape;
    } else {
      MediaQuery.of(context).orientation == Orientation.portrait;
    }
  }
}

class _ActionButtonsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(Icons.thumb_up, 'Лайк'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white, size: 30.0),
          onPressed: () {},
        ),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }
}