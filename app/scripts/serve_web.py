"""Local Flutter preview without stale HTTP or Flutter service-worker caches."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import hashlib
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1] / 'build/web'

def build_prefix():
    # Include artwork changes even when the compiled application is unchanged.
    digest = hashlib.sha256()
    for path in sorted(ROOT.rglob('*')):
        if path.is_file():
            stat = path.stat()
            digest.update(f'{path.relative_to(ROOT)}:{stat.st_size}:{stat.st_mtime_ns}'.encode())
    return f'/_preview/{digest.hexdigest()[:12]}/'
RETIRE_WORKER = b"""
self.addEventListener('install', event => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
  for (const key of await caches.keys()) {
    if (key.startsWith('flutter-')) await caches.delete(key);
  }
  await self.registration.unregister();
  const windows = await self.clients.matchAll({type: 'window'});
  for (const client of windows) await client.navigate(client.url);
})()));
"""

class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_GET(self):
        request_path = urlsplit(self.path).path
        if request_path == '/design-system.html':
            body = (ROOT.parents[1] / 'design/design-system.html').read_bytes()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if request_path.endswith('/flutter_service_worker.js'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/javascript')
            self.send_header('Content-Length', str(len(RETIRE_WORKER)))
            self.end_headers()
            self.wfile.write(RETIRE_WORKER)
            return
        if request_path in ('/', '/index.html', '/fresh') or request_path.startswith('/_preview/'):
            prefix = build_prefix()
            if request_path.startswith('/_preview/'):
                parts = request_path.split('/', 3)
                relative = parts[3] if len(parts) == 4 else ''
                if relative and relative != 'index.html':
                    self.path = '/' + relative
                    super().do_GET()
                    return
            document = (ROOT / 'index.html').read_text(encoding='utf-8')
            document = document.replace('<base href="/">', f'<base href="{prefix}">')
            body = document.encode('utf-8')
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.send_header('X-Preview-Version', prefix.split('/')[2])
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()

if __name__ == '__main__':
    print(f'Preview: http://127.0.0.1:8080 (no cache), root={ROOT}', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8080), PreviewHandler).serve_forever()
