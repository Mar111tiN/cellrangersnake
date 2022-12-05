import os
import sys
import pandas as pd
from datetime import datetime as dt
from yaml import CLoader as Loader, load


ansii_colors = {
    "magenta": "[1;35;2m",
    "green": "[1;9;2m",
    "red": "[1;31;1m",
    "cyan": "[1;36;1m",
    "gray": "[1;30;1m",
    "black": "[0m",
}

colors = {
    "process": ansii_colors["green"],
    "time": ansii_colors["magenta"],
    "normal": ansii_colors["gray"],
    "warning": ansii_colors["red"],
    "success": ansii_colors["cyan"],
}


def show_output(text, color="normal", multi=False, time=False, **kwargs):
    """
    get colored output to the terminal
    """
    time = (
        f"\033{colors['time']}{dt.now().strftime('%H:%M:%S')}\033[0m : " if time else ""
    )
    proc = f"\033{colors['process']}Process {os.pid()}\033[0m : " if multi else ""
    text = f"\033{colors[color]}{text}\033[0m"
    print(time + proc + text, **kwargs)



def load_config_file(config_file):
    '''
    loads a yaml_config
    '''

    with open(config_file, "r") as stream:
        return load(stream, Loader=Loader)


def full_path(path, base_folder=os.environ['HOME']):
    '''
    extends any path with the base_folder if it is not a full path or starts with "."
    '''
    if path[0] in ["/", "."]:
        return path
    return os.path.join(base_folder,path)


def get_path(path, file_type="file", config={}):
    '''
    retrieves a path value from the given key in the config and does some checks
    '''
    pc = config['paths']
    if not path in pc:
        show_output(f"Please provide a path for the {file_type} in the configs @{path}!", color="warning")
        return
    if not (file_path := pc[path]):
        show_output("Please provide a {file_type} in the configs", color="warning")
        return
    file_path = full_path(pc[path], base_folder=os.environ['HOME'])
        
    if os.path.isfile(file_path):
        return file_path
    else:
        show_output(f"{file_type} {file_path} cannot be found!", color="warning")
        return