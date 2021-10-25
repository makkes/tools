import json
import os
import serial
import subprocess
import time
import i3utils
import argparse

def run(ser, delay, cbs):
    buttons = [0, 0, 0, 0, 0, 0, 0]
    while True:
        b = ser.readline().strip()
        if b == b'EOS':
            # empty read is interpreted as exit
            return
        try:
            state = int(b, 16)
            process(state, buttons, delay, cbs)
        except ValueError as err:
            print("skipping unparseable input: {}".format(err))

def process(state, buttons, delay, cbs):
    for idx, btn in enumerate(buttons):
        if state >> idx & 1 == 0:
            if buttons[idx] != -1:
                buttons[idx] += 1
                if buttons[idx] >= delay/10:
                    buttons[idx] = -1
                    cbs[idx]()
        else:
            buttons[idx] = 0

def create_kind_cluster():  
    os.system("espeak-ng 'creating kind cluster'")
    os.system("kind create cluster")
    os.system("espeak-ng 'kind cluster running'")

def delete_kind_cluster():
    os.system("espeak-ng 'shutting down kind cluster'")
    os.system("kind delete cluster")
    os.system("espeak-ng 'kind cluster shut down'")

def beep():
    os.system("mpg321 ~/sounds/tng/alarm01.mp3")

prev_workspace = -1
def switch_to_ws_1():
    global prev_workspace
    completed = subprocess.run(["i3-msg", "-t", "get_workspaces"], stdout=subprocess.PIPE)
    workspaces = json.loads(completed.stdout)
    cur_workspace = next(e for e in workspaces if e["focused"] == True)["num"]
    if prev_workspace != -1 and cur_workspace == 1:
        os.system("i3-msg workspace number {}".format(prev_workspace))
        prev_workspace = -1
    else:
        os.system("i3-msg workspace number 1")
        prev_workspace = cur_workspace

def sleep():
    os.system("sleep 5")

prev_win = None
def focus_zoom_meeting_window():
    global prev_win
    cur_win = i3utils.find_active_window()
    prev_win = cur_win
    if i3utils.focus_window(lambda node: node["name"] == "Zoom Meeting") != 0:
        beep_error()

def focus_prev_win():
    global prev_win
    if prev_win == None:
        return
    i3utils.focus_window(lambda node: node["id"] == prev_win["id"])
    prev_win = None

def toggle_mute():
    subprocess.run(["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"])

def beep_error():
    subprocess.run(["ogg123", "-q", "/usr/share/sounds/ubuntu/stereo/dialog-error.ogg"])

def beep():
    subprocess.run(["aplay", "/home/max/sounds/mixkit-clock-countdown-bleeps-916.wav"])

def echo(str):
    def res():
        print("button pressed: {}".format(str))
    return res

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="React to button presses")
    parser.add_argument("-d", "--device", help="serial device to connect to", default="/dev/ttyACM0")
    args = parser.parse_args()
    run(serial.Serial(args.device), 50, [
        beep,
        beep_error,
        #focus_zoom_meeting_window,
        #toggle_mute,
        ])
