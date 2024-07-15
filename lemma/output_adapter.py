from lemma.settings import get_settings

class OutputAdapter:
    def __init__(self):
        self.settings = get_settings()

    def process(self, stdout_queue):
        if (stdout_queue.empty()):
            return
        
        data = stdout_queue.get()
        print(data, end='', flush=True)
        stdout_queue.task_done()
