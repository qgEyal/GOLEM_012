extends Node

"""
General Signal utility to catch and emit signals from other nodes
This is set as a singleton (in the Globals config)
"""
signal message_sent(text, color) # for message_log
signal info_sent(text, color) # for info_log
