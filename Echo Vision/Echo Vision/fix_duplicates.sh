#!/bin/bash\
\
# Close Xcode FIRST before running this!\
\
cd ~/Desktop/hals/ECHOVISION/Echo\\ Vision/Echo\\ Vision\
\
echo "\uc0\u55357 \u56589  Finding duplicate SpeechManager.swift files..."\
find . -name "SpeechManager.swift" -type f\
\
echo ""\
echo "\uc0\u55357 \u56785 \u65039   Deleting duplicates..."\
\
# Delete the ones in wrong locations\
rm -f "./views/SpeechManager.swift"\
rm -f "./trained-models/SpeechManager.swift"\
\
echo ""\
echo "\uc0\u55357 \u56589  Finding all Swift files in wrong locations..."\
\
# Remove Swift files from Copy Bundle Resources locations\
rm -f "./trained-models/DetectionResult.swift"\
rm -f "./views/HomeView.swift"\
rm -f "./views/CameraView.swift"\
\
echo ""\
echo "\uc0\u55357 \u56785 \u65039   Removing wrong folders..."\
rm -rf ./views\
rm -rf ./trained-models\
rm -rf ./datasets\
rm -rf ./scenes_backup_34\
rm -rf ./scenes_new\
\
echo ""\
echo "\uc0\u9989  Cleanup complete!"\
echo ""\
echo "\uc0\u55357 \u56513  Creating proper folder structure..."\
\
mkdir -p Models\
mkdir -p Views  \
mkdir -p ViewModels\
\
echo ""\
echo "\uc0\u9989  Folders created!"\
echo ""\
echo "Now:"\
echo "1. Open Xcode"\
echo "2. Go to Project \uc0\u8594  Build Phases"\
echo "3. Remove ALL .swift files from 'Copy Bundle Resources'"\
echo "4. Make sure ALL .swift files are in 'Compile Sources'"\
echo "5. Product \uc0\u8594  Clean Build Folder (Shift+Cmd+K)"\
echo "6. Product \uc0\u8594  Build (Cmd+B)"}
