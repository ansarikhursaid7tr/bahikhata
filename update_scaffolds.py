import os
import glob

# paths to process
files = glob.glob('lib/screens/**/*.dart', recursive=True)
exclude = ['dashboard_screen.dart', 'login_screen.dart', 'settings_screen.dart']

count = 0
for f in files:
    if any(e in f for e in exclude):
        continue
    with open(f, 'r') as file:
        content = file.read()
    
    if 'return Scaffold(' in content or ' Scaffold(' in content:
        # Calculate import depth
        depth = f.count('/') - 1
        # lib/screens/foo.dart -> depth = 2. import '../widgets/app_scaffold.dart'
        # lib/screens/users/foo.dart -> depth = 3. import '../../widgets/app_scaffold.dart'
        import_path = '../' * (depth - 1) + 'widgets/app_scaffold.dart'
            
        import_stmt = f"import '{import_path}';"
        
        if import_stmt in content:
            continue
            
        # Insert import after the last import
        lines = content.split('\n')
        last_import = -1
        for i, line in enumerate(lines):
            if line.startswith('import '):
                last_import = i
                
        if last_import != -1:
            lines.insert(last_import + 1, import_stmt)
            content = '\n'.join(lines)
            
        content = content.replace('return Scaffold(', 'return AppScaffold(')
        content = content.replace(' Scaffold(', ' AppScaffold(')
        
        with open(f, 'w') as file:
            file.write(content)
        count += 1
        print(f"Updated {f}")
        
print(f"Total updated: {count}")
