import os
import time
import random
import logging
from logging.handlers import RotatingFileHandler

class LoggerFactory:
    @staticmethod
    def loggerA(logpath):
        FORMAT = '%(asctime)-15s: %(filename)-10s:%(lineno)-3d %(funcName)-10s %(levelname)-5s %(message)s'

        logger = LoggerFactory.loggerX("%d-%d" % (time.time(), random.randint(0, 10000)), FORMAT, logging.DEBUG,
            RotatingFileHandler, {"filename": logpath, "maxBytes": 128*1024*1024, "backupCount":5})
        return logger
    
    @staticmethod
    def loggerX(name, format, level, handler_type, opts):
        FORMAT = format
        formatter = logging.Formatter(FORMAT)

        handler = handler_type(**opts)
        handler.setFormatter(formatter)

        logger = logging.getLogger(name)
        logger.setLevel(level)
        logger.addHandler(handler)
        return logger


if __name__ == "__main__":
    filepath = os.path.realpath(__file__)
    dirpath = os.path.dirname(filepath)
    logfile = os.path.join(dirpath, "logfile")

    loggera = LoggerFactory.loggerA(logfile)
    loggera.error("this is an error message")
    loggera.info("information test")
    loggera.warn("warning %s " % "zongzw")