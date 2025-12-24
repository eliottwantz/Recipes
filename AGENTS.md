Always verify if they are build errors before ending your response. If there are, please fix them and run the build again. Repeat until there are no build errors.

To build the iOS app, run this command and ALWAYS use this exact command:
```bash
xcodebuild -scheme Recipes -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | xcsift -f toon --warnings
```
