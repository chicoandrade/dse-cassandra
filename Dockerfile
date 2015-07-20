FROM debian:jessie

#Original dockerfile from Suresh Khatri, kc2005au@gmail.com
MAINTAINER Francisco Andrade, fjandrade15@gmail.com

RUN apt-get update
RUN apt-get install -y git ack-grep vim curl wget tmux build-essential unzip python-software-properties

RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list
RUN echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886
RUN apt-get update
RUN apt-get -y upgrade

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get -y --force-yes=true install oracle-java8-installer
RUN update-alternatives --display java 
RUN apt-get clean

ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV DSE_VERSION dse-4.7.0
ENV DSE_FILE $DSE_VERSION-bin.tar.gz
ENV DSE_DIR /opt/cassandra
ENV DSE_HOME $DSE_DIR/datastax/$DSE_VERSION
ENV PATH $JAVA_HOME/bin:$DSE_HOME/bin:$PATH

#Put your datastax registration info here.
#Either get from Datastax
#RUN wget http://user:password@downloads.datastax.com/enterprise/$DSE_FILE -O /tmp/$DSE_FILE
#Use local server to work with already downloaded dse
#RUN wget http://10.1.1.19:8900/$DSE_FILE -O /tmp/$DSE_FILE

COPY $DSE_FILE /tmp/

RUN /bin/mkdir -p $DSE_DIR/datastax
RUN cd $DSE_DIR/datastax && /bin/tar zxf /tmp/$DSE_FILE

COPY cassandra.yaml $DSE_HOME/resources/cassandra/conf/template.yaml
##RUN cat $DSE_HOME/resources/cassandra/conf/template.yaml > $DSE_HOME/resources/cassandra/conf/cassandra.yaml
##RUN cat $DSE_HOME/resources/cassandra/conf/lib.txt >> $DSE_HOME/resources/cassandra/conf/cassandra.yaml
COPY entrypoint.sh $DSE_HOME/resources/cassandra/conf/

RUN rm -rf /tmp/$DSE_FILE

EXPOSE 9042 9160 7199 7000

CMD ["$DSE_HOME/resources/cassandra/conf/entrypoint.sh"]
