
import logging

verbose_logging = False

def log_verbose(msg: str):
	if verbose_logging:
		logging.debug(msg)