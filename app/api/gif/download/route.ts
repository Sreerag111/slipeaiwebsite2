import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const rawParam = searchParams.get('jobId') || searchParams.get('file') || searchParams.get('id');

    if (!rawParam) {
      return NextResponse.json({ error: 'Missing jobId or file parameter' }, { status: 400 });
    }

    // Sanitize jobId to prevent directory traversal
    const cleanId = path.basename(rawParam).replace(/\.gif$/i, '');
    const filePath = path.join(process.cwd(), 'public', 'outputs', 'gifs', `${cleanId}.gif`);

    if (!fs.existsSync(filePath)) {
      return NextResponse.json({ error: 'GIF file not found' }, { status: 404 });
    }

    const fileBuffer = fs.readFileSync(filePath);
    const filename = `slipeai-animated-${cleanId}.gif`;

    return new NextResponse(fileBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'image/gif',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': fileBuffer.length.toString(),
        'Cache-Control': 'public, max-age=31536000, immutable',
      },
    });
  } catch (err: any) {
    console.error('Error in /api/gif/download:', err);
    return NextResponse.json({ error: 'Failed to download GIF' }, { status: 500 });
  }
}
