import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rhythm_box/providers/spotify.dart';

class TrackHeartButton extends StatefulWidget {
  final String trackId;

  const TrackHeartButton({super.key, required this.trackId});

  @override
  State<TrackHeartButton> createState() => _TrackHeartButtonState();
}

class _TrackHeartButtonState extends State<TrackHeartButton> {
  late final SpotifyProvider _spotify = Get.find();

  bool _isLoading = true;

  bool _isLiked = false;

  Future<void> _pullHeart() async {
    final res = await _spotify.api.tracks.me.containsOne(widget.trackId);
    setState(() {
      _isLiked = res;
      _isLoading = false;
    });
  }

  Future<void> _toggleHeart() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    if (_isLiked) {
      await _spotify.api.tracks.me.removeOne(widget.trackId);
      _isLiked = false;
    } else {
      await _spotify.api.tracks.me.saveOne(widget.trackId);
      _isLiked = true;
    }

    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    _pullHeart();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Icon(
          _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          key: ValueKey(_isLiked),
          color: _isLiked ? Colors.red[600] : null,
        ),
      ),
      onPressed: _isLoading ? null : _toggleHeart,
    );
  }
}
