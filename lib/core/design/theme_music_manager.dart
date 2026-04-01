import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:games/features/settings/presentation/providers/settings_providers.dart';

class ThemeMusicManager extends ConsumerStatefulWidget {
  final Widget child;
  const ThemeMusicManager({super.key, required this.child});

  @override
  ConsumerState<ThemeMusicManager> createState() => _ThemeMusicManagerState();
}

class _ThemeMusicManagerState extends ConsumerState<ThemeMusicManager> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  String? _currentMusicPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      final settings = ref.read(generalSettingsProvider).maybeWhen(data: (s) => s, orElse: () => null);
      if (settings != null) {
        final theme = settings['app_theme'] as String?;
        final customMusicEnabled = settings['custom_music_enabled'] == true;
        final christmasMusicEnabled = settings['christmas_music_enabled'] == true;
        final holyWeekMusicEnabled = settings['holy_week_music_enabled'] == true;
        final resurrectionMusicEnabled = settings['resurrection_music_enabled'] == true;

        if ((theme == 'custom' && customMusicEnabled) || 
            (theme == 'christmas' && christmasMusicEnabled) ||
            (theme == 'holy_week' && holyWeekMusicEnabled) ||
            (theme == 'resurrection' && resurrectionMusicEnabled)) {
          _audioPlayer.resume();
        }
      }
    }
  }

  void _manageMusic(Map<String, dynamic> settings) async {
    final themeId = settings['app_theme'] as String?;
    final musicEnabled = settings['custom_music_enabled'] as bool? ?? false;
    final musicPath = settings['custom_music_path'] as String?;

    final isCustom = themeId == 'custom' && musicEnabled && musicPath != null && musicPath.isNotEmpty;
    final isChristmas = themeId == 'christmas' && (settings['christmas_music_enabled'] ?? true);
    final isHolyWeek = themeId == 'holy_week' && (settings['holy_week_music_enabled'] ?? true);
    final isResurrection = themeId == 'resurrection' && (settings['resurrection_music_enabled'] ?? true);

    if (isCustom) {
      if (_currentMusicPath != musicPath) {
        _currentMusicPath = musicPath;
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(DeviceFileSource(musicPath));
        } catch (e) {
          debugPrint('Error playing custom theme music: $e');
        }
      }
    } else if (isChristmas) {
      const christmasMusic = 'We Wish You a Merry Christmas-1810407330.mp3';
      if (_currentMusicPath != christmasMusic) {
        _currentMusicPath = christmasMusic;
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource(christmasMusic));
        } catch (e) {
          debugPrint('Error playing christmas music: $e');
        }
      }
    } else if (isHolyWeek) {
      const holyWeekMusic = 'holy_week_music.mp3';
      if (_currentMusicPath != holyWeekMusic) {
        _currentMusicPath = holyWeekMusic;
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource(holyWeekMusic));
        } catch (e) {
          debugPrint('Error playing holy week music: $e');
        }
      }
    } else if (isResurrection) {
      const resurrectionMusic = 'resurrection_music.mp3';
      if (_currentMusicPath != resurrectionMusic) {
        _currentMusicPath = resurrectionMusic;
        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(AssetSource(resurrectionMusic));
        } catch (e) {
          debugPrint('Error playing resurrection music: $e');
        }
      }
    } else {
      // If we shouldn't play, but something is playing or we have a path recorded
      if (_currentMusicPath != null) {
        _currentMusicPath = null;
        await _audioPlayer.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to ensure we react to settings updates
    ref.listen<AsyncValue<Map<String, dynamic>>>(generalSettingsProvider, (previous, next) {
      next.whenData(_manageMusic);
    });

    // Check once on build to handle initial state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(generalSettingsProvider).maybeWhen(data: (s) => s, orElse: () => null);
      if (settings != null) _manageMusic(settings);
    });

    return widget.child;
  }
}
