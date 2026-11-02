// Server-side Topaz Labs API Client
// Note: This file only executes on the server (API routes / server actions).
// The API key is NEVER sent to the client browser.

export interface TopazEnhanceOptions {
  model?: string;
  output_format?: string;
  crop_to_fill?: boolean;
  scale_factor?: string;
  output_width?: number;
  output_height?: number;
  face_enhancement?: boolean;
  face_enhancement_strength?: number;
  face_enhancement_creativity?: number;
  prompt?: string;
  [key: string]: any;
}

export class TopazClient {
  private apiKey: string;
  private baseUrl: string;

  constructor() {
    this.apiKey = process.env.TOPAZ_API_KEY || '5012739d-5a5b-48ca-a5e3-1b808ba3d9a8';
    this.baseUrl = process.env.TOPAZ_API_BASE || 'https://api.topazlabs.com/image/v1';
  }

  getHeaders() {
    return {
      'X-API-Key': this.apiKey,
      'Accept': 'application/json, image/*',
    };
  }

  /**
   * Health check / Ping endpoint to verify Topaz API connection
   */
  async checkConnection(): Promise<{ ok: boolean; status: number; message: string }> {
    try {
      const res = await fetch(`${this.baseUrl}/enhance`, {
        method: 'OPTIONS',
        headers: this.getHeaders(),
      });
      return {
        ok: res.status >= 200 && res.status < 400,
        status: res.status,
        message: res.status === 204 ? 'Topaz Platform API Connected (Ready)' : `Status ${res.status}`,
      };
    } catch (err: any) {
      return {
        ok: false,
        status: 500,
        message: err?.message || 'Network error reaching Topaz API',
      };
    }
  }

  /**
   * Poll an async Topaz job until completed, and retrieve the download URL
   */
  async pollAndDownload(
    processId: string,
    maxWaitMs: number = 120000
  ): Promise<{ success: boolean; dataUrl?: string; error?: string }> {
    const startTime = Date.now();
    const intervalMs = 1500;

    while (Date.now() - startTime < maxWaitMs) {
      await new Promise((resolve) => setTimeout(resolve, intervalMs));

      const statusRes = await fetch(`${this.baseUrl}/status/${processId}`, {
        headers: { 'X-API-Key': this.apiKey },
      });

      if (!statusRes.ok) {
        const errText = await statusRes.text();
        return {
          success: false,
          error: `Failed to check status for process ${processId}: ${errText.slice(0, 200)}`,
        };
      }

      const statusJson = await statusRes.json();
      if (statusJson.status === 'Completed') {
        const downloadRes = await fetch(`${this.baseUrl}/download/${processId}`, {
          headers: { 'X-API-Key': this.apiKey },
        });

        if (!downloadRes.ok) {
          const errText = await downloadRes.text();
          return {
            success: false,
            error: `Failed to get download URL for process ${processId}: ${errText.slice(0, 200)}`,
          };
        }

        const downloadJson = await downloadRes.json();
        const downloadUrl = downloadJson.download_url || downloadJson.head_url;
        if (!downloadUrl) {
          return {
            success: false,
            error: 'No download URL returned by Topaz for completed job',
          };
        }

        // Fetch the output image binary directly to provide a clean base64 data URL
        const imageRes = await fetch(downloadUrl);
        if (!imageRes.ok) {
          // If direct binary fetch fails, return the signed download URL directly
          return { success: true, dataUrl: downloadUrl };
        }

        const imageBuffer = await imageRes.arrayBuffer();
        const contentType = imageRes.headers.get('content-type') || 'image/jpeg';
        const base64 = Buffer.from(imageBuffer).toString('base64');
        return {
          success: true,
          dataUrl: `data:${contentType};base64,${base64}`,
        };
      }

      if (statusJson.status === 'Failed' || statusJson.status === 'Timeout') {
        return {
          success: false,
          error: statusJson.error || `Topaz job ended with status: ${statusJson.status}`,
        };
      }
    }

    return {
      success: false,
      error: `Topaz processing timed out after ${maxWaitMs / 1000}s`,
    };
  }

  /**
   * Submit an image for AI Enhancement (handles both synchronous binary and asynchronous polling)
   */
  async enhanceImage(
    endpoint: string,
    imageBuffer: Buffer,
    mimeType: string,
    options: TopazEnhanceOptions = {}
  ): Promise<{ success: boolean; dataUrl?: string; processId?: string; error?: string }> {
    try {
      const url = `${this.baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

      const formData = new FormData();
      const ext = mimeType.includes('png') ? 'png' : 'jpg';
      const blob = new Blob([new Uint8Array(imageBuffer)], { type: mimeType });
      formData.append('image', blob, `upload.${ext}`);

      // Pass all model and control parameters
      if (options.model) formData.append('model', options.model);
      if (options.output_format) formData.append('output_format', options.output_format);
      if (options.crop_to_fill !== undefined) formData.append('crop_to_fill', String(options.crop_to_fill));
      if (options.output_width) formData.append('output_width', String(options.output_width));
      if (options.output_height) formData.append('output_height', String(options.output_height));
      if (options.face_enhancement !== undefined) formData.append('face_enhancement', String(options.face_enhancement));
      if (options.face_enhancement_strength !== undefined) {
        formData.append('face_enhancement_strength', String(options.face_enhancement_strength));
      }
      if (options.face_enhancement_creativity !== undefined) {
        formData.append('face_enhancement_creativity', String(options.face_enhancement_creativity));
      }
      if (options.prompt) formData.append('prompt', options.prompt);

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-API-Key': this.apiKey,
        },
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        return {
          success: false,
          error: `Topaz API error (${response.status}): ${errorText.slice(0, 300)}`,
        };
      }

      const contentType = response.headers.get('content-type') || '';
      if (contentType.includes('application/json')) {
        const json = await response.json();
        const processId = json.process_id || json.request_id || json.id;

        // If direct output_url is provided, return it immediately
        if (json.output_url || json.url) {
          return {
            success: true,
            processId,
            dataUrl: json.output_url || json.url,
          };
        }

        // If job was accepted asynchronously, poll until ready
        if (processId) {
          const pollResult = await this.pollAndDownload(processId);
          return {
            ...pollResult,
            processId,
          };
        }

        return {
          success: false,
          error: 'Topaz API did not return process_id or output URL',
        };
      } else {
        // Direct synchronous image binary returned
        const arrayBuffer = await response.arrayBuffer();
        const base64 = Buffer.from(arrayBuffer).toString('base64');
        return {
          success: true,
          dataUrl: `data:${contentType};base64,${base64}`,
        };
      }
    } catch (err: any) {
      return {
        success: false,
        error: err.message || 'Internal error dispatching to Topaz API',
      };
    }
  }
}

export const topazClient = new TopazClient();
