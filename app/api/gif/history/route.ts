import { NextRequest, NextResponse } from 'next/server';
import { getGifHistory } from '@/lib/gifJobManager';

export const dynamic = 'force-dynamic';

export async function GET() {
  try {
    const history = getGifHistory();
    return NextResponse.json({
      success: true,
      history,
    });
  } catch (err: any) {
    console.error('Error in /api/gif/history:', err);
    return NextResponse.json(
      { error: 'Failed to fetch GIF history' },
      { status: 500 }
    );
  }
}
