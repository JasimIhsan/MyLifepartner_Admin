enum FeatureKey {
  audioCall('audio_call'),
  videoCall('video_call'),
  sendMessage('send_message'),
  profileBlur('profile_blur'),
  maxInterests('max_interests'),
  maxVideoCallMinutes('max_video_call_minutes'),
  maxAudioCallMinutes('max_audio_call_minutes'),
  maxMessages('max_messages'),
  unknown('unknown');

  final String value;
  const FeatureKey(this.value);

  static FeatureKey fromString(String? key) {
    return FeatureKey.values.firstWhere(
      (e) => e.value == key,
      orElse: () => FeatureKey.unknown,
    );
  }
}
