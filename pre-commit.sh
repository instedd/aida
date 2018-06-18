#!/bin/sh
NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'

echo "${GREEN}----==== Running Mix tests ====----${NC}"
docker-compose run --rm -e MIX_ENV=test app mix do compile --force --warnings-as-errors, test
MIX=$?

if [ $MIX -eq 0 ]; then
  echo "${GREEN}OK${NC}";
fi

echo "${GREEN}----==== Running Dialyzer ====----${NC}"
DIALYZER="$(docker-compose run --rm app mix dialyzer)"
echo "${DIALYZER}"

if [[ $DIALYZER == *"done (passed successfully)"* ]]; then
  echo "${GREEN}OK${NC}";
fi

if [ $MIX -eq 0 ] && [[ $DIALYZER == *"done (passed successfully)"* ]]; then
  echo "${GREEN}----==== Good to go! ====----${NC}"
else
  echo "${RED}----==== Oops! ====----${NC}"

  if [ $MIX -ne 0 ]; then
  echo "${RED}Mix tests failed${NC}";
  fi

  if [[ $DIALYZER != *"done (passed successfully)"* ]]; then
    echo "${RED}Dialyzer failed${NC}";
  fi

  echo "${RED}----==== Oops! ====----${NC}"
fi
