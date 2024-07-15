from lemma.settings import get_settings, get_profiler
from lemma.pipeline import Pipeline
from lemma.input_adapter import InputAdapter
from lemma.output_adapter import OutputAdapter
import sys


def main():
    settings = get_settings()

    if settings.remote_command == "":
        print("error: no remote command specified", file=sys.stderr)
        exit(1)
    
    if not settings.stdin_pipe_exists and settings.args.per_stdin:
        print("error: cannot invoke per stdin line, stdin has no pipe", file=sys.stderr)
        exit(1)

    pipe = Pipeline(
        settings=settings,
        input_adapter=InputAdapter(),
        output_adapter=OutputAdapter(),
    )

    pipe.run()

if __name__ == "__main__":
    main()