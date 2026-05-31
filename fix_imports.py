import os
import glob
import re

files = glob.glob('lib/screens/**/*.dart', recursive=True)

for f in files:
    with open(f, 'r') as file:
        content = file.read()
    
    changed = False
    
    # Fix incorrect relative imports
    if "import '../widgets/app_scaffold.dart';" in content:
        content = content.replace("import '../widgets/app_scaffold.dart';", "import 'package:bahi_khata/widgets/app_scaffold.dart';")
        changed = True
        
    if "import '../../widgets/app_scaffold.dart';" in content:
        content = content.replace("import '../../widgets/app_scaffold.dart';", "import 'package:bahi_khata/widgets/app_scaffold.dart';")
        changed = True
        
    # Just in case there are missing imports
    if 'AppScaffold(' in content and "import 'package:bahi_khata/widgets/app_scaffold.dart';" not in content:
        # Find last import
        lines = content.split('\n')
        last_import = -1
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
        if last_import != -1:
            lines.insert(last_import + 1, "import 'package:bahi_khata/widgets/app_scaffold.dart';")
            content = '\n'.join(lines)
            changed = True
            
    if changed:
        with open(f, 'w') as file:
            file.write(content)
        print(f"Fixed {f}")
