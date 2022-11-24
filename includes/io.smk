import pandas as pd
import os
import re

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
