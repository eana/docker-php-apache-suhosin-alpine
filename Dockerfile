FROM php:5.6-alpine
LABEL \
    description="PHP 5.6 with Apache 2.4 on top of Alpine"

# Check latest stable version here: https://suhosin.org/stories/download.html
ENV SUHOSIN_VERSION 0.9.38

RUN set -xe && \
    apk add --update --no-cache \
        ffmpeg \
        apache2 \
        apache2-utils \
        php5-apache2 \
        php5-mysql \
        php5-mysqli \
        php5-pear \
        php5-cgi \
        php5-curl \
        php5-fpm \
        php5-gd \
        php5-imagick \
        php5-imap \
        php5-intl \
        php5-json \
        php5-mcrypt \
        php5-exif && \

    apk add --update --no-cache --virtual .build-deps \
        libpng-dev \
        zlib-dev \
        libjpeg-turbo-dev \
        ffmpeg-dev \
        php5-dev \
        binutils \
        cmake \
        git \
        autoconf \
        build-base \
        openssl && \

	sed '/^disable_functions =/ s/$/ apache_child_terminate,apache_setenv,curl_multi_exec,define_syslog_variables,dl,escapeshellarg,escapeshellcmd,eval,exec,fp,fput,ftp_connect,ftp_exec,ftp_get,ftp_login,ftp_nb_fput,ftp_put,ftp_raw,ftp_rawlist,highlight_file,ini_alter,ini_get_all,ini_restore,inject_code,mysql_pconnect,openlog,parse_ini_file,passthru,pcntl_alarm,pcntl_exec,pcntl_fork,pcntl_get_last_error,pcntl_getpriority,pcntl_setpriority,pcntl_signal,pcntl_signal_dispatch,pcntl_sigprocmask,pcntl_sigtimedwait,pcntl_sigwaitinfo,pcntl_strerror,pcntl_wait,pcntl_waitpid,pcntl_wexitstatus,pcntl_wifexited,pcntl_wifsignaled,pcntl_wifstopped,pcntl_wstopsig,pcntl_wtermsig,phpAds_remoteInfo,phpAds_XmlRpc,phpAds_xmlrpcDecode,phpAds_xmlrpcEncode,phpcredits,php_ini_scanned_files,php_uname,popen,posix_getpwuid,posix_kill,posix_mkfifo,posix_setpgid,posix_setsid,posix_setuid,posix_uname,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,symlink,syslog,system,url_fopen,virtual,/' -i /etc/php5/php.ini && \

    git clone https://github.com/dirkvdb/ffmpegthumbnailer.git /root/ffmpegthumbnailer && \
    cd /root/ffmpegthumbnailer && \
    cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_GIO=ON -DENABLE_THUMBNAILER=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON . && \
    make && \
    make install && \

    git clone https://github.com/tony2001/ffmpeg-php.git /root/ffmpeg-php && \
    cd /root/ffmpeg-php && \
    phpize && \
    ./configure && \
    make && \
    cp modules/ffmpeg.so /usr/lib/php5/modules/ && \
    echo "extension=ffmpeg.so" > /etc/php5/conf.d/ffmpeg.ini && \

    wget https://download.suhosin.org/suhosin-$SUHOSIN_VERSION.tar.gz -P /root && \
    tar xvfz /root/suhosin-$SUHOSIN_VERSION.tar.gz -C /root && \
    cd /root/suhosin-$SUHOSIN_VERSION && \
    # Alpine linux has flock() stuff in file.h
    sed -i '1i#include <sys/file.h>' log.c && \
    phpize && \
    ./configure && \
    make && \
    cp modules/suhosin.so /usr/lib/php5/modules/ && \
    echo -e "extension=suhosin.so\nsuhosin.executor.disable_eval = On" > /etc/php5/conf.d/suhosin.ini && \

    rm -fr /root/ffmpegthumbnailer && \
    rm -rf /root/ffmpeg-php && \
    rm /root/suhosin-$SUHOSIN_VERSION.tar.gz && \
    rm -rf /root/suhosin-$SUHOSIN_VERSION && \

    apk del .build-deps

RUN mkdir -p /run/apache2

CMD ["apachectl", "-D", "FOREGROUND"]
