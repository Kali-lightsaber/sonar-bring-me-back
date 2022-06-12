#!/bin/bash

# script based on https://gist.github.com/aslakknutsen/2422117

GIT_REPO=/gitrepo
#START_DATE=$1 //TODO i want all history, but some reason it seem to useful

ls -al /gitrepo
git --version

#SONAR_SCANNER_OPTS+=" -XX:+UseG1GC -XX:MaxGCPauseMillis=200"
#echo $SONAR_SCANNER_OPTS

#MVN_COMMAND="mvn clean install"
#SONAR_COMMAND="mvn org.codehaus.sonar:sonar-maven3-plugin:3.3.0.603:sonar"
SONAR_COMMAND="sonar-scanner"

if [ -z "$START_DATE" ]; then
    LASTDATE="0001-01-01"
    echo "Missing program argument: start-date"
    echo "Analyze wil start from first commit of branch"
else
    LASTDATE=$START_DATE
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
  echo "you didnot provide correct git repo"
  exit 42 # "why 42 ? please googl it as an answer"
fi

cp -ar /gitrepo /tmp/gitrepo
cp /gitrepo/sonar-project.properties /tmp/sonar-project.properties || \
  { echo "You need to create sonar-projects.properties file"; exit 42;}

dos2unix /tmp/sonar-project.properties

pushd /tmp/gitrepo

git clean -df

for hash in `git --no-pager log --reverse --pretty=format:%h`
do
    #T03:00:00+0300
    HASH_DATE=`git show $hash --date=iso | grep Date: -m1 | cut -d' ' -f 4`
    HASH_TIME=`git show $hash --date=iso | grep Date: -m1 | cut -d' ' -f 5`

    if [[ "$HASH_DATE" > "$LASTDATE" ]] ;
    then
      echo "New commit in new date $HASH_DATE"
      LASTDATE=$HASH_DATE 
    else
      echo "Hash $hash skiped $HASH_DATE"
      continue
    fi
    
    TIMESTAMP=`grep sonar.projectVersion /tmp/sonar-project.properties | cut -d'=' -f 2`

    echo "Checking out source $HASH_DATE with as $hash on $TIMESTAMP-$HASH_TIME"

    git reset --hard $hash > /dev/null 2>&1

    # finaly copy last sonar-project.properties
    cp /tmp/sonar-project.properties ./sonar-project.properties

    # this will not working on latest git
    # see https://stackoverflow.com/questions/4114095/how-to-revert-git-repository-to-a-previous-commit
    #git checkout $hash  > /dev/null 2>&1
    #git clean -df > /dev/null 2>&1

    STATUS=`git show --oneline -s`
    echo $STATUS

    SONAR_PROJECT_COMMAND="$SONAR_COMMAND -Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=600000 -Dsonar.projectDate=$HASH_DATE -Dsonar.host.url=$SONAR_SERVER_URL $AUTH -Dsonar.projectVersion=$TIMESTAM-$HASH_TIME"

    #echo "Executing Maven: $MVN_COMMAND"
    #$MVN_COMMAND > /dev/null 2>&1
    #echo "Executing Sonar: $SONAR_PROJECT_COMMAND"
    #$SONAR_PROJECT_COMMAND || exit 42 #> /dev/null 2>&1
    $SONAR_PROJECT_COMMAND #> /dev/null 2>&1
done

git reset --hard $hash > /dev/null 2>&1
SONAR_PROJECT_COMMAND="$SONAR_COMMAND -Dsonar.host.url=$SONAR_SERVER_URL $AUTH -Dsonar.projectVersion=$TIMESTAM-$HASH_TIME"
echo "last hash $hash analyze"
$SONAR_PROJECT_COMMAND

popd
