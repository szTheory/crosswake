import os
import re

def add_public_to_types(content):
    content = re.sub(r'(\b)(struct\s+TransferRecord\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(struct\s+StagedDocument\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(enum\s+TransferCommand\b)', r'\1public \2', content)
    content = re.sub(r'(\b)(enum\s+TransferState\b)', r'\1public \2', content)
    return content

filepath = 'packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/TransferCoordinator.swift'
with open(filepath, 'r') as f:
    content = f.read()
new_content = add_public_to_types(content)
with open(filepath, 'w') as f:
    f.write(new_content)
