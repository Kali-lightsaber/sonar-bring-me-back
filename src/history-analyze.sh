#!/bin/bash

# script based on https://gist.github.com/aslakknutsen/2422117

GIT_REPO=/gitrepo

ls -al /gitrepo
git --version

SONAR_COMMAND="sonar-scanner"

if [ -z "$START_DATE" ]; then
    LASTDATE="0001-01-01"
    echo "Missing program argument: start-date"
    echo "Analyze will start from first commit of branch"
else
    LASTDATE=$START_DATE
fi

if [[ "$DATE_DIFF_STEP" == '"per-year"' ]]; then
  DIFF_STEP="+1 year"
elif [[ "$DATE_DIFF_STEP" == '"per-half-year"' ]]; then
  DIFF_STEP="+6 month"
elif [[ "$DATE_DIFF_STEP" == '"per-quarter"' ]]; then
  DIFF_STEP="+3 month"
elif [[ "$DATE_DIFF_STEP" == '"per-month"' ]]; then
  DIFF_STEP="+1 month"
elif [[ "$DATE_DIFF_STEP" == '"per-sprint"' ]]; then
  DIFF_STEP="+2 week"
elif [[ "$DATE_DIFF_STEP" == '"per-week"' ]]; then
  DIFF_STEP="+1 week"
elif [[ "$DATE_DIFF_STEP" == '"per-day"' ]]; then
  DIFF_STEP="+1 day"
else
  DIFF_STEP="+1 day"
  echo "Incorrect program argument DATE_DIFF_STEP: $DATE_DIFF_STEP"
  echo "Analyze will switch between +1 day"
fi

if [ -z "$SONAR_TOKEN" ]; then
    echo "You need to provide auth for your instanse"
else
   AUTH="-Dsonar.login=$SONAR_TOKEN"
fi 

git config --global --add safe.directory /gitrepo
git config --global --add safe.directory /tmp/gitrepo
if git rev-parse --is-inside-work-tree; then
  echo "starting checkout history of git repo"
else
  echo "you did't provide correct git repo"
  exit 42 # "why 42 ? please google it as an answer"
fi

cp -ar /gitrepo /tmp/gitrepo
cp /gitrepo/sonar-project.properties /tmp/sonar-project.properties || \
  { echo "You need to create sonar-projects.properties file"; exit 42;}

dos2unix /tmp/sonar-project.properties

pushd /tmp/gitrepo

git clean -df

CURRENT_BRANCH=`git branch --show-current`
FIRST_HASH_OF_BRANCH=`git rev-list -1 --before="$START_DATE" $CURRENT_BRANCH`

for hash in `git --no-pager log --reverse --after="$START_DATE" --pretty=format:%h $CURRENT_BRANCH`
do
    #template T03:00:00+0300
    HASH_DATE=`git show $hash --date=iso | grep Date: -m1 | cut -d' ' -f 4`
    HASH_TIME=`git show $hash --date=iso | grep Date: -m1 | cut -d' ' -f 5`

    if [[ "$HASH_DATE" > "$LASTDATE" ]] ;
    then
      echo "New commit in new date $HASH_DATE"
      LASTDATE=$HASH_DATE 
      DATE_DIFF="$LASTDATE $DIFF_STEP"
      LASTDATE=`date '+%C%y-%m-%d' -d "$DATE_DIFF"`
      echo "Next analyze date $LASTDATE (switch next analyze date by step $DIFF_STEP =$DATE_DIFF=)"
    elif [[ "$HASH_DATE" == "$LASTDATE" ]] ;
    then
      echo "Hash $hash skiped $HASH_DATE because it similar on $LASTDATE"
      continue
    else
      echo "Hash $hash skiped because of diff step"
      continue
    fi
    
    LATEST_BRANCH_TAG=`git describe --tags --abbrev=0`
    PROJECT_VERSION=`grep sonar.projectVersion /tmp/sonar-project.properties | cut -d'=' -f 2`
    PROPOSED_VERSION="$HASH_DATE-$LATEST_BRANCH_TAG-$PROJECT_VERSION"
    echo "Checking out source $HASH_DATE with as $hash on $PROPOSED_VERSION"

    git reset --hard $hash > /dev/null 2>&1

    # finaly copy last sonar-project.properties
    cp /tmp/sonar-project.properties ./sonar-project.properties

    STATUS=`git show --oneline -s`
    echo $STATUS

    SONAR_PROJECT_COMMAND="$SONAR_COMMAND -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=600 -Dsonar.projectDate=$HASH_DATE -Dsonar.host.url=$SONAR_SERVER_URL $AUTH -Dsonar.projectVersion=$PROPOSED_VERSION"

    $SONAR_PROJECT_COMMAND #> /dev/null 2>&1
done

git reset --hard $hash > /dev/null 2>&1
SONAR_PROJECT_COMMAND="$SONAR_COMMAND -Dsonar.host.url=$SONAR_SERVER_URL $AUTH -Dsonar.projectVersion=$TIMESTAM-$HASH_TIME"
echo "last hash $hash analyze"
$SONAR_PROJECT_COMMAND

popd
