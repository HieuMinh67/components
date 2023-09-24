#!/usr/bin/env bash

source "$(pwd)/platform/bin/variables.sh"

# cd ${ProjectPath} 
 
rm -fr ".cache"

# PathPrefix=${BRANCH} PREFIX_PATHS=true

EnvPath="${ProjectPath}/.env.local"

echo "" > "${EnvPath}"
echo "PATH_PREFIX=${BRANCH}" >> "${EnvPath}"
echo "PREFIX_PATHS=true" >> "${EnvPath}"

npx nx build gatsby-showcase --skip-nx-cache

#  npm run build

# nx build gatsby-showcase

# npm run build -w gatsby-showcase

# nx build gatsby-showcase

# PathPrefix=BRANCH PREFIX_PATHS=true gatsby build