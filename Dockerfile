FROM nginx:latest

LABEL maintainer="Evangelos Pistolas"

RUN apt update && apt-get install -y apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
RUN cd ModSecurity && git submodule init && git submodule update && ./build.sh && ./configure && make && make install
RUN cd ..

#ARG NGINX_VERSION = ${nginx -v 2>&1 | awk -F/ '{print $2}'}
ARG NGINX_VERSION=1.21.1
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz
RUN cd nginx-${NGINX_VERSION} && ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && make modules && cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules
RUN cd ..

RUN sed -i '1s/^/load_module modules\/ngx_http_modsecurity_module.so; /' /etc/nginx/nginx.conf
RUN mkdir /etc/nginx/modsec && wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended && mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf && cp ModSecurity/unicode.mapping /etc/nginx/modsec 
RUN sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf

RUN git clone https://github.com/sullo/nikto && cd nikto && perl program/nikto.pl -h localhost && touch /etc/nginx/modsec/main.conf
RUN wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v3.0.2.tar.gz && tar -xzvf v3.0.2.tar.gz && mv owasp-modsecurity-crs-3.0.2 /usr/local && cd /usr/local/owasp-modsecurity-crs-3.0.2 sudo cp crs-setup.conf.example crs-setup.conf
#RUN sed -e '/Include \/usr\/local\/owasp-modsecurity-crs-3.0.2\/rules\/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf/s/^/#/' /etc/nginx/modsec/main.conf
#RUN sed -e '/Include \/usr\/local\/owasp-modsecurity-crs-3.0.2\/rules\/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf/s/^/#/' /etc/nginx/modsec/main.conf
RUN apt-get install nano

#CMD ["nginx", "-g", "daemon off;"]