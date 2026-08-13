"""
Task 3 -- audio metrics extraction.

Uses ffprobe (for structural metadata: duration, sample rate, bitrate)
and ffmpeg's volumedetect + silencedetect filters (for loudness and a
rough noise/quality estimate). Chosen over a Python audio library
(pydub/librosa) because ffmpeg/ffprobe are already installed here,
handle virtually any input codec/container a browser might produce
(webm/opus, wav, mp3, m4a...), and are the same tools used in
production audio pipelines.
"""
import json
import re
import subprocess


def _run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=60)


def probe_structural(file_path):
    """duration (sec), sample_rate (Hz), bitrate (kbps), channels -- via ffprobe."""
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_format", "-show_streams", str(file_path),
    ]
    result = _run(cmd)
    if result.returncode != 0:
        raise RuntimeError(f"ffprobe failed: {result.stderr}")

    data = json.loads(result.stdout)
    fmt = data.get("format", {})
    audio_stream = next((s for s in data.get("streams", []) if s.get("codec_type") == "audio"), None)
    if audio_stream is None:
        raise RuntimeError("No audio stream found in file")

    duration = float(fmt.get("duration") or audio_stream.get("duration") or 0)
    sample_rate = int(audio_stream.get("sample_rate", 0))

    # Prefer the stream's own bit_rate; fall back to container-level bit_rate
    bitrate_bps = audio_stream.get("bit_rate") or fmt.get("bit_rate")
    bitrate_kbps = round(int(bitrate_bps) / 1000, 2) if bitrate_bps else None

    return {
        "duration_sec": round(duration, 2),
        "sample_rate_hz": sample_rate,
        "bitrate_kbps": bitrate_kbps,
        "channels": audio_stream.get("channels"),
    }


def measure_loudness(file_path):
    """
    Mean and max volume in dBFS via ffmpeg's volumedetect filter.
    dBFS = decibels relative to full scale; 0 is the loudest possible
    digital sample, so values are always <= 0. Quieter audio = more negative.
    """
    cmd = [
        "ffmpeg", "-i", str(file_path), "-af", "volumedetect",
        "-f", "null", "-",
    ]
    result = _run(cmd)  # ffmpeg writes filter output to stderr, exit code 0 expected
    stderr = result.stderr

    mean_match = re.search(r"mean_volume:\s*(-?\d+\.?\d*)\s*dB", stderr)
    max_match = re.search(r"max_volume:\s*(-?\d+\.?\d*)\s*dB", stderr)

    mean_volume = float(mean_match.group(1)) if mean_match else None
    max_volume = float(max_match.group(1)) if max_match else None
    return mean_volume, max_volume


def estimate_noise_floor(file_path, noise_threshold_db="-30dB", min_silence_sec=0.3):
    """
    Bonus: rough noise/quality estimate. Uses ffmpeg's silencedetect to
    find quiet stretches (treated as a proxy for the room's noise floor).
    If no silence is detected at this threshold, the whole clip is above
    it -- we report that rather than guessing a number.
    """
    cmd = [
        "ffmpeg", "-i", str(file_path), "-af",
        f"silencedetect=noise={noise_threshold_db}:d={min_silence_sec}",
        "-f", "null", "-",
    ]
    result = _run(cmd)
    silence_starts = re.findall(r"silence_start:\s*(-?\d+\.?\d*)", result.stderr)
    return len(silence_starts) > 0  # True if measurable quiet stretches exist


def quality_estimate(mean_volume, max_volume, has_silence):
    """
    Rough, explainable quality label -- not a claim of scientific
    accuracy, just enough signal for a human reviewer to triage submissions.

    Based on loudness thresholds only (mean/peak dBFS). I initially tried
    folding the silencedetect result in here too (reasoning: "no quiet
    stretches at all -> constant background noise"), but that's a bad
    inference -- a clean sustained tone and a noisy recording both lack
    silence, so it mislabeled clean audio as noisy. Kept has_silence as a
    separate diagnostic value instead of baking it into this label.
    """
    if mean_volume is None:
        return "unknown"
    if max_volume is not None and max_volume >= -0.5:
        return "clipping_risk"       # audio hit/near 0 dBFS, likely distorted
    if mean_volume < -35:
        return "very_quiet"          # probably too far from mic
    if mean_volume > -12:
        return "good"                 # healthy recording level
    return "acceptable"               # usable but not ideal (-35 to -12 dBFS)


def analyze_audio(file_path):
    """Run the full analysis and return a dict matching the audio_submissions schema."""
    structural = probe_structural(file_path)
    mean_volume, max_volume = measure_loudness(file_path)
    has_silence = estimate_noise_floor(file_path)  # diagnostic only, see quality_estimate() docstring
    quality = quality_estimate(mean_volume, max_volume, has_silence)

    return {
        **structural,
        "loudness_dbfs": mean_volume,
        "peak_dbfs": max_volume,
        "quality_estimate": quality,
        "has_quiet_stretches": has_silence,
    }
