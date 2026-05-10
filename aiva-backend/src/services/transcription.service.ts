import OpenAI from 'openai';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { spawn } from 'child_process';
import { v4 as uuidv4 } from 'uuid';
import { env } from '../config/env';
import { TranscriptSegment } from '../types';

interface WhisperSegment {
  id: number;
  seek: number;
  start: number;
  end: number;
  text: string;
  tokens: number[];
  temperature: number;
  avg_logprob: number;
  compression_ratio: number;
  no_speech_prob: number;
}

// Whisper API hard limit is 25 MB — stay 1 MB under to be safe
const WHISPER_MAX_BYTES = 24 * 1024 * 1024;

export class TranscriptionService {
  private client: OpenAI;

  constructor() {
    this.client = new OpenAI({ apiKey: env.OPENAI_API_KEY });
  }

  private formatTimestamp(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
  }

  // Use ffmpeg to strip video and compress audio to mono 16kHz MP3.
  // At 32 kbps this keeps a 1-hour lecture under 15 MB — well within the Whisper limit.
  private extractAudio(videoPath: string, bitrate = '32k'): Promise<string> {
    const tempPath = path.join(os.tmpdir(), `aiva_audio_${Date.now()}.mp3`);
    console.log(`[Transcription] Extracting audio at ${bitrate} → ${tempPath}`);

    return new Promise((resolve, reject) => {
      const proc = spawn('ffmpeg', [
        '-i', videoPath,
        '-vn',                   // drop video stream
        '-acodec', 'libmp3lame', // MP3 codec
        '-ac', '1',              // mono — speech doesn't need stereo
        '-ar', '16000',          // 16 kHz — Whisper's native sample rate
        '-ab', bitrate,
        '-y',                    // overwrite without prompting
        tempPath,
      ]);

      let stderr = '';
      proc.stderr?.on('data', (d: Buffer) => { stderr += d.toString(); });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve(tempPath);
        } else {
          reject(new Error(
            `[Transcription] ffmpeg exited ${code}. ` +
            `Last output: ${stderr.slice(-400)}`
          ));
        }
      });

      proc.on('error', (err: NodeJS.ErrnoException) => {
        if (err.code === 'ENOENT') {
          reject(new Error(
            '[Transcription] ffmpeg not found. Install it to process large video files:\n' +
            '  Windows : winget install Gyan.FFmpeg\n' +
            '  macOS   : brew install ffmpeg\n' +
            '  Ubuntu  : sudo apt install ffmpeg'
          ));
        } else {
          reject(err);
        }
      });
    });
  }

  async transcribeVideo(videoPath: string): Promise<TranscriptSegment[]> {
    console.log('[Transcription] Starting transcription for:', videoPath);

    const absolutePath = path.isAbsolute(videoPath)
      ? videoPath
      : path.join(process.cwd(), videoPath);

    if (!fs.existsSync(absolutePath)) {
      throw new Error(`[Transcription] Video file not found: ${absolutePath}`);
    }

    const stats = fs.statSync(absolutePath);
    const fileSizeMB = stats.size / (1024 * 1024);
    console.log(`[Transcription] File size: ${fileSizeMB.toFixed(2)} MB`);

    if (fileSizeMB > env.MAX_FILE_SIZE_MB) {
      throw new Error(
        `[Transcription] File too large: ${fileSizeMB.toFixed(2)} MB. ` +
        `Max allowed: ${env.MAX_FILE_SIZE_MB} MB`
      );
    }

    let transcriptionPath = absolutePath;
    let tempAudioPath: string | null = null;

    try {
      if (stats.size > WHISPER_MAX_BYTES) {
        console.log(
          `[Transcription] File (${fileSizeMB.toFixed(1)} MB) exceeds Whisper's 25 MB limit. ` +
          `Extracting compressed audio with ffmpeg...`
        );

        tempAudioPath = await this.extractAudio(absolutePath, '32k');
        let audioStats = fs.statSync(tempAudioPath);

        // If 32 kbps is still over the limit (lecture > ~1.7 h), drop to 16 kbps
        if (audioStats.size > WHISPER_MAX_BYTES) {
          console.log('[Transcription] 32k audio still too large, re-extracting at 16k...');
          fs.unlinkSync(tempAudioPath);
          tempAudioPath = await this.extractAudio(absolutePath, '16k');
          audioStats = fs.statSync(tempAudioPath);
        }

        const audioMB = audioStats.size / (1024 * 1024);
        console.log(`[Transcription] Compressed audio: ${audioMB.toFixed(2)} MB`);

        if (audioStats.size > WHISPER_MAX_BYTES) {
          throw new Error(
            `[Transcription] Compressed audio (${audioMB.toFixed(1)} MB) still exceeds Whisper's 25 MB limit. ` +
            `This lecture is very long. Try splitting it into shorter segments (< 3 hours each).`
          );
        }

        transcriptionPath = tempAudioPath;
      }

      console.log('[Transcription] Calling Whisper API...');

      let response;
      try {
        response = await this.client.audio.transcriptions.create({
          file: fs.createReadStream(transcriptionPath),
          model: 'whisper-1',
          response_format: 'verbose_json',
        });
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        throw new Error(`[Transcription] Whisper API failed: ${message}`);
      }

      const rawResponse = response as unknown as { segments?: WhisperSegment[] };

      if (!rawResponse.segments || rawResponse.segments.length === 0) {
        throw new Error('[Transcription] Whisper returned no segments. The audio may be silent or corrupt.');
      }

      console.log(`[Transcription] Received ${rawResponse.segments.length} segments from Whisper`);

      const segments: TranscriptSegment[] = rawResponse.segments.map((seg) => ({
        id: uuidv4(),
        start: seg.start,
        end: seg.end,
        text: seg.text.trim(),
        timestamp_label: this.formatTimestamp(seg.start),
      }));

      console.log('[Transcription] Done. Total segments:', segments.length);
      return segments;
    } finally {
      if (tempAudioPath && fs.existsSync(tempAudioPath)) {
        fs.unlinkSync(tempAudioPath);
        console.log('[Transcription] Cleaned up temp audio file');
      }
    }
  }
}

export const transcriptionService = new TranscriptionService();
