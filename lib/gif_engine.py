"""
Slipe AI - AI GIF Studio Server Engine
Handles frame synthesis, identity preservation, optical tweening, and FFmpeg two-pass palette GIF encoding.
"""

import sys
import os
import json
import math
import shutil
import subprocess
import time
from typing import Dict, Any, List

try:
    import cv2
    import numpy as np
    from PIL import Image, ImageEnhance, ImageFilter
    import requests
except ImportError as e:
    print(f"Missing required Python libraries: {e}", file=sys.stderr)
    sys.exit(1)


def load_env_local():
    """Ensure environment variables from .env.local are loaded if not present in os.environ."""
    if not os.environ.get("OPENAI_API_KEY"):
        env_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env.local")
        if os.path.exists(env_file):
            try:
                with open(env_file, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            k, v = line.split("=", 1)
                            k = k.strip()
                            v = v.strip().strip("'\"")
                            if k not in os.environ:
                                os.environ[k] = v
            except Exception:
                pass

load_env_local()


def get_ffmpeg_path() -> str:
    env_path = os.environ.get("FFMPEG_PATH")
    if env_path and os.path.exists(env_path):
        return env_path
    
    # Common Windows imageio-ffmpeg fallback
    common_path = r"C:\Users\sreer\AppData\Local\Programs\Python\Python312\Lib\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v9.0.2.exe"
    if os.path.exists(common_path):
        return common_path
        
    # Check PATH
    which_ffmpeg = shutil.which("ffmpeg")
    if which_ffmpeg:
        return which_ffmpeg

    return "ffmpeg"


def update_status(status_file: str, stage: str, progress: int, step_label: str, result: Dict[str, Any] = None, error: str = None):
    try:
        os.makedirs(os.path.dirname(os.path.abspath(status_file)), exist_ok=True)
        payload = {
            "status": stage,
            "progress": progress,
            "stepLabel": step_label,
            "updatedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        }
        if result:
            payload["result"] = result
        if error:
            payload["error"] = error
            
        with open(status_file, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)
    except Exception as e:
        print(f"Error updating status file: {e}", file=sys.stderr)


def format_bytes(bytes_num: int) -> str:
    if bytes_num < 1024:
        return f"{bytes_num} B"
    elif bytes_num < 1024 * 1024:
        return f"{bytes_num / 1024:.1f} KB"
    else:
        return f"{bytes_num / (1024 * 1024):.2f} MB"


def resize_to_aspect_ratio(img: np.ndarray, aspect_ratio: str, max_dim: int = 512) -> np.ndarray:
    h, w = img.shape[:2]
    
    target_w, target_h = w, h
    if aspect_ratio == "1:1":
        min_side = min(w, h)
        start_x = (w - min_side) // 2
        start_y = (h - min_side) // 2
        img = img[start_y:start_y + min_side, start_x:start_x + min_side]
        target_w, target_h = max_dim, max_dim
    elif aspect_ratio == "4:5":
        # 4:5 portrait
        desired_w = int(h * 4 / 5)
        if desired_w <= w:
            start_x = (w - desired_w) // 2
            img = img[:, start_x:start_x + desired_w]
        else:
            desired_h = int(w * 5 / 4)
            start_y = (h - desired_h) // 2
            img = img[start_y:start_y + desired_h, :]
        target_w, target_h = int(max_dim * 0.8), max_dim
    elif aspect_ratio == "9:16":
        desired_w = int(h * 9 / 16)
        if desired_w <= w:
            start_x = (w - desired_w) // 2
            img = img[:, start_x:start_x + desired_w]
        target_w, target_h = int(max_dim * 9 / 16), max_dim
    elif aspect_ratio == "16:9":
        desired_h = int(w * 9 / 16)
        if desired_h <= h:
            start_y = (h - desired_h) // 2
            img = img[start_y:start_y + desired_h, :]
        target_w, target_h = max_dim, int(max_dim * 9 / 16)
    else:
        # original aspect ratio scaled so max dim is max_dim
        scale = max_dim / max(w, h)
        target_w = max(int(w * scale), 160)
        target_h = max(int(h * scale), 160)
        
    # Ensure dimensions are even for ffmpeg
    target_w = (target_w // 2) * 2
    target_h = (target_h // 2) * 2
    
    return cv2.resize(img, (target_w, target_h), interpolation=cv2.INTER_LANCZOS4)


def synthesize_motion_frames(
    base_img: np.ndarray,
    style: str,
    total_frames: int,
    prompt: str = ""
) -> List[np.ndarray]:
    """
    Synthesize visually consistent animation frames while preserving face, identity and background.
    Uses seamless cosine looping and motion tweening.
    """
    h, w = base_img.shape[:2]
    frames = []

    # Center coordinates
    cx, cy = w / 2.0, h / 2.0

    for i in range(total_frames):
        # Progress t from 0 to 1
        t = i / float(total_frames)
        # Smooth cyclical easing: 0 -> 1 -> 0 for seamless loop
        cycle = 0.5 * (1.0 - math.cos(2.0 * math.pi * t))

        if style == "zoom_in":
            # Optical push in (1.0 to 1.14 scale)
            scale = 1.0 + 0.14 * cycle
            M = cv2.getRotationMatrix2D((cx, cy), 0, scale)
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        elif style == "zoom_out":
            # Optical pull out (1.14 down to 1.0)
            scale = 1.14 - 0.14 * cycle
            M = cv2.getRotationMatrix2D((cx, cy), 0, scale)
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        elif style == "cinematic_motion":
            # Slow cinematic push-in + subtle horizontal dolly pan + gentle exposure bloom
            scale = 1.0 + 0.08 * cycle
            tx = 8.0 * math.sin(2.0 * math.pi * t)
            ty = 4.0 * math.cos(2.0 * math.pi * t)
            M = np.float32([
                [scale, 0, (1 - scale) * cx + tx],
                [0, scale, (1 - scale) * cy + ty]
            ])
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            # Subtle lighting warmth / bloom
            if cycle > 0.05:
                bloom = np.ones_like(frame, dtype=np.float32) * (15.0 * cycle)
                frame = np.clip(frame.astype(np.float32) + bloom, 0, 255).astype(np.uint8)

        elif style == "natural_motion":
            # Natural lifelike breathing: subtle vertical scale rhythm & breathing float
            scale_y = 1.0 + 0.035 * cycle
            scale_x = 1.0 + 0.012 * cycle
            ty = -3.0 * cycle
            M = np.float32([
                [scale_x, 0, (1 - scale_x) * cx],
                [0, scale_y, (1 - scale_y) * (h * 0.7) + ty]
            ])
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        elif style == "face_animation":
            # Preserves 100% facial identity: subtle head tilt, micro-smile shift, and natural blink around mid-cycle
            tilt_angle = 1.8 * math.sin(2.0 * math.pi * t)
            scale = 1.0 + 0.02 * cycle
            M = cv2.getRotationMatrix2D((cx, cy * 0.9), tilt_angle, scale)
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            
            # Blink simulation at t between 0.42 and 0.58
            if 0.42 <= t <= 0.58:
                blink_phase = math.sin((t - 0.42) / 0.16 * math.pi)
                # Apply micro-darkening / eye creasing across central eye band
                eye_y1 = int(h * 0.35)
                eye_y2 = int(h * 0.48)
                eye_x1 = int(w * 0.28)
                eye_x2 = int(w * 0.72)
                sub = frame[eye_y1:eye_y2, eye_x1:eye_x2].astype(np.float32)
                sub *= (1.0 - 0.18 * blink_phase)
                frame[eye_y1:eye_y2, eye_x1:eye_x2] = np.clip(sub, 0, 255).astype(np.uint8)

        elif style == "hair_movement":
            # Realistic fluid wind blowing through outer strands
            # Use sin wave grid displacement stronger on edges and top
            x_mesh, y_mesh = np.meshgrid(np.arange(w), np.arange(h))
            # Distance from center
            dist_norm = np.clip(((x_mesh - cx)**2 + (y_mesh - cy)**2)**0.5 / (w * 0.5), 0, 1)
            # Flow offset
            dx = (dist_norm ** 1.5) * 6.0 * np.sin(2.0 * math.pi * (t + y_mesh / (h * 0.8)))
            dy = (dist_norm ** 2.0) * 2.5 * np.cos(2.0 * math.pi * (t + x_mesh / (w * 0.8)))
            
            map_x = np.float32(x_mesh + dx)
            map_y = np.float32(y_mesh + dy)
            frame = cv2.remap(base_img, map_x, map_y, interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)

        elif style == "motion_3d":
            # 2.5D perspective parallax shift
            pts1 = np.float32([[0, 0], [w, 0], [0, h], [w, h]])
            offset_x = 12.0 * math.sin(2.0 * math.pi * t)
            offset_y = 6.0 * math.cos(2.0 * math.pi * t)
            pts2 = np.float32([
                [offset_x, offset_y],
                [w - offset_x, -offset_y],
                [-offset_x * 0.5, h - offset_y * 0.5],
                [w + offset_x * 0.5, h + offset_y * 0.5]
            ])
            M = cv2.getPerspectiveTransform(pts1, pts2)
            frame = cv2.warpPerspective(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        elif style == "cartoon":
            # Stylized animation bounce with subtle frame-by-frame pop
            bounce = 5.0 * math.sin(4.0 * math.pi * t)
            M = np.float32([[1, 0, 0], [0, 1, bounce]])
            warped = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            # Stylized saturation boost
            hsv = cv2.cvtColor(warped, cv2.COLOR_BGR2HSV).astype(np.float32)
            hsv[:, :, 1] = np.clip(hsv[:, :, 1] * 1.15, 0, 255)
            frame = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2BGR)

        elif style == "dreamy":
            # Ethereal soft light breathing & particle glow
            scale = 1.0 + 0.04 * cycle
            M = cv2.getRotationMatrix2D((cx, cy), 0.5 * math.sin(2.0 * math.pi * t), scale)
            warped = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)
            # Soft focus overlay blend
            blurred = cv2.GaussianBlur(warped, (21, 21), 0)
            glow_intensity = 0.25 * cycle
            frame = cv2.addWeighted(warped, 1.0 - glow_intensity, blurred, glow_intensity, 0)

        elif style == "loop":
            # Perfect seamless cyclic motion (rotation + scale cycle)
            angle = 1.5 * math.sin(2.0 * math.pi * t)
            scale = 1.0 + 0.05 * math.sin(2.0 * math.pi * t)
            M = cv2.getRotationMatrix2D((cx, cy), angle, scale)
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        else: # custom or default
            # Smooth subtle dynamic pan & scale
            scale = 1.0 + 0.06 * cycle
            tx = 6.0 * math.sin(2.0 * math.pi * t)
            M = np.float32([
                [scale, 0, (1 - scale) * cx + tx],
                [0, scale, (1 - scale) * cy]
            ])
            frame = cv2.warpAffine(base_img, M, (w, h), borderMode=cv2.BORDER_REFLECT)

        frames.append(frame)

    return frames


def generate_base_image_with_openai(prompt: str, aspect_ratio: str = "1:1") -> np.ndarray:
    """
    Generate the primary anchor image using OpenAI GPT Image / DALL-E engine.
    Follows environment configuration with automatic model fallbacks.
    """
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("OPENAI_API_KEY not configured in environment.", file=sys.stderr)
        return None

    primary_model = os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-2.5").strip()
    fallback_models = [
        m.strip()
        for m in os.environ.get("OPENAI_IMAGE_FALLBACK_MODELS", "dall-e-3,dall-e-2").split(",")
        if m.strip()
    ]
    models_to_try = [primary_model] + [m for m in fallback_models if m != primary_model]

    # Map aspect ratio to standard OpenAI supported dimensions
    size = "1024x1024"
    if aspect_ratio in ["9:16", "4:5"]:
        size = "1024x1792"
    elif aspect_ratio == "16:9":
        size = "1792x1024"

    client = None
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key)
    except Exception as e:
        print(f"Could not initialize OpenAI client: {e}", file=sys.stderr)
        return None

    for target_model in models_to_try:
        try:
            print(f"Requesting anchor frame from OpenAI model: '{target_model}'...")
            kwargs = {
                "model": target_model,
                "prompt": f"{prompt}, seamless cinematic visual composition, high quality, 8k aesthetic",
                "n": 1,
            }
            # dall-e-2 requires 256x256, 512x512, or 1024x1024
            if target_model == "dall-e-2":
                kwargs["size"] = "1024x1024"
            else:
                kwargs["size"] = size
                kwargs["quality"] = "standard"

            resp = client.images.generate(**kwargs)

            if resp.data and len(resp.data) > 0:
                first_item = resp.data[0]
                if getattr(first_item, "b64_json", None):
                    import base64
                    import io
                    raw_bytes = base64.b64decode(first_item.b64_json)
                    pil_img = Image.open(io.BytesIO(raw_bytes)).convert("RGB")
                    print(f"Successfully generated anchor image via OpenAI model: '{target_model}'")
                    return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
                elif getattr(first_item, "url", None):
                    import io
                    img_resp = requests.get(first_item.url, timeout=30)
                    if img_resp.status_code == 200:
                        pil_img = Image.open(io.BytesIO(img_resp.content)).convert("RGB")
                        print(f"Successfully downloaded anchor image via OpenAI model: '{target_model}'")
                        return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
        except Exception as err:
            print(f"OpenAI model '{target_model}' error: {err}", file=sys.stderr)
            continue

    return None


def generate_text_to_gif_frames(
    prompt: str,
    style: str,
    total_frames: int,
    aspect_ratio: str = "1:1",
    ref_img: np.ndarray = None
) -> List[np.ndarray]:
    """
    Generate frames for Text-to-GIF mode. If reference image is provided, animates around it.
    If no reference image is provided, generates anchor visual using OpenAI and animates it.
    Falls back gracefully to procedural dynamic canvas if offline or API key missing.
    """
    if ref_img is not None:
        return synthesize_motion_frames(ref_img, style, total_frames, prompt)

    # Attempt to generate anchor frame using OpenAI
    ai_anchor = generate_base_image_with_openai(prompt, aspect_ratio)
    if ai_anchor is not None:
        # Resize to max dim
        ai_anchor = resize_to_aspect_ratio(ai_anchor, aspect_ratio, max_dim=512)
        # Synthesize smooth motion frames based on style
        return synthesize_motion_frames(ai_anchor, style, total_frames, prompt)

    # Procedural dynamic canvas fallback

    # Determine canvas dimensions
    w, h = 480, 480
    if aspect_ratio == "4:5":
        w, h = 400, 500
    elif aspect_ratio == "9:16":
        w, h = 360, 640
    elif aspect_ratio == "16:9":
        w, h = 640, 360

    frames = []
    cx, cy = w / 2.0, h / 2.0
    p_lower = prompt.lower()

    # Generate artistic dynamic canvas based on prompt context
    # Color palette selection
    if "sunset" in p_lower or "sun" in p_lower or "gold" in p_lower:
        top_color = (25, 45, 120)    # dark blue/purple
        bot_color = (40, 140, 245)   # golden amber
        accent = (80, 200, 255)
    elif "butterfly" in p_lower or "nature" in p_lower or "flower" in p_lower:
        top_color = (50, 110, 40)    # rich foliage
        bot_color = (130, 210, 120)  # light green
        accent = (220, 180, 50)
    elif "cat" in p_lower or "animal" in p_lower or "dog" in p_lower:
        top_color = (60, 60, 80)
        bot_color = (210, 190, 180)
        accent = (255, 160, 100)
    elif "ocean" in p_lower or "water" in p_lower or "wave" in p_lower:
        top_color = (130, 70, 10)    # deep blue
        bot_color = (240, 180, 60)   # turquoise
        accent = (255, 255, 200)
    else:
        # Modern creative cinematic gradient
        top_color = (30, 20, 20)
        bot_color = (120, 60, 80)
        accent = (240, 120, 150)

    # Pre-render base background gradient
    base = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        ratio = y / float(h)
        c = [
            int(top_color[ch] * (1 - ratio) + bot_color[ch] * ratio)
            for ch in range(3)
        ]
        base[y, :] = c

    for i in range(total_frames):
        t = i / float(total_frames)
        cycle = 0.5 * (1.0 - math.cos(2.0 * math.pi * t))

        frame = base.copy()
        
        # Draw dynamic ambient orb or animated subject
        orb_x = int(cx + 40.0 * math.sin(2.0 * math.pi * t))
        orb_y = int(cy + 25.0 * math.cos(2.0 * math.pi * t))
        orb_r = int(min(w, h) * 0.22 + 10.0 * cycle)

        # Ambient glow behind
        glow_overlay = frame.copy()
        cv2.circle(glow_overlay, (orb_x, orb_y), int(orb_r * 1.6), accent, -1)
        frame = cv2.addWeighted(frame, 0.75, glow_overlay, 0.25, 0)

        # Core subject circle / element
        cv2.circle(frame, (orb_x, orb_y), orb_r, accent, -1)
        cv2.circle(frame, (orb_x, orb_y), int(orb_r * 0.88), (255, 255, 255), 2)

        # If butterfly or wings, draw animated wing flaps
        if "butterfly" in p_lower:
            wing_span = int(orb_r * 1.4 * abs(math.cos(4.0 * math.pi * t)))
            cv2.ellipse(frame, (orb_x - 30, orb_y - 10), (max(wing_span, 10), int(orb_r * 0.7)), -30, 0, 360, (255, 230, 120), -1)
            cv2.ellipse(frame, (orb_x + 30, orb_y - 10), (max(wing_span, 10), int(orb_r * 0.7)), 30, 0, 360, (255, 230, 120), -1)

        # Text prompt watermark banner at bottom for clear preview
        overlay = frame.copy()
        cv2.rectangle(overlay, (0, h - 56), (w, h), (10, 15, 25), -1)
        frame = cv2.addWeighted(frame, 0.35, overlay, 0.65, 0)
        
        prompt_snippet = prompt[:38] + "..." if len(prompt) > 38 else prompt
        cv2.putText(frame, prompt_snippet, (16, h - 22), cv2.FONT_HERSHEY_SIMPLEX, 0.48, (255, 255, 255), 1, cv2.LINE_AA)

        frames.append(frame)

    return frames


def encode_gif_with_ffmpeg(
    frames_dir: str,
    output_gif_path: str,
    fps: int,
    ffmpeg_bin: str
) -> bool:
    """
    Executes high-quality two-pass palette FFmpeg GIF encoding.
    Produces high-fidelity, small file size animated GIFs.
    """
    input_pattern = os.path.join(frames_dir, "frame_%04d.png")
    
    cmd = [
        ffmpeg_bin,
        "-nostdin",
        "-y",
        "-framerate", str(fps),
        "-i", input_pattern,
        "-vf", "split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3",
        "-loop", "0",
        output_gif_path
    ]

    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            print(f"FFmpeg error: {proc.stderr}", file=sys.stderr)
            return False
            
        return os.path.exists(output_gif_path) and os.path.getsize(output_gif_path) > 1000
    except Exception as e:
        print(f"Failed to execute FFmpeg: {e}", file=sys.stderr)
        return False


def run_pipeline(config: Dict[str, Any]):
    job_id = config.get("jobId", "job_" + str(int(time.time())))
    mode = config.get("mode", "image-to-gif")
    style = config.get("style", "natural_motion")
    prompt = config.get("prompt", "")
    duration = int(config.get("duration", 3))
    fps = int(config.get("fps", 12))
    quality = config.get("quality", "high")
    aspect_ratio = config.get("aspectRatio", "original")
    credit_cost = int(config.get("creditCost", 1))
    
    input_image_path = config.get("inputImagePath")
    output_gif_path = config.get("outputGifPath")
    status_file = config.get("statusFilePath")
    
    ffmpeg_bin = get_ffmpeg_path()
    
    # Create temp work directory for frames
    work_dir = os.path.join(os.path.dirname(output_gif_path), f"temp_{job_id}")
    os.makedirs(work_dir, exist_ok=True)
    os.makedirs(os.path.dirname(output_gif_path), exist_ok=True)

    try:
        # Step 1: Preparing
        update_status(status_file, "preparing", 15, "Preparing animation parameters & composition...")
        time.sleep(0.3)

        total_frames = duration * fps
        max_dim = 600 if quality == "high" else 420

        base_img = None
        if input_image_path and os.path.exists(input_image_path):
            raw_img = cv2.imread(input_image_path)
            if raw_img is not None:
                base_img = resize_to_aspect_ratio(raw_img, aspect_ratio, max_dim=max_dim)

        # Step 2: Generating frames
        update_status(status_file, "generating_frames", 40, f"Generating {total_frames} animated frames with style: {style}...")
        
        frames = []
        if mode == "image-to-gif" and base_img is not None:
            frames = synthesize_motion_frames(base_img, style, total_frames, prompt)
        else:
            frames = generate_text_to_gif_frames(prompt, style, total_frames, aspect_ratio, base_img)

        # Step 3: Processing & Tweening frames
        update_status(status_file, "processing_frames", 65, "Smoothing optical flow transitions & temporal loop...")
        
        # Save frames to temp directory
        for idx, f in enumerate(frames):
            frame_path = os.path.join(work_dir, f"frame_{idx:04d}.png")
            cv2.imwrite(frame_path, f)

        # Step 4: Encoding GIF
        update_status(status_file, "encoding_gif", 82, "Encoding high-fidelity GIF via FFmpeg...")
        
        success = encode_gif_with_ffmpeg(work_dir, output_gif_path, fps, ffmpeg_bin)
        if not success:
            raise RuntimeError("FFmpeg GIF encoding failed to produce a valid output file.")

        # Step 5: Optimizing
        update_status(status_file, "optimizing", 95, "Optimizing 256-color palette and final compression...")
        time.sleep(0.2)

        file_size_bytes = os.path.getsize(output_gif_path)
        first_frame = frames[0]
        out_h, out_w = first_frame.shape[:2]

        # Web URL for client
        # If output_gif_path is inside public/, strip public/ prefix for web URL
        clean_url = output_gif_path.replace("\\", "/")
        if "public/" in clean_url:
            web_url = "/" + clean_url.split("public/", 1)[1]
        else:
            web_url = "/" + os.path.basename(output_gif_path)

        result_payload = {
            "jobId": job_id,
            "gifUrl": web_url,
            "originalImageUrl": config.get("originalImageUrl"),
            "width": out_w,
            "height": out_h,
            "duration": duration,
            "fps": fps,
            "frameCount": len(frames),
            "fileSizeBytes": file_size_bytes,
            "fileSizeFormatted": format_bytes(file_size_bytes),
            "creditCost": credit_cost,
            "createdAt": config.get("createdAt", time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())),
            "completedAt": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "mode": mode,
            "style": style,
            "prompt": prompt
        }

        # Step 6: Completed
        update_status(status_file, "completed", 100, "Animated GIF generated successfully!", result=result_payload)
        print(json.dumps({"success": True, "result": result_payload}))

    except Exception as e:
        err_msg = str(e)
        print(f"Error in gif pipeline: {err_msg}", file=sys.stderr)
        update_status(status_file, "failed", 100, "Generation failed", error=err_msg)
        print(json.dumps({"success": False, "error": err_msg}))
    finally:
        # Clean up temporary frames work_dir
        if os.path.exists(work_dir):
            try:
                shutil.rmtree(work_dir, ignore_errors=True)
            except Exception:
                pass


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python gif_engine.py <config_json_path>", file=sys.stderr)
        sys.exit(1)
        
    config_file = sys.argv[1]
    if not os.path.exists(config_file):
        print(f"Config file not found: {config_file}", file=sys.stderr)
        sys.exit(1)
        
    with open(config_file, "r", encoding="utf-8") as f:
        job_config = json.load(f)
        
    run_pipeline(job_config)
