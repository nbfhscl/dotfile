#!/usr/bin/env bash

JDTLS="${HOME}/.local/share/nvim/lsp_servers/jdtls"

java \
  -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044 \
  -javaagent:"${JDTLS}/lombok.jar" \
  -Xbootclasspath/a:"${JDTLS}/lombok.jar" \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dlog.protocol=true \
  -Dlog.level=ALL \
  -Xms1g \
  -Xmx2G \
  -jar "${JDTLS}/plugins/org.eclipse.equinox.launcher_1.6.400.v20210924-0641.jar" \
  -configuration "${JDTLS}/config_linux" \
  -data "$1" \
  --add-modules=ALL-SYSTEM \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED
