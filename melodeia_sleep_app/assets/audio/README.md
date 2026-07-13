# Bundled Offline Sleep Audio

This directory houses the offline loopable audio files used by `SleepAudioService` to guide users during breathing cycles and sleep sessions.

---

## 🎵 Required Files & Specifications

All files should be loopable (unless they are triggers), optimized for low power consumption, and have smooth transitions (no clicks or pops at loop points).

| Filename | Purpose | Recommended Length | Suggested Format |
| :--- | :--- | :--- | :--- |
| `white_noise_loop.mp3` | Continuous masking ambient noise | 60–120 seconds (loopable) | Stereo MP3, 128kbps |
| `breath_in.mp3` | Audio cue indicating the inhalation phase | 3–4 seconds | Mono/Stereo MP3 |
| `breath_out.mp3` | Audio cue indicating the exhalation phase | 4–6 seconds | Mono/Stereo MP3 |
| `heartbeat_loop.mp3` | Slow rhythmic heartbeat loop (60 BPM) | 10–20 seconds (loopable) | Mono/Stereo MP3 |

---

## 🤖 AI Audio Generation Prompts

You can use text-to-audio generators (e.g., Suno, Udio, ElevenLabs, Stable Audio, or AudioCraft) to produce these assets. Use the prompts below:

### 1. `white_noise_loop.mp3`
> **Prompt:** 
> *Deep soothing pink noise, loopable, steady low-frequency ambient sound, gentle ocean shore wave wash, no music, no high-pitch frequencies, relaxing background sleep aid, high-quality audio, seamless loop.*

### 2. `breath_in.mp3`
> **Prompt:** 
> *Soft ambient synthesizer swell, ascending pitch, gentle breath inhale cue, whispering wind gust rising, airy and calm, 4 seconds duration, clean background, sound effect, relaxation aid, no high frequencies.*

### 3. `breath_out.mp3`
> **Prompt:** 
> *Soft ambient synthesizer fade, descending pitch, gentle breath exhale cue, whispering wind gust falling, airy and calm, 5 seconds duration, clean background, sound effect, relaxation aid, gentle sigh.*

### 4. `heartbeat_loop.mp3`
> **Prompt:** 
> *Slow rhythmic heartbeat sound, loopable, 60 BPM, deep muted double thumps, lub-dub rhythm, calming heartbeat sound effect, clean recording, no background music, sleep aid, seamless loop.*

