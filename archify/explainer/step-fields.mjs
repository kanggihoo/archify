/** Splits a step detail that opens with `**Label**` into labelled fields, so the page can show
 * input, reads, output and next as rows instead of one paragraph. Returns null for ordinary details.
 * A label is a short bold word outside inline code; text up to the next label belongs to the field.
 */
const LABEL_MAX = 8;

export function splitStepFields(detail) {
  const text = String(detail ?? '');
  if (!/^\s*\*\*[^*\n`\s]{1,8}\*\*(?:\s|$)/u.test(text)) return null;
  const starts = [];
  let code = false;
  for (let i = 0; i < text.length;) {
    if (text[i] === '`') { code = !code; i++; continue; }
    if (!code && text.startsWith('**', i)) {
      const close = text.indexOf('**', i + 2);
      const label = close > i + 2 ? text.slice(i + 2, close) : '';
      if (label && label.length <= LABEL_MAX && !/[\s`*\n]/u.test(label) && /^\s|$/u.test(text.slice(close + 2, close + 3))) {
        starts.push({ label, from: i, body: close + 2 });
        i = close + 2;
        continue;
      }
      i += 2;
      continue;
    }
    i++;
  }
  if (starts.length < 2) return null;
  return starts.map((start, index) => ({
    label: start.label,
    text: text.slice(start.body, starts[index + 1]?.from ?? text.length).trim().replace(/[\s·]+$/u, '')
  }));
}
