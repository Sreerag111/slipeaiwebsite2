/** Debug-only logging without request bodies, prompts, URLs or error messages. */
const enabled = process.env.FUNCTIONS_EMULATOR === "true" ||
  process.env.MEDIA_DEBUG_LOGS === "true";

function safe(value: unknown): string | number | boolean {
  if (typeof value === "number" || typeof value === "boolean") return value;
  if (value instanceof Error) return `[${value.name}]`;
  if (typeof value === "string") return `[redacted text ${value.length} chars]`;
  return `[${typeof value}]`;
}

function write(level: "info" | "warn" | "error", values: unknown[]) {
  if (!enabled) return;
  console[level]("[Debug]", ...values.map(safe));
}

export const debugLog = {
  log: (...values: unknown[]) => write("info", values),
  info: (...values: unknown[]) => write("info", values),
  warn: (...values: unknown[]) => write("warn", values),
  error: (...values: unknown[]) => write("error", values),
};
