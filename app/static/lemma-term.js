
let disableInput = false;
let prompt = '\x1b[33mlemma$\x1b[0m ';
let commandBuffer = '';
let toollist = [];
let lineBuffer = [];
let history = [];
let historyIndex = -1;
let offset = 0;
let lambdaurl = "";
let lemmaauth = "";

function stripAnsiCodes(str) {
    // Regular expression to match ANSI escape codes
    const ansiRegex = /\x1b\[[0-9;]*m/g;
    return str.replace(ansiRegex, '');
}

async function load_tools()
{
    try {
        const response = await fetch(lambdaurl + '/tools.json', {
            headers: {
                "x-lemma-api-key": lemmaauth
            }
        });
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        const tools = await response.json();
        return tools;
    }
    catch (error) {
        console.error('Error fetching tools:', error);
    }
    return [];
}

function populate_tools() {
    load_tools().then((tools) => {
        toollist = [];
        tools.forEach(tool => {
            toollist.push(tool);
        });
    });
}

function list_tools(terminal) {
    load_tools().then((tools) => {
        terminal.write('Available Remote Tools:\r\n');
        toollist = [];
        tools.forEach(tool => {
            toollist.push(tool);
            terminal.write(`  \u001b[38;2;145;231;255m${tool}\u001b[0m\r\n`);
        });
        terminal.write("\r\n");
        terminal.write("Run using \x1b[32mrun \u001b[38;2;145;231;255m<tool> <args>\x1b[0m or \x1b[32mfork \u001b[38;2;145;231;255m<tool> <args>\x1b[0m or simply \u001b[38;2;145;231;255m<tool> <args>\x1b[0m\r\n");
        terminal.write(prompt);
    });
}

function typeNextChar(terminal, text, delay) {
    return new Promise((resolve) => {
        let index = 0;

        function step() {
            if (index < text.length) {
                terminal.write(text[index]);
                index++;
                setTimeout(step, delay);
            } else {
                terminal.write('\r\n\r\n');
                list_tools(terminal);
                disableInput = false;
                resolve();
            }
        }

        step();
    });
}

async function printWithDelay(terminal, text, delay) {
    await typeNextChar(terminal, text, delay);
}

async function intro(terminal)
{
    disableInput = true;
    const sstr = "\u001b\u005b\u0033\u0033\u006d\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u2584\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2588\u2584\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2588\u2584\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2584\u0020\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2580\u2580\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2588\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2588\u2588\u2588\u2584\u2584\u2584\u2584\u2584\u0020\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u2588\u2588\u2584\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2580\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u2584\u2588\u2580\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u2588\u2588\u2584\u0020\u0020\u2584\u2588\u2580\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u2588\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u2580\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u2588\u2588\u2588\u2588\u2580\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u2584\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u2580\u2588\u2588\u0020\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u2584\u2584\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u2584\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2588\u0020\u000d\u000a\u0020\u0020\u0020\u0020\u0020\u2580\u2588\u2588\u2588\u2588\u2588\u2588\u2580\u2580\u2580\u0020\u0020\u0020\u0020\u2580\u2588\u2588\u2588\u2588\u2588\u2580\u2580\u2580\u0020\u0020\u0020\u2590\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u0020\u2588\u2588\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u258c\u0020\u0020\u0020\u2588\u2588\u2580\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u0020\u2588\u2588\u2580\u001b\u005b\u0030\u006d\u000d\u000a"
    terminal.write(sstr+ "\r\n\r\n");
    terminal.write('                          ');
    const phrase = 'Response Streaming CLI Tools on AWS Lambda';
    const delay = 25; // Delay in milliseconds

    printWithDelay(terminal, phrase, delay);
}

async function execute_remote_tool(terminal, args) {
    const abortController = new AbortController();

    try {
        const url = new URL('/runtool', lambdaurl);
        url.searchParams.set('cmd', encodeURIComponent(args));
        url.searchParams.set('verbose', "true");

        const response = await fetch(url.toString(), {
            method: 'POST',
            signal: abortController.signal,
            headers: {
                "x-lemma-api-key": lemmaauth
            }
        });

        if (!response.body) {
            throw new Error('ReadableStream not supported.');
        }

        // Get the timeout from the header and set the timeout
        const timeoutHeader = response.headers.get('x-lemma-timeout');
        const timeout = parseInt(timeoutHeader, 10) * 1000; // Convert to milliseconds

        // Set a timeout to abort the request
        const timeoutId = setTimeout(() => {
            abortController.abort();
            terminal.write('\r\n\u001b[31mError: Stream timeout exceeded.\x1b[0m\r\n');
        }, timeout);

        const reader = response.body.getReader();
        const decoder = new TextDecoder('utf-8');

        while (true) {
            const { done, value } = await reader.read();
            if (done) {
                clearTimeout(timeoutId); // Clear the timeout if done
                break;
            }
            let chunk = decoder.decode(value, { stream: true });
            // replace any \n with \r\n
            chunk = chunk.replace(/\n/g, '\r\n');
            terminal.write(chunk);
        }

        terminal.write('\r\n\u001b[38;2;145;231;255mRemote tool execution complete.\x1b[0m\r\n');
        disableInput = false;
        terminal.write(prompt);
    } catch (error) {
        if (error.name === 'AbortError') {
            terminal.write('\r\n\u001b[31mError: Remote execution failed due to timeout.\x1b[0m\r\n');
        } else {
            terminal.write(`\r\nError: ${error.message}\r\n`);
        }
        disableInput = false;
        terminal.write(prompt);
    }
}

document.addEventListener('DOMContentLoaded', () => {


    let truerows = 45;
    let truecols = 150;

    if (terminalContainer.clientWidth <= 1024) {
        truecols = 100;
    }

    
    const terminal = new Terminal({
        rows: truerows,
        cols: truecols
    });
    const fitAddon = new FitAddon.FitAddon();
    terminal.loadAddon(fitAddon);
    function fitTerminal() {
       const containerWidth = terminalContainer.clientWidth;
       const containerHeight = terminalContainer.clientHeight;
       const cols = truecols;
       const rows = truerows;
       const cellWidth = containerWidth / cols;
       const cellHeight = containerHeight / rows;
       // Set the font size based on the smallest dimension to maintain aspect ratio
       const fontSize = Math.min(cellWidth, cellHeight) * 1.6;
       console.log(cols)
//
       // // Apply the calculated font size to the terminal
       // // Apply the calculated font size to the terminal
       terminal.options.fontSize = fontSize;

        fitAddon.fit();
        console.log("fitting terminal")
    }

    terminal.open(document.getElementById('terminalContainer'));
    fitTerminal();
    terminal.focus();

    // Adjust terminal size when window is resized
    window.addEventListener('resize', fitTerminal);

    // first lets get the LAMBDA_URL cookie using document.cookie
    const cookies = document.cookie.split(';');
    
    cookies.forEach(cookie => {
        if (cookie.includes('LEMMA_URL')) {
            lambdaurl = cookie.split('=')[1];
        }
    });

    cookies.forEach(cookie => {
        if (cookie.includes('LEMMA_OVERRIDE_API_KEY')) {
            lemmaauth = cookie.split('=')[1];
        }
    });

    if (lambdaurl === "") {
        // get the host name of the page
        lambdaurl = window.location.origin
    }


    // check if the command query has been set
    const urlParams = new URLSearchParams(window.location.search);
    const command = urlParams.get('cmd');
    if (command) {
        populate_tools();
        terminal.write(prompt+`${command}\r\n`);
        executeCommand(command);
    }
    else
    {
        intro(terminal);
    }

    async function simpleShell(term, data) {
    let CurX = term.buffer.active.cursorX;
    let CurY = term.buffer.active.cursorY;
    let MaxX = term.cols;
    let MaxY = term.rows;

    if (disableInput === true) {
            return;
    }
    // string splitting is needed to also handle multichar input (eg. from copy)
    for (let i = 0; i < data.length; ++i) {
        const c = data[i];
        if (c === '\r') {  // <Enter> was pressed case
            offset = 0;
            term.write('\r\n');
            if (lineBuffer.length) {
                // we have something in line buffer, normally a shell does its REPL logic here
                // for simplicity - just join characters and exec...
                const command = lineBuffer.join('');
                lineBuffer.length = 0;
                history.push(command);
                historyIndex = history.length;
                executeCommand(command);
            }
            else {
                term.write(prompt);
            }
        } else if (c === '\x7F') {  // <Backspace> was pressed case
            if (lineBuffer.length) {
                if (offset === 0) {
                    if (CurX === 0) {
                        // go to the previous line end
                        term.write('\x1b[1A'); // control code: move up one line
                        term.write('\x1b[' + MaxX + 'C'); // control code: move to the end of the line       
                    } 
                    lineBuffer.pop();
                    term.write('\b \b');
                }
            }
        } else if (['\x1b[5', '\x1b[6'].includes(data.slice(i, i + 3))) {
            // not implemented 
            i += 3;
        } else if (['\x1b[F', '\x1b[H'].includes(data.slice(i, i + 3))) {

            if (data.slice(i, i + 3) === '\x1b[H') { // Home key
                // not implemented
            }
            else if (data.slice(i, i + 3) === '\x1b[F') { // End key
                // not implemented
            }
            i += 3;
        } else if (['\x1b[A', '\x1b[B', '\x1b[C', '\x1b[D'].includes(data.slice(i, i + 3))) {  // <arrow> keys pressed
            if (data.slice(i, i + 3) === '\x1b[A') { // up arrow
                if (historyIndex > 0) {
                    historyIndex--;
                    updateCommandBuffer(history[historyIndex]);
                }
            } else if (data.slice(i, i + 3) === '\x1b[B') { // down arrow
                if (historyIndex < history.length - 1) {
                    historyIndex++;
                    updateCommandBuffer(history[historyIndex]);
        
                } else {
                    historyIndex = history.length;
                    updateCommandBuffer('');
                }
            }
            else if (data.slice(i, i + 3) === '\x1b[C') { // right arrow
                // not implemented
            }
            else if (data.slice(i, i + 3) === '\x1b[D') { // left arrow
                // not implemented
            }
            i += 2;
        } else {  // push everything else into the line buffer and echo back to user
            // if we are at the end of the line,
            // move up a row and to the beginning of the line
            if (CurX === MaxX - 1) {
                term.write('\r\n');
            }
            lineBuffer.push(c);   
            term.write(c);
            
        }
    }
}
    
    terminal.onData(data => simpleShell(terminal, data));

    function executeCommandSingle(command) {

        // Empty function for now
        //terminal.write(`Executing command: ${command}\r\n`);
        // split command and get first token
        const command0 = command.split(' ')[0];
        const command1 = command.split(' ')[1];

        if (command0 === 'help') {
            terminal.write('Available Local Commands:\r\n');
            terminal.write('  \x1b[32mhelp                 -\x1b[0m Show this help message\r\n');
            terminal.write('  \x1b[32mclear                -\x1b[0m Clear the terminal\r\n');
            terminal.write('  \x1b[32mtools                -\x1b[0m Show a list of remote tools\r\n');
            terminal.write('  \x1b[32msize                 -\x1b[0m Show or Set terminal size (i.e size, size 45x100)\r\n');
            terminal.write('  \x1b[32mrun <args>           -\x1b[0m Run a remote tool in the current terminal\r\n');
            terminal.write('  \x1b[32mfork <args>          -\x1b[0m Run a remote tool in a new terminal\r\n');
            terminal.write('  \x1b[32mset-url <lamdaurl>   -\x1b[0m Set the lambda URL\r\n');
            terminal.write(prompt);
        } else if (command0 === 'clear') {
            terminal.clear();
            terminal.write(prompt);
        } else if (command0 === 'tools') {
            list_tools(terminal);
        } else if (command0 === 'reset') {
            truerows = 45;
            truecols = 150;
        
            if (terminalContainer.clientWidth <= 1024) {
                truecols = 100;
            }
            toollist = [];
            terminal.clear();
            terminal.resize(truerows, truecols);
            fitTerminal()
            intro(terminal);
        } else if (command0 === 'size') {

            if (command1 === undefined) {
                terminal.write("Terminal size: " + truerows + "x" + truecols + "\r\n");
                terminal.write(prompt);
                return
            }

            const r = command1.split('x')[0];
            const c = command1.split('x')[1];

            if (r === undefined || c === undefined) {
                terminal.write(prompt);
                return
            }

            // resize the terminal based on r and c
            terminal.resize(r, c);
            truerows = r;
            truecols = c;
            fitTerminal()
            terminal.write(prompt);
            
        } else if (command0 === 'fork') {
            const args = ("run " + command.split(' ').slice(1).join(' '));
            const url = new URL(window.location.href);
            const finalurl = url.origin + url.pathname + "?cmd=" + encodeURIComponent(args);
            window.open(finalurl, '_blank');
            terminal.write(prompt);

        } else if (command0 === 'set-url') {
            // lets take the LAMBDA_URL and set it as a cookie called LAMBDA_URL
            const url = command.split(' ').slice(1).join(' ').trim();

            if ((url === "") || (url === undefined)) {
                document.cookie = "LEMMA_URL=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/";
                document.cookie = "LEMMA_OVERRIDE_API_KEY=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/";
                lambdaurl = window.location.origin;
                lemmaauth = "";

                terminal.write(`\x1b[32mLambda URL reset\x1b[0m\r\n`);
                terminal.write(prompt);
                return
            }

            let parsedUrl;
            try {
                parsedUrl = new URL(url);
            } catch (_) { 
                terminal.write(`\x1b[31mInvalid Lambda URL:\x1b[0m ${url}\r\n`);
                terminal.write(prompt);
                return
            }
            
            const hostname = parsedUrl.hostname;
            const keyValue = parsedUrl.searchParams.get('key');

            if (keyValue !== null) {
                document.cookie = "LEMMA_URL=https://" + hostname + "; path=/"
                document.cookie = "LEMMA_OVERRIDE_API_KEY=" + keyValue + "; path=/"
                lambdaurl = "https://" + hostname;
                lemmaauth = keyValue;
                terminal.write(`\x1b[32mLambda URL set to:\x1b[0m ${url}\r\n`);
                terminal.write(prompt);
            }
            else {
                terminal.write(`\x1b[31mInvalid Lambda URL:\x1b[0m ${url}\r\n`);
                terminal.write(prompt);
            }

        } else if (command0 === 'run') {
            const args = command.split(' ').slice(1).join(' ');
            disableInput = true;
            execute_remote_tool(terminal, args);
        } else {
            
            // check if the command is a tool
            if (toollist.includes(command0))
            {
                disableInput = true;
                execute_remote_tool(terminal, command);
            }
            else
            {

                terminal.write(`\x1b[31mCommand not found:\x1b[0m ${command0}\r\n`);
                terminal.write(prompt);
            }
        }

    }

    function executeCommand(command) {
        if (command.includes(';')) {
            const commands = command.split(';');
            commands.forEach((cmd) => {
                // Execute each command in the list and trim any leading/trailing whitespace
                executeCommandSingle(cmd.trim());
            });
        } else {
            executeCommandSingle(command);
        }
    }

    function updateCommandBuffer(command) {
        // Clear current line
        
        terminal.write('\r'+prompt + ' '.repeat(lineBuffer.length) + '\r'+prompt);
        // push every character in the command to the lineBuffer
        lineBuffer = command.split('');

        // Convert the command string into an array of characters
        let commandArray = command.split('');
        let promptlen = stripAnsiCodes(prompt).length
        let i = promptlen;
        while (i < commandArray.length) {
            if (i % terminal.cols === 0 && i !== 0 ) {
                commandArray.splice(i-promptlen-1, 0, '\r\n');
            }
            i++;
        }
        terminal.write(commandArray.join(''));
    }

    // Apply custom CSS to make the scrollbar invisible
    const terminalElement = document.querySelector('#terminal .xterm-viewport');
    if (terminalElement) {
        terminalElement.style.overflowY = 'hidden';
    }
});
