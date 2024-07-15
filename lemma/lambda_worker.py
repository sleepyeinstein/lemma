import time
import select
from lemma.settings import get_settings
import requests
import urllib.parse
import random

class LambdaService:
    def __init__(self, worker):
        self.worker = worker

    def invoke(self, command, stdin):
        # URL encode the command
        command = urllib.parse.quote(command)
        body_data = stdin

        url = get_settings().lambda_url + '/runtool?cmd=' + command
        if get_settings().args.verbose:
            url += '&verbose=true'
        if get_settings().args.no_stderr:
            url += '&no_stderr=true'
        
        # Set the LEMMA_API_KEY cookie
        cookies = {'LEMMA_API_KEY': get_settings().lambda_key}

        # Check if feeding stdin is enabled and if it is then add the stdin to the request body
        if get_settings().args.omit_stdin:
            body_data = ""

        with requests.Session() as session:
            # Perform a POST request to the Lambda URL with streaming enabled
            with session.post(url, cookies=cookies, data=body_data, stream=True) as response:
                # Ensure the request was successful
                try:
                    response.raise_for_status()
                except:
                    print(response.status_code)
                    return response.status_code

                # Get the X-Lemma-Timeout header
                timeout = response.headers.get('X-Lemma-Timeout')
                if timeout:
                    timeout = float(timeout)
                    start_time = time.time()

                buffer = ""
                sock = response.raw._fp.fp.raw._sock  # Get the raw socket from the response                
                x = response.raw.stream(4096, decode_content=False)

                # Process the stream in chunks
                while True:
                    rlist, _, _ = select.select([sock], [], [], 0.01)
                    # Break the loop if no more data to read
                    if not rlist:
                        if timeout and (time.time() - start_time) > timeout:
                            # LEMMA timeout exceeded, bail out the thread
                            break
                        continue
                    
                    try:
                        chunk = next(x)
                    except StopIteration:
                        break

                    decoded_chunk = chunk.decode('utf-8')
                    if get_settings().args.line_buffered:
                        buffer += decoded_chunk
                        while '\n' in buffer:
                            line, buffer = buffer.split('\n', 1)
                            self.worker.push(line + '\n')
                    else:
                        self.worker.push(decoded_chunk)


                if buffer:
                    self.worker.push(buffer)

                return response.status_code

class LambdaWorker:
    stop = False

    def __init__(self, command_queue, stdout_queue):
        self.command_queue = command_queue
        self.stdout_queue = stdout_queue
        self.idle = True

    def push(self, stdoutitem):
        self.stdout_queue.put(stdoutitem)

    def run(self):
        while True:
            if LambdaWorker.stop:
                break

            try:
                command, stdin = self.command_queue.get_nowait()
            except:
                continue

            self.idle = False
            LambdaService(self).invoke(command, stdin)
            self.command_queue.task_done()
            self.idle = True

    @classmethod
    def stop_all_workers(cls):
        LambdaWorker.stop = True
