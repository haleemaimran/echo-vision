#!/bin/bash

echo "🧹 Cleaning ECHOVISION project..."

cd ~/Desktop/hals/ECHOVISION

echo "📊 Current size:"
du -sh .

echo ""
echo "🔍 Finding large files..."

# Show what's taking space
echo "=== Breakdown by folder ==="
du -sh * 2>/dev/null | sort -hr | head -10

echo ""
echo "=== Large files (>1MB) ==="
find . -type f -size +1M -exec du -h {} \; | sort -hr | head -20

echo ""
echo "🗑️  Cleaning up..."

# Remove system files
find . -name ".DS_Store" -delete
echo "✅ Removed .DS_Store files"

# Remove build artifacts
find . -name "DerivedData" -type d -exec rm -rf {} + 2>/dev/null
echo "✅ Removed DerivedData"

# Remove Xcode user data
find . -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null
echo "✅ Removed xcuserdata"

# Remove temporary files
find . -name "*.swp" -delete
find . -name "*~" -delete
find . -name ".*.swp" -delete
echo "✅ Removed temp files"

# Remove duplicate models (keep only ones in Echo Vision/Echo Vision/models/)
echo ""
echo "🔍 Checking for duplicate models..."
find . \( -name "*.mlmodel" -o -name "*.mlpackage" \) ! -path "*/Echo Vision/Echo Vision/models/*" -exec ls -lh {} \;

echo ""
echo "📊 New size:"
du -sh .

echo ""
echo "✅ Cleanup complete!"