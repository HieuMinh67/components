#!/usr/bin/env bash

source "$(pwd)/platform/bin/variables.sh"

# cd ${ProjectPath} 
 
rm -fr ".cache"

# PathPrefix=${Branch} PREFIX_PATHS=true

EnvPath="${ProjectPath}/.env.local"

echo "" > "${EnvPath}"
echo "PATH_PREFIX=${Branch}" >> "${EnvPath}"
echo "PREFIX_PATHS=true" >> "${EnvPath}"

npx nx build gatsby-showcase --skip-nx-cache

#  npm run build

# nx build gatsby-showcase

# npm run build -w gatsby-showcase

# nx build gatsby-showcase

# PathPrefix=Branch PREFIX_PATHS=true gatsby build