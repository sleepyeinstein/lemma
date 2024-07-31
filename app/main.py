from fastapi import FastAPI, Query, Request
from fastapi.responses import StreamingResponse, FileResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import asyncio
import os
import json
import urllib.parse
import traceback
import requests
import time
import shlex


app = FastAPI()

# Allow all origins, all methods, and all headers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # You can specify a list of allowed origins here
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
    expose_headers=["x-lemma-timeout"],  # Expose the custom header
)

# get a list of every file (not directory) with +x set in the tools directory
tools = [f for f in os.listdir("tools") if os.path.isfile(os.path.join("tools", f)) and os.access(os.path.join("tools", f), os.X_OK)]

# write it to a json file at the root of the static directory
with open("/tmp/tools.json", "w") as f:
    json.dump(tools, f)

def access_allowed(request):
    key = os.getenv("LEMMA_API_KEY")
    ckey = request.cookies.get("LEMMA_API_KEY")
    if ckey and ckey == key:
        return None
    # check if key is in the header field "x-lemma-api-key"
    header_key = request.headers.get("x-lemma-api-key")
    if header_key and header_key == key:
        return None

    if key and request.query_params.get("key") == key:
        # return redirect to '/' with a cookie set
        r = Response(status_code=302, headers={"Location": "/"})
        # set the cookie as secure and httponly
        r.set_cookie("LEMMA_API_KEY", key, secure=True, httponly=True)
        return r
    return Response(status_code=404)

@app.exception_handler(404)
async def custom_404_handler(request, exc):
    # Customize the response here
    return Response(status_code=404)

@app.exception_handler(405)
async def custom_405_handler(request, exc):
    # Customize the response here
    return Response(status_code=404)

# Mount the tools.json file to /static/tools.json
@app.get("/tools.json")
async def get_tools(request: Request):
    response = access_allowed(request)
    if response is not None:
        return response
    return FileResponse("/tmp/tools.json", media_type="application/json", headers={"Cache-Control": "no-store"})

@app.get("/static/lemma-term.js")
async def read_js(request: Request):
    response = access_allowed(request)
    if response is not None:
        return response
    return FileResponse("static/lemma-term.js", media_type="application/javascript", headers={"Cache-Control": "no-store"})

@app.get("/")
async def read_root(request: Request):
    response = access_allowed(request)
    if response is not None:
        return response
    return FileResponse("static/index.html", media_type="text/html", headers={"Cache-Control": "no-store"})

async def execute(command, stdinput=None, verbose=False, no_stderr=False):
    global g_runningprocess
    global g_timeout
    global g_req_context
    global g_lam_context

    timeout = int(os.getenv("LEMMA_TIMEOUT", 60)) - 5 # subtract 5 seconds to allow for cleanup
    time_start = time.time()

    if g_req_context is not None:
        # we are running on AWS Lambda
        if verbose:
            r = json.loads(g_req_context)
            yield bytes(f"\x1b[32mLambda Request ID:  \u001b[38;2;145;231;255m{r['requestId']}\x1b[0m\n", "utf-8")
            url = "http://checkip.amazonaws.com/"
            pubipv4 = requests.get(url).text.strip()
            yield bytes(f"\x1b[32mLambda Public IPv4: \u001b[38;2;145;231;255m{pubipv4}\x1b[0m\n", "utf-8")

    try:
        if verbose:
            yield bytes(f"\x1b[32mLambda Command:     \u001b[38;2;145;231;255m", "utf-8") + bytes(str(shlex.split(command)), "utf-8") + b"\x1b[0m\n\n"
        
        process = await asyncio.create_subprocess_exec(
            *shlex.split(command),
            stdin=asyncio.subprocess.PIPE if stdinput else None,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE if no_stderr else asyncio.subprocess.STDOUT
        )
    except FileNotFoundError:
        if verbose:
            yield b"\n\x1b[31mRemote Error:\x1b[0m command not found\n"
        yield b"\r\n"
        return
    except:
        # yield back the traceback if the command failed to execute
        if verbose:
            yield traceback.format_exc().encode()
        yield b"\r\n"
        return
    
    # If input_data is provided, write it to the process's stdin
    if stdinput:
        process.stdin.write(stdinput)
        await process.stdin.drain()
        process.stdin.close()

    # Read and yield stdout data
    while True:
        try:
             data = await asyncio.wait_for(process.stdout.read(4096), timeout=1)
        except asyncio.exceptions.TimeoutError:
            if (time.time() - time_start) > timeout:
                process.kill()
                if verbose:
                    yield b"\n\x1b[31mRemote Error:\x1b[0m lambda function timed out (Lemma Timeout: %d seconds)\n"%(timeout)
                yield b"\r\n"
                return
            continue
        if data:
            yield data
        else:
            break

    await process.wait()
    if verbose:
        yield b"\n\x1b[32mRemote Command Finished \x1b[38;2;145;231;255m- Elapsed Time: " + str(round(time.time() - time_start)).encode() + b" seconds\x1b[0m\n"

@app.post("/runtool")
async def tool(
    request: Request,
    cmd = Query(""),
    verbose = Query("false"),
    no_stderr = Query("false")
    ):
    response = access_allowed(request)
    if response is not None:
        return response

    verbose = True if verbose.lower() == "true" else False
    no_stderr = True if no_stderr.lower() == "true" else False

    global g_req_context
    global g_lam_context
    g_req_context = request.headers.get('x-amzn-request-context')
    g_lam_context = request.headers.get('x-amzn-lambda-context')

    stdinput = await request.body()
    cmd = urllib.parse.unquote(cmd).strip()

    # check if the command is in the tools directory
    if cmd.split()[0] not in tools:
        return Response(status_code=200, content="\x1b[31mError:\x1b[0m Command not found\n".encode())

    cmd = "./tools/" + cmd

    headers = {
        "X-Lemma-Timeout": os.getenv("LEMMA_TIMEOUT", "60")
    }

    return StreamingResponse(execute(cmd, stdinput, verbose, no_stderr), media_type="text/html", headers=headers)