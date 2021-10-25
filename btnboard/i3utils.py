import json
import subprocess

def get_i3_tree():
    completed = subprocess.run(["i3-msg", "-t", "get_tree"], stdout=subprocess.PIPE)
    return json.loads(completed.stdout)

def find_node(tree, predicate):
    for node in tree:
        if predicate(node):
            return node
        if node["nodes"] != None:
            node = find_node(node["nodes"], predicate)
            if node != None:
                return node
    return None

def find_window(predicate):
    tree = get_i3_tree()
    return find_node(tree["nodes"], predicate)

def find_active_window():
    return find_window(lambda node: node["focused"] == True)

def focus_window(predicate):
    wnd = find_window(predicate)
    if wnd == None:
        return
    completed = subprocess.run(["i3-msg", "[con_id=\"{}\"]".format(wnd["id"]), "focus"])
    return completed.returncode

if __name__ == "__main__":
    focus_zoom_meeting_window()
