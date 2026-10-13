#!/usr/bin/env python3
"""Check the actual Ruby API over loopback HTTP, including file persistence."""
from pathlib import Path
import json
import os
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]

def main():
    with tempfile.TemporaryDirectory() as temporary:
        data_path = Path(temporary) / 'gems.json'
        with socket.socket() as listener:
            listener.bind(('127.0.0.1', 0))
            port = listener.getsockname()[1]
        env = {**os.environ, 'PORT': str(port), 'API_TOKEN': 'fixture-token', 'GEMHUB_DATA_PATH': str(data_path)}
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
        def request(path, payload=None, authorized=True):
            headers = {'Content-Type': 'application/json'}
            if authorized:
                headers['Authorization'] = 'Bearer fixture-token'
            req = urllib.request.Request(f'http://127.0.0.1:{port}{path}', data=json.dumps(payload).encode() if payload is not None else None, headers=headers)
            try:
                with opener.open(req, timeout=5) as response:
                    return response.status, json.loads(response.read())
            except urllib.error.HTTPError as error:
                return error.code, json.loads(error.read())
        for iteration in range(2):
            with open(Path(temporary) / 'server.log', 'a+') as log:
                process = subprocess.Popen([env.get('RUBY_BIN', 'ruby'), 'services/api/simple_server.rb'], cwd=ROOT, env=env, stdout=log, stderr=log)
                try:
                    for attempt in range(150):
                        if process.poll() is not None:
                            log.seek(0)
                            raise RuntimeError(log.read())
                        try:
                            if request('/health')[0] == 200:
                                break
                        except (OSError, urllib.error.URLError):
                            time.sleep(.1)
                    else:
                        raise RuntimeError('Ruby HTTP startup timeout')
                    assert request('/gems', authorized=False)[0] == 401
                    if iteration == 0:
                        gem = {'name': 'fixture-http-gem', 'version': '1.0.0', 'description': 'Temporary real API test'}
                        assert request('/gems', gem)[0] == 201
                        assert request('/gems', gem)[0] == 409
                        assert request('/gems', {'name': ''})[0] == 400
                        assert request('/gems', [1, 2])[0] == 400
                        assert request('/scan', {'gem_name': gem['name']})[0] == 501
                    records = request('/gems')[1]['gems']
                    stored = next(gem for gem in records if gem['name'] == 'fixture-http-gem')
                    assert request('/gems/' + str(stored['id']))[1]['gem']['version'] == '1.0.0'
                    assert request('/gems/999999')[0] == 404
                finally:
                    process.terminate()
                    process.wait(timeout=10)
        assert any(gem['name'] == 'fixture-http-gem' for gem in json.loads(data_path.read_text()))
        print('PASS: Ruby HTTP create/read, authorization, validation, duplicates, unavailable scanner, restart persistence')

if __name__ == '__main__':
    main()
