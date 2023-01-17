#!/usr/bin/env sh

# abort on errors
set -e

npm run build
git add dist && git commit -m "deploy: adding dist subtree"
git subtree push --prefix dist origin gh-pages