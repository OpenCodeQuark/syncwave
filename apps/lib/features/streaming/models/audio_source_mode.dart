enum AudioSourceMode {
  systemAudio('Audio Source', 'Capture system/device audio', true),
  microphone('Microphone', 'Overlay microphone input', true),
  systemAudioWithMic(
    'Audio Source + Mic',
    'Combine device audio and microphone',
    true,
  );

  const AudioSourceMode(this.label, this.availabilityNote, this.enabled);

  final String label;
  final String availabilityNote;
  final bool enabled;
}
