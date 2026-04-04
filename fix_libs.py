import os
import re

files = [
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceTimer-3.0\AceTimer-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceTab-3.0\AceTab-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceSerializer-3.0\AceSerializer-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceLocale-3.0\AceLocale-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceHook-3.0\AceHook-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceEvent-3.0\AceEvent-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceDB-3.0\AceDB-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceDBOptions-3.0\AceDBOptions-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceConfig-3.0\AceConfigDialog-3.0\AceConfigDialog-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceComm-3.0\AceComm-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceConsole-3.0\AceConsole-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceBucket-3.0\AceBucket-3.0.lua",
    r"C:\Users\kance\Documents\GitHub\!X-Libs\AceAddon-3.0\AceAddon-3.0.lua"
]

for file_path in files:
    if not os.path.exists(file_path):
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    skip = 0
    for i in range(len(lines)):
        if skip > 0:
            skip -= 1
            continue
        
        line = lines[i]
        # Match the LibStub call
        if 'LibStub:NewLibrary(' in line and i + 2 < len(lines):
            # Check if next line is the comment
            if '-- If an older version exists' in lines[i+1] or \
               ('-- If an older version exists' in lines[i+2] and lines[i+1].strip() == ''):
                
                # Check for the pattern
                # Determine where the block starts
                j = i + 1
                if lines[j].strip() == '': j += 1
                
                if '-- If an older version exists' in lines[j]:
                    # We found it. Reformat the current line to be "local Lib = ...; if not Lib then return end"
                    # Get the variable name
                    match = re.search(r'local (\w+)', line)
                    if match:
                        var_name = match.group(1)
                        new_lines.append(line.rstrip() + "\n")
                        new_lines.append(f"if not {var_name} then return end\n")
                        # Skip until 'end' of the block
                        k = j + 1
                        while k < len(lines) and 'if not' not in lines[k] and 'return end' not in lines[k]:
                            k += 1
                        # The block usually has:
                        # if not Lib then
                        #   Lib = GetLibrary
                        #   if not Lib then return end
                        # end
                        # So we skip until the last 'end'
                        
                        # Simpler: skip exactly the comment line + the if/end block (usually 4 lines)
                        # Let's see:
                        # -- If an older version exists (j)
                        # if not Lib then (j+1)
                        #     Lib = GetLibrary (j+2)
                        #     if not Lib then return end (j+3)
                        # end (j+4)
                        skip = (j + 4) - i
                        continue
        
        new_lines.append(line)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print(f"Processed {file_path}")
