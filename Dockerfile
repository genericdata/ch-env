FROM centos:centos8.2.2004

ENV APPS_ROOT /apps
RUN mkdir -p ${APPS_ROOT}

#########################################################################################
#- Java JDK (1.8.0_271): https://www.oracle.com/java/technologies/javase/javase-jdk8-downloads.html
COPY jdk-8u271-linux-x64.rpm /tmp/jdk-8u271-linux-x64.rpm
RUN yum -y localinstall /tmp/jdk-8u271-linux-x64.rpm \
  && rm /tmp/jdk-8u271-linux-x64.rpm \
  && dnf -y clean all

#########################################################################################
#- Perl (5.32.0)
#- Perl module XML::Simple (version 2.25)
ENV PERL_VERSION 5.32.0
ENV XMLSIMPLE_VERSION 2.25
RUN dnf -y install \
  make \
  gcc \
  expat-devel \
  && dnf -y clean all \
  && curl -sSL https://www.cpan.org/src/5.0/perl-${PERL_VERSION}.tar.gz | tar xz \
  && cd perl-${PERL_VERSION} \
  && ./Configure -de \
  && make -j \
  && make install \
  && curl -L https://cpanmin.us | perl - App::cpanminus \
  && cpanm install GRANTM/XML-Simple-${XMLSIMPLE_VERSION}.tar.gz \
  && rm -Rf /perl-${PERL_VERSION}

#########################################################################################
#CONDA
ENV MINICONDA_HOME ${APPS_ROOT}/miniconda
ENV PATH $PATH:${MINICONDA_HOME}/bin
RUN curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh --output ~/miniconda.sh \
  && bash ~/miniconda.sh -b -p ${MINICONDA_HOME} \
  && rm -f ~/miniconda.sh \
  && eval "$(${APPS_ROOT}/miniconda/bin/conda shell.bash hook)" \
  && conda config --add channels bioconda --add channels conda-forge \
  && conda install -yq mamba \
  && echo '. ${APPS_ROOT}/miniconda/etc/profile.d/conda.sh' >> /etc/profile.d/miniconda.sh

#- Install Apps
RUN mamba install -yq python==3.8.6 \
  snakemake==5.31.1 \
  trim-galore==0.6.6 \
  cutadapt==3.1 \
  fastqc==0.11.9 \
  bowtie2==2.4.2 \
  minimap2==2.17 \
  samtools==1.11 \
  macs2==2.2.7.1 \
  bedtools==2.29.2 \
  && mamba clean -afy

#########################################################################################
#- GEM (version 3.3): https://groups.csail.mit.edu/cgs/gem/versions.html
# example: java -Xmx10G -jar $GEM_JAR --d Read_Distribution_default.txt --g mm8.chrom.sizes --genome your_path/mm8 --s 2000000000 --expt SRX000540_mES_CTCF.bed --ctrl SRX000543_mES_GFP.bed --f BED --out mouseCTCF --k_min 6 --k_max 13
ENV GEM_VERSION 3.3
ENV GEM_HOME ${APPS_ROOT}/gem/${GEM_VERSION}
ENV GEM_JAR ${GEM_HOME}/gem.jar
RUN mkdir -p ${APPS_ROOT}/gem \
  && curl -sSL https://groups.csail.mit.edu/cgs/gem/download/gem.v${GEM_VERSION}.tar.gz \
  | tar xz \
  && mv gem ${GEM_HOME}

#########################################################################################
#- MEME (version 5.3.0 - MPI): http://meme-suite.org/doc/download.html
ENV MEME_VERSION 5.3.0
ENV MEME_HOME ${APPS_ROOT}/meme/${MEME_VERSION}
ENV PATH ${MEME_HOME}/bin:${MEME_HOME}/libexec/meme-${MEME_VERSION}:$PATH
#------Prerequisite Software----------
RUN dnf --enablerepo=PowerTools install -y ghostscript \
  make \
  openmpi \
  openmpi-devel \
  zlib-devel \
  libxml2-devel \
  which \
  && dnf -y clean all \
  && cpanm install \
    File::Which \
    HTML::Template \
    HTML::TreeBuilder \
    JSON \
    Log::Log4perl \
    Math::CDF \
    XML::Compile::SOAP11 \
    XML::Compile::WSDL11 \
    XML::Compile::Transport::SOAPHTTP

ENV PATH /usr/lib64/openmpi/bin:$PATH
ENV LD_LIBRARY_PATH /usr/lib64/openmpi/lib:$LD_LIBRARY_PATH
#------------------------------------
RUN mkdir -p ${APPS_ROOT}/meme \
  && curl -sSL http://meme-suite.org/meme-software/${MEME_VERSION}/meme-${MEME_VERSION}.tar.gz | tar xz \
  && cd meme-${MEME_VERSION} \
  && ./configure --prefix=${MEME_HOME} --enable-build-libxml2 --enable-build-libxslt --with-url=http://meme-suite.org \
  && make -j \
  && make install \
  && rm -Rf /meme-${MEME_VERSION}

#########################################################################################
#- SRA-TOOLS (version 2.10.9)
ENV SRATOOLS_VERSION 2.10.9
ENV SRATOOLS_HOME ${APPS_ROOT}/sratools/${SRATOOLS_VERSION}
ENV PATH ${SRATOOLS_HOME}/bin:$PATH

RUN mkdir -p ${APPS_ROOT}/sratools \
  && curl -sSL https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${SRATOOLS_VERSION}/sratoolkit.${SRATOOLS_VERSION}-centos_linux64.tar.gz \
  | tar xz \
  && mv sratoolkit.${SRATOOLS_VERSION}-centos_linux64 ${SRATOOLS_HOME}
