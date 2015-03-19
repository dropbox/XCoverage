# XCoverage
Xcode Plugin that displays coverage data in the text editor

![Example](https://github.com/dropbox/XCoverage/raw/master/docs/example.png)

###Menu options:
![Menu options](https://github.com/dropbox/XCoverage/raw/master/docs/menu.png)
- Quickly toggle with keyboard shortcut CMD+Shift+\
- By default the plugin will try and find your coverage files, however for the best performance/reliability you can set your own location. The plugin will then use this location and recursively search it for your coverage file matching the source file you are viewing.

###Installation instructions:
Open the project in XCode and build it. This should auto-install it for you and just restart XCode to begin using!

To uninstall, delete the XCoverage directory from `~/Library/Application Support/Developer/Shared/Xcode/Plug-ins`

###See test app for example
- If you run the unit tests for the test app (CMD+U) then you will generate coverage data for the ViewController

###Generating coverage data
This plugin does not actually generate coverage data for you, since there are various workflows that people use to do this. However if you don't currently have coverage data, the sample app includes some build scripts that can help you get started.

#####Steps:
#####1. Enable project settings to begin generating coverage information
- Make build setting for Generate Debug Symbols set to YES
- Make build setting for Instrument Program Flow to YES
(See more info at https://developer.apple.com/library/ios/qa/qa1514/_index.html)

#####2. Setup the export_build_vars.py script in build phases
![Export build vars](https://github.com/dropbox/XCoverage/raw/master/docs/export-build-vars.png)

#####3. Add pre-action script to the test section of your scheme
![Pre-action](https://github.com/dropbox/XCoverage/raw/master/docs/pre-actions-setup.png)

#####4. Add post-action script to the test section of your scheme
![Post-action](https://github.com/dropbox/XCoverage/raw/master/docs/post-actions-setup.png)


