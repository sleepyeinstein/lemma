import sys, time
from threading import Thread
from queue import Queue
from lemma.lambda_worker import LambdaWorker

class Pipeline:
    def __init__(self, settings, input_adapter, output_adapter):
        self.settings = settings
        self.input_adapter = input_adapter
        self.output_adapter = output_adapter
        self.command_queue = Queue()
        self.stdout_queue = Queue()
        self.worker_pool = []

    def pool_create(self):
        self.worker_pool = []
        for i in range(int(self.settings.args.workers)):
            worker = LambdaWorker(self.command_queue, self.stdout_queue)
            self.worker_pool.append(worker)
            thread = Thread(target=LambdaWorker.run, args=(worker,), daemon=True)
            thread.start()

    def pool_idle(self):
        return all(worker.idle for worker in self.worker_pool)

    def pool_stop(self):
        LambdaWorker.stop_all_workers()

    def queues_empty(self):
        return self.command_queue.empty() and self.stdout_queue.empty()

    def run(self):
        
        self.pool_create()

        while True:
            self.input_adapter.process(self.command_queue)
            self.output_adapter.process(self.stdout_queue)
            time.sleep(0.01)
            if self.input_adapter.done and self.queues_empty() and self.pool_idle():
                self.pool_stop()
                break
