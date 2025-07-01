import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

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
  bool _showControls = true;
  List<Map<String, dynamic>> _reviews = [];
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isCommentLoading = false;
  Timer? _controlsTimer;
  double _volume = 1.0;
  bool _showVolumeSlider = false;
  Timer? _sleepTimer;
  bool _isTimerActive = false;
  bool _isFadingOut = false;
  double _playbackSpeed = 1.0;
  Duration? _remainingTime;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadReviews();
    _startControlsTimer();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
          _showVolumeSlider = false;
        });
      }
    });
  }

  void _resetControlsTimer() {
    _startControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _resetControlsTimer();
    });
  }

  Future<void> _initializeVideo() async {
    try {
      final response = await _supabase
          .from('films')
          .select('url_film, name_film, year, age_rating, desc, rating, rating_num, duration')
          .eq('id', widget.id as Object)
          .single();

      setState(() {
        _movie = response;
        _isLoading = false;
      });

      _controller = VideoPlayerController.networkUrl(Uri.parse(_movie['url_film']))
        ..addListener(() {
          if (mounted) setState(() {});
        })
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller.play();
            _controller.setVolume(_volume);
            _resetControlsTimer();
          }
        });

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
      await _supabase.from('reviews').insert({
        'id_film': widget.id,
        'review_text': _commentController.text,
        'rating': _selectedRating,
        'id_user': _supabase.auth.currentUser?.id,
      });

      await _supabase.rpc('update_film_rating', params: {
        'film_id': widget.id,
        'new_rating': _selectedRating,
      });

      await _initializeVideo();
      await _loadReviews();

      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _isCommentLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Комментарий добавлен')),
      );
    } catch (e) {
      setState(() => _isCommentLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
      print('Error submitting comment: $e');
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      _controller.setVolume(_volume);
      _resetControlsTimer();
    });
  }

  void _toggleVolumeSlider() {
    setState(() {
      _showVolumeSlider = !_showVolumeSlider;
      _showControls = true;
      _resetControlsTimer();
    });
  }

  void _changeSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _controller.setPlaybackSpeed(speed);
      _resetControlsTimer();
    });
  }

  void _toggleFullscreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: _buildVideoPlayer(),
            ),
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _showTimerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Таймер просмотра', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_isTimerActive) ...[
                Text('Осталось: ${_formatDuration(_remainingTime)}', 
                    style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isTimerActive = false);
                    _sleepTimer?.cancel();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Отменить таймер'),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('1 мин (тест)'),
                    onPressed: () {
                      _setMovieTimer(const Duration(minutes: 1));
                      Navigator.pop(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('30 мин'),
                    onPressed: () {
                      _setMovieTimer(const Duration(minutes: 30));
                      Navigator.pop(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('1 час'),
                    onPressed: () {
                      _setMovieTimer(const Duration(hours: 1));
                      Navigator.pop(context);
                    },
                  ),
                  ActionChip(
                    label: const Text('До конца'),
                    onPressed: () {
                      final remaining = Duration(minutes: _movie['duration'] ?? 120) - _controller.value.position;
                      _setMovieTimer(remaining);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

void _setMovieTimer(Duration duration) {
  _sleepTimer?.cancel();
  setState(() {
    _isTimerActive = true;
    _remainingTime = duration;
  });
  
  final startTime = DateTime.now();
  
  _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (mounted) {
      final elapsed = DateTime.now().difference(startTime);
      setState(() {
        _remainingTime = duration - elapsed;
      });
      
      if (_remainingTime!.inSeconds <= 0) {
        timer.cancel();
        if (_controller.value.isPlaying) {
          _controller.pause();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Время просмотра истекло')),
          );
          setState(() {
            _isTimerActive = false;
            _remainingTime = null;
          });
        }
      }
    }
  });
}

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isInitialized)
            const CircularProgressIndicator(),
          if (_showControls) ...[
            _TopControls(
              onBack: () => Navigator.pop(context),
              onTimer: _showTimerMenu,
              isTimerActive: _isTimerActive,
              remainingTime: _remainingTime,
            ),
            _BottomControls(
              controller: _controller,
              onSpeedChanged: _changeSpeed,
              onFullscreen: _toggleFullscreen,
              onVolumePressed: _toggleVolumeSlider,
              volume: _volume,
              showVolumeSlider: _showVolumeSlider,
              onVolumeChanged: _setVolume,
              playbackSpeed: _playbackSpeed,
            ),
            if (_showVolumeSlider) _VolumeSliderOverlay(
              volume: _volume,
              onVolumeChanged: _setVolume,
            ),
          ],
          if (_isTimerActive && _remainingTime != null)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDuration(_remainingTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (!_showControls && _controller.value.isPlaying)
            Opacity(
              opacity: 0.5,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _movie['name_film'] ?? 'Название не указано',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Text(
                '${_movie['year'] ?? ''}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(width: 16.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '${_movie['age_rating'] ?? '0+'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            _movie['desc'] ?? 'Описание отсутствует',
            style: const TextStyle(
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Оставить отзыв',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ваш отзыв...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[900],
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Оценка:',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8.0),
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
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCommentLoading ? null : _submitComment,
              child: _isCommentLoading
                  ? const CircularProgressIndicator()
                  : const Text('Отправить отзыв'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return const Padding(
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
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final user = review['users'] as Map<String, dynamic>? ?? {};
        
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      user['username'] ?? 'Аноним',
                      style: const TextStyle(
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
                const SizedBox(height: 8.0),
                Text(
                  review['review_text'] ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '${review['created_at']?.toString().substring(0, 10) ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Ошибка загрузки видео', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _initializeVideo,
            child: const Text('Повторить попытку'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _sleepTimer?.cancel();
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? _buildErrorWidget()
                : CustomScrollView(
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
                          padding: const EdgeInsets.only(left: 16.0, top: 24.0),
                          child: const Text(
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
                  ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onTimer;
  final bool isTimerActive;
  final Duration? remainingTime;

  const _TopControls({
    required this.onBack,
    required this.onTimer,
    required this.isTimerActive,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              const Spacer(),
              if (isTimerActive && remainingTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(remainingTime),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.timer, color: Colors.white),
                onPressed: onTimer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours}:$minutes:$seconds";
  }
}

class _BottomControls extends StatelessWidget {
  final VideoPlayerController controller;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onFullscreen;
  final VoidCallback onVolumePressed;
  final double volume;
  final bool showVolumeSlider;
  final ValueChanged<double> onVolumeChanged;
  final double playbackSpeed;

  const _BottomControls({
    required this.controller,
    required this.onSpeedChanged,
    required this.onFullscreen,
    required this.onVolumePressed,
    required this.volume,
    required this.showVolumeSlider,
    required this.onVolumeChanged,
    required this.playbackSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.grey,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                      },
                    ),
                    Text(
                      controller.value.position.toString().split('.').first,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        volume > 0.66 
                            ? Icons.volume_up 
                            : volume > 0 
                                ? Icons.volume_down 
                                : Icons.volume_off,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: onVolumePressed,
                    ),
                    PopupMenuButton<double>(
                      icon: Text('${playbackSpeed}x', style: const TextStyle(color: Colors.white)),
                      itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0]
                          .map((speed) => PopupMenuItem(
                                value: speed,
                                child: Text('${speed}x'),
                              ))
                          .toList(),
                      onSelected: onSpeedChanged,
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                      onPressed: onFullscreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolumeSliderOverlay extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const _VolumeSliderOverlay({
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          color: Colors.black.withValues(alpha: 0.7),
          child: Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0,
                  max: 1,
                  onChanged: onVolumeChanged,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}