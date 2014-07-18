#!/usr/bin/env python2.7

import subprocess
import time
import xmpp
import fileinput

def init_client(jid, password):
    jid = xmpp.protocol.JID(jid)
    client = xmpp.Client(jid.getDomain(), debug=[])
    client.connect()
    client.auth(jid.getNode(), password)
    return client

def send(client, to, text):
    client.send(xmpp.protocol.Message(to, text))

if __name__ == "__main__":

    recipients = subprocess.check_output(["git", "config",
        "hooks.xmppnotify.recipients"]).rstrip().split(" ")
    sender_jid = subprocess.check_output(["git", "config",
        "hooks.xmppnotify.jid"]).rstrip()
    sender_pw = subprocess.check_output(["git", "config",
        "hooks.xmppnotify.password"]).rstrip()

    client = init_client(sender_jid, sender_pw)

    for line in fileinput.input():
        old, new, ref = line.split(" ")
        log = subprocess.check_output(["git", "log", "--no-merges", "--reverse",
            "--find-copies-harder", "--pretty=format:%an: %s (%h)", "-r", 
            "{0}..{1}".format(old, new)]).rstrip()
        for recipient in recipients:
            send(client, recipient, log)
            time.sleep(0.1)
