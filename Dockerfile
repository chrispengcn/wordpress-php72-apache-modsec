
# 基础镜像 WordPress PHP8.2 Apache
# 如需切换 PHP7.2 直接修改为 FROM wordpress:php7.2-apache 即可全部通用
FROM wordpress:php8.2-apache

# 安装 mod_security 模块
RUN apt-get update && \
    apt-get install -y --no-install-recommends libapache2-mod-security2 && \
    a2enmod security2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建统一 ModSecurity 配置目录
RUN mkdir -p /etc/modsec/rules && \
    chown -R www-data:www-data /etc/modsec

# 解决 Apache ServerName 警告
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# 复制启动初始化脚本
COPY init.sh /init.sh
RUN chmod +x /init.sh

EXPOSE 80

# 容器启动入口
CMD ["/init.sh"]
