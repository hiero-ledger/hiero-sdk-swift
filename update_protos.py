import os
import re
from pathlib import Path

def update_imports(file_path):
    """Update import statements to remove directory paths, preserving google imports."""
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Process each line individually to handle google imports differently
    lines = content.split('\n')
    updated_lines = []
    
    for line in lines:
        # If it's an import line
        if line.strip().startswith('import'):
            # Skip google imports
            if 'google' in line:
                updated_lines.append(line)
            else:
                # Remove directory paths for non-google imports
                updated_line = re.sub(r'import\s+"([^/]+/)*([^"]+)"', r'import "\2"', line)
                updated_lines.append(updated_line)
        else:
            updated_lines.append(line)
    
    updated_content = '\n'.join(updated_lines)
    
    if content != updated_content:
        print(f"Updating: {file_path}")
        with open(file_path, 'w') as f:
            f.write(updated_content)

def process_proto_files():
    protos_dir = Path("Sources/HieroProtobufs/Protos")
    
    # Walk through all .proto files
    for root, _, files in os.walk(protos_dir):
        root_path = Path(root)
        
        # Skip sdk and mirror directories
        if "sdk" in root_path.parts or "mirror" in root_path.parts:
            continue
            
        for file in files:
            if file.endswith('.proto'):
                file_path = root_path / file
                print(f"Processing: {file_path}")
                update_imports(file_path)

if __name__ == "__main__":
    print("Starting proto file updates...")
    process_proto_files()
    print("Finished updating proto files!")
