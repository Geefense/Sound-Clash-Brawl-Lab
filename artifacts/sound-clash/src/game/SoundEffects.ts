export class SoundEffects {
  private context: AudioContext | null = null;
  private enabled = false;

  setEnabled(enabled: boolean) {
    this.enabled = enabled;
    if (enabled && !this.context) {
      const AudioContextClass = window.AudioContext;
      if (AudioContextClass) this.context = new AudioContextClass();
    }
    if (enabled && this.context?.state === 'suspended') void this.context.resume();
  }

  play(kind: 'hit' | 'block' | 'jump' | 'round') {
    if (!this.enabled || !this.context) return;
    const now = this.context.currentTime;
    const oscillator = this.context.createOscillator();
    const gain = this.context.createGain();
    oscillator.type = kind === 'hit' ? 'sawtooth' : 'triangle';
    const tones = { hit: 110, block: 210, jump: 310, round: 170 };
    oscillator.frequency.setValueAtTime(tones[kind], now);
    oscillator.frequency.exponentialRampToValueAtTime(Math.max(55, tones[kind] * 0.52), now + 0.11);
    gain.gain.setValueAtTime(kind === 'hit' ? 0.07 : 0.035, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.13);
    oscillator.connect(gain);
    gain.connect(this.context.destination);
    oscillator.start(now);
    oscillator.stop(now + 0.14);
  }

  dispose() {
    void this.context?.close();
    this.context = null;
  }
}
