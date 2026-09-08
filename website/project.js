function setMethod(button, open) {
  document.getElementById(button.getAttribute('aria-controls')).hidden = !open;
  button.setAttribute('aria-expanded', String(open));
}
function revealMethod(id = window.location.hash.slice(1)) {
  const target = document.getElementById(id);
  if (target && target.classList.contains('method-group')) {
    setMethod(target.querySelector('.method-toggle'), true);
  }
}
document.addEventListener('click', event => {
  const button = event.target.closest('.method-toggle');
  if (button) setMethod(button, button.getAttribute('aria-expanded') !== 'true');
  const link = event.target.closest('a[href^="#method-"]');
  if (link) revealMethod(link.getAttribute('href').slice(1));
});
window.addEventListener('hashchange', () => revealMethod());
revealMethod();
document.querySelectorAll('[data-copy]').forEach(button => {
  button.addEventListener('click', async () => {
    const code = document.getElementById(button.dataset.copy);
    const status = button.closest('.code-block').querySelector('[role="status"]');
    try {
      await navigator.clipboard.writeText(code.textContent);
      status.textContent = 'Copied.';
    } catch {
      const selection = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(code);
      selection.removeAllRanges();
      selection.addRange(range);
      status.textContent = 'Code selected. Use your usual copy command.';
    }
  });
});
