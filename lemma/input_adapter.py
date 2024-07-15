from lemma.settings import get_settings
from select import select
import sys

def format_command(command, index, stdin_data):
    if (('%STDIN%' in command) and ("\n" in stdin_data.strip())):
        print("error: cannot place stdin onto remote command with newline characters", file=sys.stderr)
        exit(1)

    command = command.replace(r"%INDEX%", str(index))
    command = command.replace(r"%STDIN%", stdin_data.strip())
    return command

class InputAdapter:
    def __init__(self):
        self.settings = get_settings()
        self.done = False
        self.stdin_closed = False
        self.count = 0

    def readline_stdin(self):
        # Check if there is any data to read from stdin
        ready_to_read, _, _ = select([sys.stdin], [], [], 1.0)
        if sys.stdin in ready_to_read:
            line = sys.stdin.readline()
            if line == "":
                self.stdin_closed = True
                return None
            return line
        else:
            return None
        
    def read_stdin(self):
        if self.stdin_closed:
            return None
        data = sys.stdin.read()
        self.stdin_closed = True
        return data

    def process(self, command_queue):
        if self.done:
            return
        # lambdas are either invoked per stdin line or per the invocations argument value
        if self.settings.args.per_stdin:
            line = self.readline_stdin()
            if line is not None:
                remote_command = self.settings.remote_command
                command_queue.put((format_command(remote_command, self.count, line),line,))
                self.count += 1
            if self.stdin_closed:
                self.done = True
        elif self.settings.args.div_stdin:
            stdin_data = ""
            if self.settings.stdin_pipe_exists:
                stdin_data = self.read_stdin()
            remote_command = self.settings.remote_command

            # we need to divide the stdin data into div_stdin equal parts at the newline boundary
            parts = stdin_data.split('\n')
            parts_len = len(parts)
            # create step and round up to the nearest integer
            step = -(-parts_len // int(self.settings.args.div_stdin))
            for i in range(0, parts_len, step):
                stdin_data = '\n'.join(parts[i:i+step])
                command_queue.put((format_command(remote_command, self.count, stdin_data),stdin_data,))
                self.count += 1
            self.done = True
        else:
            stdin_data = ""
            if self.settings.stdin_pipe_exists:
                stdin_data = self.read_stdin()

            remote_command = self.settings.remote_command
            for i in range(int(self.settings.args.invocations)):
                command_queue.put((format_command(remote_command, i, stdin_data),stdin_data,))

            self.done = True
