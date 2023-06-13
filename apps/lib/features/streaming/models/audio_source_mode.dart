enum AudioSourceMode {
  systemAudio('System Audio', 'Planned for Phase 5', false),
  microphone('Microphone', 'Planned for Phase 4', false),
  systemAudioWithMic('System Audio + Mic', 'Planned for later phase', false);

  const AudioSourceMode(this.label, this.availabilityNote, this.enabled);

  final String label;
  final String availabilityNote;
  final bool enabled;
}
