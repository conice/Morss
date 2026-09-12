// Capture a running preview through a local Chromium DevTools port. Node 22+.
// Example: node tools/capture_ui.cjs http://127.0.0.1:8787/ out.png 390 844
const fs = require('node:fs');
const path = require('node:path');

async function connectToPage(port = 9222) {
  const endpoint = `http://127.0.0.1:${port}`;
  const target = await fetch(`${endpoint}/json/new?about:blank`, {method: 'PUT'}).then(r => r.json());
  const socket = new WebSocket(target.webSocketDebuggerUrl);
  const pending = new Map();
  const errors = [];
  let sequence = 0;
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (message.method === 'Runtime.exceptionThrown') {
      errors.push(message.params.exceptionDetails.exception?.description || message.params.exceptionDetails.text);
    }
    const request = pending.get(message.id);
    if (!request) return;
    pending.delete(message.id);
    clearTimeout(request.timeout);
    if (message.error) request.reject(new Error(JSON.stringify(message.error)));
    else request.resolve(message.result);
  });
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, {once: true});
    socket.addEventListener('error', reject, {once: true});
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++sequence;
    const timeout = setTimeout(() => {pending.delete(id); reject(new Error(`Timeout: ${method}`));}, 45000);
    pending.set(id, {resolve, reject, timeout});
    socket.send(JSON.stringify({id, method, params}));
  });
  const evaluate = async expression => {
    const result = await send('Runtime.evaluate', {expression, awaitPromise: true, returnByValue: true});
    if (result.exceptionDetails) throw new Error(result.exceptionDetails.exception?.description || 'Browser evaluation failed');
    return result.result.value;
  };
  const waitFor = async expression => {
    const started = Date.now();
    while (!await evaluate(expression)) {
      if (Date.now() - started > 45000) throw new Error(`Page not ready: ${expression}`);
      await new Promise(resolve => setTimeout(resolve, 150));
    }
  };
  const close = async () => {
    socket.close();
    await fetch(`${endpoint}/json/close/${target.id}`);
  };
  return {send, evaluate, waitFor, errors, close};
}

async function capture() {
  const [url, output, width = '1440', height = '960', ...options] = process.argv.slice(2);
  if (!url || !output) throw new Error('Usage: node tools/capture_ui.cjs URL OUTPUT WIDTH HEIGHT [--dark] [--click=x,y] [--settle-ms=10000]');
  const page = await connectToPage();
  try {
    await page.send('Page.enable');
    await page.send('Runtime.enable');
    await page.send('Emulation.setDeviceMetricsOverride', {
      width: Number(width), height: Number(height), deviceScaleFactor: 1, mobile: false,
    });
    await page.send('Emulation.setEmulatedMedia', {features: [
      {name: 'prefers-color-scheme', value: options.includes('--dark') ? 'dark' : 'light'},
    ]});
    const navigation = await page.send('Page.navigate', {url});
    if (navigation.errorText) throw new Error(`Preview unavailable: ${navigation.errorText}`);
    await page.waitFor('Boolean(window.morssReferenceState || window.morssFirstFrame)');
    await page.evaluate('document.fonts.ready.then(() => true)');
    await page.waitFor('Array.from(document.images).every(image => image.complete)');
    // Flutter's first-frame event precedes asynchronous image decoding. The
    // software renderer used for local captures needs time to paint those assets.
    const delayOption = options.find(value => value.startsWith('--settle-ms='));
    const settleMs = delayOption
      ? Number(delayOption.slice('--settle-ms='.length))
      : await page.evaluate('window.morssFirstFrame ? 10000 : 0');
    if (!Number.isFinite(settleMs) || settleMs < 0 || settleMs > 60000) {
      throw new Error('--settle-ms must be between 0 and 60000');
    }
    for (const option of options.filter(value => value.startsWith('--click='))) {
      const [x, y] = option.slice(8).split(',').map(Number);
      for (const type of ['mousePressed', 'mouseReleased']) {
        await page.send('Input.dispatchMouseEvent', {type, x, y, button: 'left', clickCount: 1});
      }
      await new Promise(resolve => setTimeout(resolve, 400));
    }
    await page.evaluate('document.fonts.ready.then(() => true)');
    await page.waitFor('Array.from(document.images).every(image => image.complete)');
    if (settleMs) await new Promise(resolve => setTimeout(resolve, settleMs));
    await page.evaluate('new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))');
    const screenshot = await page.send('Page.captureScreenshot', {format: 'png', captureBeyondViewport: false});
    fs.mkdirSync(path.dirname(output), {recursive: true});
    fs.writeFileSync(output, Buffer.from(screenshot.data, 'base64'));
    if (page.errors.length) throw new Error(page.errors.join('\n'));
    console.log(`${output} · ${width} × ${height} · browser exceptions: 0`);
  } finally {
    await page.close();
  }
}

module.exports = {connectToPage};
if (require.main === module) capture().catch(error => {console.error(error); process.exitCode = 1;});
