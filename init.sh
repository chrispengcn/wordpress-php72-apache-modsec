#!/bin/bash
set -e

# 定义统一配置路径
MODSEC_CONF="/etc/modsec/modsecurity.conf"
CRS_SETUP="/etc/modsec/crs-setup.conf"
RULES_DIR="/etc/modsec/rules"

# 生成 ModSecurity 引擎主配置（兼容 ModSecurity 2.9.x，无废弃指令）
cat > "$MODSEC_CONF" << EOF
<IfModule security2_module>
    SecRuleEngine On
    SecRequestBodyAccess On
    SecResponseBodyAccess On

    Include /etc/modsec/crs-setup.conf
    IncludeOptional /etc/modsec/rules/*.conf
</IfModule>
EOF

# 检测CRS规则集，不存在则自动下载官方稳定版 v3.3.4
if [ ! -f "$CRS_SETUP" ] || [ -z "$(ls -A $RULES_DIR 2>/dev/null)" ]; then
    echo "=================================================="
    echo "  ModSecurity 规则未检测到，开始自动下载 OWASP CRS 官方规则集"
    echo "=================================================="

    apt-get update
    apt-get install -y git

    git clone https://github.com/coreruleset/coreruleset.git -b v3.3.4 --depth 1 /tmp/crs
    cp /tmp/crs/crs-setup.conf.example "$CRS_SETUP"
    mkdir -p "$RULES_DIR"
    cp -r /tmp/crs/rules/* "$RULES_DIR"/

    rm -rf /tmp/crs
    apt-get remove -y git
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    echo "=================================================="
    echo "  OWASP CRS 规则集下载完成！"
    echo "=================================================="
else
    echo "=================================================="
    echo "  ModSecurity 规则已存在，跳过自动下载"
    echo "=================================================="
fi

# 配置Apache加载ModSecurity
cat > /etc/apache2/conf-enabled/modsec.conf << EOF
Include /etc/modsec/modsecurity.conf
EOF

# 启动 Apache 前台运行
exec apache2-foreground
