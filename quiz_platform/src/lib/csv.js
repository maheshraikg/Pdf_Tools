// CSV helpers. Output is protected against spreadsheet formula injection
// (cells beginning with = + - @ tab or CR are prefixed with a single quote).

export function csvCell(value) {
  if (value === null || value === undefined) return '';
  let s = value instanceof Date ? value.toISOString() : String(value);
  if (typeof value === 'string' && /^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  if (/[",\r\n]/.test(s)) s = `"${s.replace(/"/g, '""')}"`;
  return s;
}

export function toCsv(headers, rows) {
  const lines = [headers.map(csvCell).join(',')];
  for (const r of rows) lines.push(r.map(csvCell).join(','));
  return `﻿${lines.join('\r\n')}\r\n`;
}

/** RFC 4180 parser (quoted fields, escaped quotes, CRLF). Returns array of string arrays. */
export function parseCsv(text) {
  const rows = [];
  let row = [];
  let field = '';
  let i = 0;
  let quoted = false;
  const src = text.replace(/^﻿/, '');
  while (i < src.length) {
    const ch = src[i];
    if (quoted) {
      if (ch === '"') {
        if (src[i + 1] === '"') { field += '"'; i += 2; continue; }
        quoted = false; i++; continue;
      }
      field += ch; i++; continue;
    }
    if (ch === '"') { quoted = true; i++; continue; }
    if (ch === ',') { row.push(field); field = ''; i++; continue; }
    if (ch === '\r' || ch === '\n') {
      row.push(field); field = '';
      if (row.some((c) => c !== '')) rows.push(row);
      row = [];
      i += ch === '\r' && src[i + 1] === '\n' ? 2 : 1;
      continue;
    }
    field += ch; i++;
  }
  row.push(field);
  if (row.some((c) => c !== '')) rows.push(row);
  return rows;
}
