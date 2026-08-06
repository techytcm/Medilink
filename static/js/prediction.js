/* prediction.js — optional quick-predict via API (for landing page demos) */
async function quickPredict(text) {
  const res = await fetch('/api/predict', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ symptoms: text })
  });
  return await res.json();
}