import fs from 'fs';
import path from 'path';
import { spawn } from 'child_process';
import {
  GifMode,
  AnimationStyleId,
  GifGenerationSettings,
  GifJobStage,
  GifJobResult,
  GifHistoryItem,
} from './gifStudioTypes';

export interface CreateGifJobInput {
  userId?: string;
  mode: GifMode;
  style: AnimationStyleId;
  prompt?: string;
  duration?: number;
  fps?: number;
  quality?: 'standard' | 'high';
  aspectRatio?: 'original' | '1:1' | '4:5' | '9:16' | '16:9';
  imageBuffer?: Buffer;
  imageMimeType?: string;
  originalImageBase64?: string;
}

export interface GifJobStatusResponse {
  jobId: string;
  status: GifJobStage;
  progress: number;
  stepLabel: string;
  error?: string;
  result?: GifJobResult;
  creditCost: number;
  createdAt: string;
}

const OUTPUTS_DIR = path.join(process.cwd(), 'public', 'outputs', 'gifs');
const JOBS_DIR = path.join(OUTPUTS_DIR, 'jobs');
const UPLOADS_DIR = path.join(process.cwd(), 'public', 'uploads', 'gif_inputs');
const HISTORY_FILE = path.join(OUTPUTS_DIR, 'history.json');

// Ensure directories exist
function ensureDirs() {
  if (!fs.existsSync(OUTPUTS_DIR)) fs.mkdirSync(OUTPUTS_DIR, { recursive: true });
  if (!fs.existsSync(JOBS_DIR)) fs.mkdirSync(JOBS_DIR, { recursive: true });
  if (!fs.existsSync(UPLOADS_DIR)) fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

export function calculateCreditCost(duration: number, quality: string): number {
  // 1 credit for standard <= 3s, 2 credits for high or 4-5s
  if (quality === 'high' || duration > 3) {
    return 2;
  }
  return 1;
}

export async function startGifJob(input: CreateGifJobInput): Promise<{ jobId: string; creditCost: number }> {
  ensureDirs();

  const jobId = `gif_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
  const duration = (input.duration || 3) as 2 | 3 | 4 | 5;
  const fps = (input.fps || 12) as 8 | 12 | 15;
  const quality = input.quality || 'high';
  const aspectRatio = input.aspectRatio || 'original';
  const style = input.style || 'natural_motion';
  const prompt = (input.prompt || '').trim();
  const creditCost = calculateCreditCost(duration, quality);

  let inputImagePath: string | null = null;
  let originalImageUrl: string | null = null;

  // Handle uploaded image if provided
  if (input.imageBuffer) {
    const ext = input.imageMimeType?.includes('png') ? 'png' : 'jpg';
    inputImagePath = path.join(UPLOADS_DIR, `${jobId}_input.${ext}`);
    fs.writeFileSync(inputImagePath, input.imageBuffer);
    originalImageUrl = `/uploads/gif_inputs/${jobId}_input.${ext}`;
  } else if (input.originalImageBase64) {
    const base64Data = input.originalImageBase64.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    inputImagePath = path.join(UPLOADS_DIR, `${jobId}_input.png`);
    fs.writeFileSync(inputImagePath, buffer);
    originalImageUrl = `/uploads/gif_inputs/${jobId}_input.png`;
  }

  const outputGifPath = path.join(OUTPUTS_DIR, `${jobId}.gif`);
  const statusFilePath = path.join(JOBS_DIR, `${jobId}.json`);

  // Write initial status
  const initialStatus = {
    status: 'queued',
    progress: 5,
    stepLabel: 'Job enqueued. Initializing studio pipeline...',
    creditCost,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  fs.writeFileSync(statusFilePath, JSON.stringify(initialStatus, null, 2));

  // Write job config for Python engine
  const jobConfig = {
    jobId,
    userId: input.userId || 'anonymous',
    mode: input.mode,
    style,
    prompt,
    duration,
    fps,
    quality,
    aspectRatio,
    creditCost,
    inputImagePath,
    originalImageUrl,
    outputGifPath,
    statusFilePath,
    createdAt: initialStatus.createdAt,
  };

  const configPath = path.join(JOBS_DIR, `${jobId}_config.json`);
  fs.writeFileSync(configPath, JSON.stringify(jobConfig, null, 2));

  // Launch background Python process asynchronously
  const enginePath = path.join(process.cwd(), 'lib', 'gif_engine.py');
  const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';

  const child = spawn(pythonCmd, [enginePath, configPath], {
    detached: true,
    stdio: 'ignore',
    env: {
      ...process.env,
    },
  });

  child.unref();

  return { jobId, creditCost };
}

export function getGifJobStatus(jobId: string): GifJobStatusResponse | null {
  ensureDirs();
  const statusFilePath = path.join(JOBS_DIR, `${jobId}.json`);

  if (!fs.existsSync(statusFilePath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(statusFilePath, 'utf-8');
    const data = JSON.parse(content);

    // If completed and not yet in history, append to history
    if (data.status === 'completed' && data.result) {
      recordJobInHistory(data.result);
    }

    return {
      jobId,
      status: data.status,
      progress: data.progress || 0,
      stepLabel: data.stepLabel || 'Processing...',
      error: data.error,
      result: data.result,
      creditCost: data.creditCost || 1,
      createdAt: data.createdAt || new Date().toISOString(),
    };
  } catch (err) {
    console.error('Error reading job status:', err);
    return null;
  }
}

export function recordJobInHistory(result: GifJobResult) {
  try {
    ensureDirs();
    let history: GifHistoryItem[] = [];
    if (fs.existsSync(HISTORY_FILE)) {
      try {
        const raw = fs.readFileSync(HISTORY_FILE, 'utf-8');
        history = JSON.parse(raw);
      } catch {
        history = [];
      }
    }

    // Check if already in history
    if (!history.some((h) => h.id === result.jobId)) {
      const item: GifHistoryItem = {
        id: result.jobId,
        gifUrl: result.gifUrl,
        thumbnailUrl: result.originalImageUrl || result.gifUrl,
        originalImageUrl: result.originalImageUrl,
        mode: result.mode,
        style: result.style,
        prompt: result.prompt,
        duration: result.duration,
        fps: result.fps,
        frameCount: result.frameCount,
        fileSizeFormatted: result.fileSizeFormatted,
        createdAt: result.completedAt || result.createdAt,
      };

      // Keep latest 25 items
      history.unshift(item);
      if (history.length > 25) {
        history = history.slice(0, 25);
      }

      fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
    }
  } catch (err) {
    console.error('Failed to record job in history:', err);
  }
}

export function getGifHistory(): GifHistoryItem[] {
  try {
    ensureDirs();
    if (fs.existsSync(HISTORY_FILE)) {
      const raw = fs.readFileSync(HISTORY_FILE, 'utf-8');
      const items = JSON.parse(raw);
      // Filter out files that don't exist
      return items.filter((item: GifHistoryItem) => {
        const localPath = path.join(process.cwd(), 'public', item.gifUrl.replace(/^\//, ''));
        return fs.existsSync(localPath);
      });
    }
  } catch (err) {
    console.error('Error fetching GIF history:', err);
  }
  return [];
}
