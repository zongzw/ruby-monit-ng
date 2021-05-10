import time

# Need not add mutex for multi-thread append and pop, because of GIL
class Cache:
    def __init__(self):
        self.cache = []

    def wait_and_pop(self):
        while len(self.cache) == 0:
            time.sleep(0.01)
        return self.cache.pop()

    def append(self, item):
        self.cache.append(item)

    def listall(self):
        return self.cache

if __name__ == "__main__":
    import threading
    import random
    stop  = False
    cc = Cache()
    
    def add():

        global stop
        global cc
        for n in range(0, 100):
            time.sleep(random.random())
            print("add: %d" % n)
            cc.append("%s" % n)

        stop  = True

    def wait_and_pop1():
        global cc
        global stop
        time.sleep(10)
        while not stop:
            print("all: %s" % cc.listall())
            print("wait_and_pop: %s" % cc.wait_and_pop())

    threads = []
    t1 = threading.Thread(target=add)

    t2 = threading.Thread(target=add)
    t3 = threading.Thread(target=wait_and_pop1)

    for n in [t1, t2, t3]:
        n.start()

    for n in [t1, t2, t3]:
        n.join()
