## Analyze history of git repo with SonarQube 

**if you start use SonarQube for your git repo yo may want to load your tech debt from first commit to current date**

> install docker https://docs.docker.com/get-docker/ and `make+git+bash` on each platform Linux or Windows

## Run Workflow

* run `make prepare` - it create directory `./gitrepos/` for repos you want to scan
* run `make build` - it build sonar-scanner image with sh script for commit hash switch
* clone your repo `git clone <git@some.url/somename> ./gitrepos/<somename>`
* create env file based on example `cp ./.env.example ./.env`
```
SONAR_SCANNER_OPTS=-Xmx512m             # https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/
SONAR_SERVER_URL=http://localhost:9000  # <your-sonarserver-url>
SONAR_TOKEN=                            # <yourapitoken>
START_DATE=0001-01-01                   # start date for history import

#(per-year|per-half-year|per-quarter|per-month|per-sprint|per-week|per-day)
DATE_DIFF_STEP="per-day"                # step between history walker
```
* edit env file (you must add sonar host url, starting date for history and sonar-apitoken) and if you wish - you may skip history per week, per month
* run `make run` - it start analize your history of each repo in `./gitrepos/*`

### Behavior

* we build [Docker image](./Dockerfile) with latest sonar-scanner standalone cli 
* entrypoint of an image is a [bash script](./src/history-analyze.sh) which walk throuth commits and start analyze source code
* it switch each `commit-hash` on current cloned `branch`
* then it start sonar-scan with some behavior
  * parse `sonar-project.properties` to find `$PROJECTVERSION`
  * and create version template `-Dsonar.project.version=$DATE-$TAG-$PROJECTVERSION`
* then analize `commit-hash` with `-Dsonar.qualitygate.wait=true -Dsonar.qualitygate.timeout=600`
* and then find next date of commit by the rule `NEXT_DATE=date '+%C%y%m%d' -d "+X yeer/month/etc"` (please see the **DATE_DIFF_STEP** param)

## Trobleshoting and Debug

if you want debug run you must run docker command (dont forgent run `make prepera && make build` before it)

* **Linux** `docker run -it --rm --env-file=.env -v "$PWD/gitrepos/<ouroldrepo>":/gitrepo local-sonar-history-runner`
* **Windows** create `bat` file with this content
```
set CURPWD=%cd%
set CURPWD=%CURPWD:\=/%

docker run -it --rm --env-file=.env -v "%CURPWD%gitrepos/<ouroldrepo>":/gitrepo local-sonar-history-runner
```
and run it

> note: on docker for windows there is strange behavior with mount localdrive with PWD command, thats why run command so strange

## Debug run for latest version

* run `make prepera && make build`
* enter to container bash `docker run -it --rm --env-file=.env -v "$PWD/gitrepos/<ouroldrepo>":/gitrepo local-sonar-history-runner bash`
* run `sonar-runner` command

## Tech info

* we use an docker image with jdk11, maven and nodejs with sonar-scanner installation
* we use additional parameter `-Dsonar.projectDate=` to bring you in history

## Useful link

* simple example by tags https://gist.github.com/aslakknutsen/2422117
* official docs for scanner https://docs.sonarqube.org/display/SCAN/Analyzing+with+SonarQube+Scanner
* advanced usage of sonar scaner https://docs.sonarqube.org/display/SCAN/Advanced+SonarQube+Scanner+Usages

### Limitation

if you have many revision in one day - you may see analyze error on sonarqube with this content

```
Validation of project failed:
  o Date of analysis cannot be older than the date of the last known analysis on this project. Value: 
```

this is not bug, this is a limitation of sonar.projectDate parameter - you may set only date, not time in this parameter  

### For Russian Users

Данный проект реализован для "ввода остатков" технического долга на основе вашего git репозитория и используется в следующих кейсах

#### Для 1С и SonarQube

* Вы используйте gitsync - https://github.com/oscript-library/gitsync
* Вам нужно проанализировать историю вашего кода с момента использования Git для 1С

#### Для других языков

* Вы использовали GIT
* Вы только недавно прочитали статью про SonarQube
* Вы решили ввести остатки своего технического долга

[Проект реанимирован и развивается только благодаря подписчикам](https://boosty.to/ineedlustin)
