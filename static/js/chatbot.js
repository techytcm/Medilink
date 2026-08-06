/* MediBot chat client */
(function () {
  const form   = document.getElementById('chat-form');
  const input  = document.getElementById('chat-input');
  const box    = document.getElementById('chat-box');
  if (!form) return;

  function append(text, sender) {
    const wrap = document.createElement('div');
    wrap.className = 'flex ' + (sender === 'user' ? 'justify-end' : 'justify-start');
    const bubble = document.createElement('div');
    bubble.className = 'max-w-[75%] px-4 py-2.5 rounded-2xl text-sm ' +
      (sender === 'user'
        ? 'bg-brand-600 text-white rounded-br-md'
        : 'bg-brand-50 dark:bg-ink-800 text-slate-800 dark:text-slate-100 rounded-bl-md');
    bubble.textContent = text;
    wrap.appendChild(bubble);
    box.appendChild(wrap);
    box.scrollTop = box.scrollHeight;
  }

  form.addEventListener('submit', async e => {
    e.preventDefault();
    const msg = input.value.trim();
    if (!msg) return;
    append(msg, 'user');
    input.value = '';
    input.disabled = true;

    // Typing indicator
    const typing = document.createElement('div');
    typing.className = 'flex justify-start';
    typing.innerHTML = '<div class="px-4 py-3 rounded-2xl rounded-bl-md bg-brand-50 dark:bg-ink-800 text-sm">● ● ●</div>';
    box.appendChild(typing);
    box.scrollTop = box.scrollHeight;

    try {
      const fd = new FormData();
      fd.append('message', msg);
      const res = await fetch('/patient/chatbot/send', { method: 'POST', body: fd });
      const data = await res.json();
      typing.remove();
      append(data.bot || 'Sorry, I could not process that.', 'bot');
    } catch (err) {
      typing.remove();
      append('Network error. Please try again.', 'bot');
    } finally {
      input.disabled = false;
      input.focus();
    }
  });
})();