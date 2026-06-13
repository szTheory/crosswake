import os
import re

def fix_published(content):
    # Fix "public @Published" -> "@Published public"
    return re.sub(r'public\s+@Published\s+(private\(set\)\s+)?var\b', lambda m: f'@Published public {m.group(1) or ""}var', content)

def add_public_to_types(content):
    # Add public to specific enums and structs that were missed
    content = re.sub(r'(\b)(struct\s+Route\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(struct\s+TransferSeam\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(enum\s+CommandResult\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(enum\s+NotificationTokenCommandSnapshot\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(struct\s+Compatibility\b)', r'\1public \2', content)
    # also ActivationCoordinator Route
    return content

directory = 'packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore'
for filename in os.listdir(directory):
    if not filename.endswith('.swift'): continue
    filepath = os.path.join(directory, filename)
    with open(filepath, 'r') as f:
        content = f.read()
        
    new_content = fix_published(content)
    new_content = add_public_to_types(new_content)
    
    with open(filepath, 'w') as f:
        f.write(new_content)

