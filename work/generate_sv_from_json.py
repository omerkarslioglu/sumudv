import json
import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument("config_name", help="JSON config name (without path or extension)")
args = parser.parse_args()

json_file = f"../test/configs/{args.config_name}.json" # fix it
svh_file = "../env/config_auto.svh" # fix it

def flatten_dict(d, parent_key='', sep='.'):
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

with open(json_file) as f:
    data = json.load(f)

flat_data = flatten_dict(data)

with open(svh_file, "w") as svf:
    svf.write("// Auto-generated from config.json\n")
    svf.write("// Do not edit manually!\n\n")
    svf.write("function void load_cfg_array(ref t_bit_arr cfg_array);\n")
    for k, v in flat_data.items():
        if isinstance(v, bool):
            v = int(v)
        if isinstance(v, str):
            svf.write(f'  cfg_array["{k}"] = "{v}";\n')
        else:
            svf.write(f'  cfg_array["{k}"] = {v};\n')
    svf.write("endfunction\n")

print(f"? Generated {svh_file} from {json_file} ({len(flat_data)} entries).")
