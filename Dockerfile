FROM timbru31/alpine-java-maven:latest

ENV SONAR_SCANNER_VERSION 4.7.0.2747

RUN apk add dos2unix --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted

RUN apk update && apk upgrade && \
    apk add --no-cache coreutils bash git openssh nodejs npm

# https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-VERFULL-linux.zip
RUN apk add --no-cache wget && \
	mkdir -p -m 777 /sonar-scanner && \
	wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_SCANNER_VERSION.zip -O /sonar-scanner/sonar-scanner.zip && \
	cd /sonar-scanner && \
	unzip -q sonar-scanner.zip && \
	rm sonar-scanner.zip

ENV SONAR_SCANNER_HOME=/sonar-scanner/sonar-scanner-$SONAR_SCANNER_VERSION
ENV PATH $PATH:/sonar-scanner/sonar-scanner-$SONAR_SCANNER_VERSION/bin

RUN mkdir -p /gitrepo
RUN mkdir -p /opt/

ADD ./src/history-analyze.sh /opt/history-analyze.sh

RUN chmod +x /opt/history-analyze.sh

VOLUME /gitrepo

WORKDIR /gitrepo

ENV SONAR_SCANNER_OPTS -Xmx512m 
ENV SONAR_SERVER_URL http://localhost:9000
ENV SONAR_TOKEN ""
ENV START_DATE 0001-01-01
ENV DATE_DIFF_STEP "per-sprint"

CMD /opt/history-analyze.sh
