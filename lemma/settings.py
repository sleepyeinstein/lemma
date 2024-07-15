from lemma.logo import logo
from functools import lru_cache
from argparse import ArgumentParser, REMAINDER, RawDescriptionHelpFormatter
from configparser import ConfigParser
import urllib.parse
import requests
import os, sys
import cProfile

def tools(settings):
    print('Available Remote Tools:')
    url = settings.lambda_url + 'tools.json'
    try:
        response = requests.get(url, cookies={'LEMMA_API_KEY': settings.lambda_key},timeout=5)
    except:
        print('  \u001b[31m<could not access lambda url>\u001b[0m', file=sys.stderr)
        sys.exit(1)

    if response.status_code != 200:
        print('  \u001b[31m<could not access lambda url>\u001b[0m', file=sys.stderr)
        sys.exit(1)

    tools = response.json()
    for tool in tools:
        print('  \u001b[38;2;145;231;255m' + tool + '\u001b[0m')


@lru_cache(maxsize=1)
def get_args():
    parser = ArgumentParser(description=logo,formatter_class=RawDescriptionHelpFormatter)
    parser.add_argument('-w', '--workers', default=1, help='Number of concurrent Lambda service workers')
    parser.add_argument('-l', '--lambda-url', help='Prompt user to enter a new lambda url', action='store_true')
    parser.add_argument('-i', '--invocations', default=1, help='The number of invocations of the remote command')
    parser.add_argument('-p', '--per-stdin', help='Invoke the remote command for each line of stdin (-i is ignored)', action='store_true')
    parser.add_argument('-d', '--div-stdin', help='Divide stdin into DIV_STDIN parts at a newline boundary and invoke on each (-i is ignored)')
    parser.add_argument('-o', '--omit-stdin', help='Omit stdin to the remote command stdin', action='store_true')
    parser.add_argument('-e', '--no-stderr', help='prevent stderr from being streamed into response', action='store_true')
    parser.add_argument('-b', '--line-buffered', help='Stream only line chunks to stdout', action='store_true')
    parser.add_argument('-v', '--verbose', help='Enable verbose remote output', action='store_true')
    parser.add_argument('-t', '--tools', help='List available tools', action='store_true')

    parser.add_argument('remote_command', help='lemma <options> -- remote_command',nargs=REMAINDER)
    args = parser.parse_args()

    return args, parser

def validate_args(settings):
    parser = settings.parser
    args = settings.args
    if len(sys.argv) == 1:
        parser.print_help()
        sys.stdout.write('\n')
        tools(settings)
        sys.exit(1)

    if args.tools:
        tools(settings)
        sys.exit(0)

    # validate that -d and -p are not used together
    if args.div_stdin and args.per_stdin:
        print('error: -d and -p cannot be used together', file=sys.stderr)
        sys.exit(1)

    if args.div_stdin and args.omit_stdin:
        print('error: -d and -o cannot be used together', file=sys.stderr)
        sys.exit(1)

    # args.div_stdin must be a non-zero positive integer
    if args.div_stdin:
        try:
            if int(args.div_stdin) <= 0:
                raise ValueError
        except:
            print('error: -d must be a non-zero positive integer', file=sys.stderr)
            sys.exit(1)

class Settings:
    def __init__(self):
        # Parse cli arguments
        args, parser = get_args()

        self.config = ConfigParser()
        self._load_config()

        if args.lambda_url:
            self.ask_config()

    def ask_config(self):
        self.lambda_url = input('Please enter the URL of the Lambda service: ')

    def _load_config(self):
        newconfig = False
        config_dir_path = os.path.expanduser('~/.lemma')
        config_file_path = os.path.join(config_dir_path, 'lemma.ini')

        # check if config_dir_path exists
        if not os.path.exists(config_file_path):
            newconfig = True

        # Ensure the directory exists
        os.makedirs(config_dir_path, exist_ok=True)

        # Ensure the file exists
        open(config_file_path, 'a').close()

        self.config.read([config_file_path])

        if newconfig:
            print('Welcome to Lemma! we could not find a configuration file, so lets create one for you.')
            self.ask_config()

    def _save_config(self):
        config_dir_path = os.path.expanduser('~/.lemma')
        config_file_path = os.path.join(config_dir_path, 'lemma.ini')

        with open(config_file_path, 'w') as configfile:
            self.config.write(configfile)

    @property
    def args(self):
        args, _ = get_args()
        return args
    
    @property
    def parser(self):
        _, parser = get_args()
        return parser
    
    @property
    def remote_command(self):
        remote_command = '--'.join(((' '.join(self.args.remote_command)).split('--')[1:]))
        return remote_command.strip()

    @property
    def lambda_url(self):
        lurl = self.config.get('DEFAULT', 'lambda_url', fallback=None)

        if lurl is None:
            # errpr no lambda url
            print('error: no lambda url specified', file=sys.stderr)

        # parse the url and get the hostname
        parsed = urllib.parse.urlparse(lurl)
        return parsed.scheme + '://' + parsed.netloc + '/'
    
    @property
    def lambda_key(self):
        lurl = self.config.get('DEFAULT', 'lambda_url', fallback=None)

        if lurl is None:
            # errpr no lambda url
            print('error: no lambda url specified', file=sys.stderr)

        # parse the url and get the query variable named "key"
        parsed = urllib.parse.urlparse(lurl)
        query = urllib.parse.parse_qs(parsed.query)
        return query.get('key', [''])[0]

    
    @lambda_url.setter
    def lambda_url(self, value):
        self.config.set('DEFAULT', 'lambda_url', value)
        self._save_config()

    @property
    def stdin_pipe_exists(self) -> bool:
        return not sys.stdin.isatty()



@lru_cache(maxsize=1)
def get_settings()->Settings:
    s = Settings()
    validate_args(s)
    return s

@lru_cache(maxsize=1)
def get_profiler():
    return cProfile.Profile()