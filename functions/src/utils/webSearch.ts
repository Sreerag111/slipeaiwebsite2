import {debugLog} from "./debugLog";

export interface WebSearchResult {
  title: string;
  url: string;
  snippet: string;
}

/**
 * Perform a live DuckDuckGo web search to retrieve real-time sources & information.
 */
export async function performWebSearch(query: string, maxResults = 5): Promise<WebSearchResult[]> {
  try {
    const cleanQuery = query.replace(/[^\w\s\d.-]/gi, ' ').trim();
    if (!cleanQuery) return [];

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 2500);

    const url = 'https://html.duckduckgo.com/html/?q=' + encodeURIComponent(cleanQuery);
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    });
    clearTimeout(timeoutId);

    if (!res.ok) return [];

    const html = await res.text();
    const results: WebSearchResult[] = [];

    const blockRegex = /<div class="result results_links[^"]*"[^>]*>([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>/g;
    const titleRegex = /<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/;
    const snippetRegex = /<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/;

    let match: RegExpExecArray | null;
    while ((match = blockRegex.exec(html)) !== null && results.length < maxResults) {
      const block = match[1];
      const titleMatch = titleRegex.exec(block);
      const snippetMatch = snippetRegex.exec(block);

      if (titleMatch) {
        const rawHref = titleMatch[1];
        let targetUrl = rawHref;
        if (rawHref.includes('uddg=')) {
          const encoded = rawHref.split('uddg=')[1].split('&')[0];
          try {
            targetUrl = decodeURIComponent(encoded);
          } catch {
            targetUrl = rawHref;
          }
        }

        const title = decodeHtmlEntities(titleMatch[2].replace(/<[^>]+>/g, '').trim());
        const snippet = snippetMatch
          ? decodeHtmlEntities(snippetMatch[1].replace(/<[^>]+>/g, '').trim())
          : '';

        if (targetUrl.startsWith('http')) {
          results.push({
            title,
            url: targetUrl,
            snippet,
          });
        }
      }
    }

    return results;
  } catch (err) {
    debugLog.error('Web search error:', err);
    return [];
  }
}

/**
 * Determine if a user prompt likely requires real-time information or external research.
 */
export function shouldPerformWebSearch(prompt: string): boolean {
  if (!prompt || prompt.length < 5) return false;

  const searchKeywords = [
    'news',
    'latest',
    'recent',
    'today',
    'yesterday',
    'current',
    'this week',
    'this month',
    'this year',
    '2024',
    '2025',
    '2026',
    '2027',
    'who won',
    'weather',
    'stock',
    'price of',
    'release date',
    'update on',
    'sources',
    'source',
    'citation',
    'research',
    'what happened',
    'event',
    'score',
    'match',
    'election',
    'article',
    'trend',
    'breakthrough',
  ];

  const lower = prompt.toLowerCase();
  return searchKeywords.some((keyword) => lower.includes(keyword));
}

function decodeHtmlEntities(str: string): string {
  return str
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#x27;/g, "'")
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ');
}
