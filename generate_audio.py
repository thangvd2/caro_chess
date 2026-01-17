import wave
import math
import struct

def generate_tone(filename, frequency, duration_ms, volume=0.5):
    sample_rate = 44100
    n_samples = int(sample_rate * (duration_ms / 1000.0))
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 2 bytes per sample (16-bit PCM)
        wav_file.setframerate(sample_rate)
        
        for i in range(n_samples):
            # Sine wave
            t = float(i) / sample_rate
            value = int(volume * 32767.0 * math.sin(2.0 * math.pi * frequency * t))
            
            # Apply decay for "ping" effect
            decay = 1.0 - (float(i) / n_samples)
            value = int(value * decay)
            
            data = struct.pack('<h', value)
            wav_file.writeframes(data)

# Generate Start Sound (A4 Ping, 1 second)
print("Generating assets/audio/start.wav...")
generate_tone('assets/audio/start.wav', 440.0, 1000)

# Generate Tick Sound (High C Ping, 100ms)
print("Generating assets/audio/tick.wav...")
generate_tone('assets/audio/tick.wav', 880.0, 100)

print("Audio generation complete.")
