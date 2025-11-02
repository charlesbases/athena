#!/bin/bash

set -e

config="$HOME/.ssh/config"

# 可添加额外的 config 字段。
# 若要添加自定义字段，以 Password 为例。
#   1. title 中添加 'PASSWORD'
#   2. config 中添加 '# Password'
#   注意：Password 不是 config 所支持的字段，所以必须使用注释，否则执行 ssh 时会报错
#
#Host localhost
#  HostName 127.0.0.1
#  User root
#  Port 22
#  # PASSWORD 1qaz!QAZ
title="SN HOST HOSTNAME PORT USER PASSWORD PROXYJUMP DESCRIPTION"

help() {
  echo "Usage: $0 [command]"
  echo ""
  echo "Commands:"
  echo "  (none)       Display SSH configurations and prompt for connection"
  echo "  edit         Edit SSH configuration file"
  echo "  ssh-copy     Display SSH configurations and copy public key to target host"
  echo "  help, -h     Show this help message"
}

example() {
  cat > $config << EOF
# Host localhost
  # HostName 127.0.0.1
  # User root
  # Port 22
  # Password 123456
  # Description description
  # Compression yes
  # TCPKeepAlive yes
  # ConnectTimeout 3
  # ServerAliveCountMax 3
  # ServerAliveInterval 60
  # IdentityFile ~/.ssh/id_rsa
  # PreferredAuthentications publickey
  # ForwardAgent yes
  # ProxyJump license-tes
EOF
}

display() {
  {
    echo "$title"
    echo "$title" | awk '{for(i=1;i<=NF;i++){for(j=1;j<=length($i);j++)printf "-";if(i<NF)printf " "};print ""}'
    awk -v title="$title" '
    BEGIN {
      n = split(title, headers, " ")
      for (i = 2; i <= n; i++) headers_lower[i] = tolower(headers[i])
      c = 1
    }
    /^Host / {
      if (c > 1) {
        printf "%d.", c-1
        for (i = 2; i <= n; i++) printf " %s", (headers_lower[i] in fields ? fields[headers_lower[i]] : "-")
        print ""
      }
      delete fields
      fields["host"] = $2
      c++
      next
    }
    /^[[:space:]]+[#]?[[:space:]]*[A-Za-z]+[[:space:]]/ {
      line = $0
      gsub(/^[[:space:]]+[#]?[[:space:]]*/, "", line)
      split(line, parts, /[[:space:]]+/)
      key = tolower(parts[1])
      fields[key] = parts[2]
    }
    END {
      if (c > 1) {
        printf "%d.", c-1
        for (i = 2; i <= n; i++) printf " %s", (headers_lower[i] in fields ? fields[headers_lower[i]] : "-")
        print ""
      }
    }
    ' "$config"
  } | column -t
}

sshconn() {
  local selection=$1
  [[ -z $selection ]] && read -p "Please enter sn: " selection
  [[ ! $selection =~ ^[0-9]+$ ]] && { echo "ssh: name or service not known" >&2; return 1; }

  local host=$(awk '/^Host / {print $2}' "$config" | sed -n "${selection}p")

  [[ -z $host ]] && { echo "ssh: name or service not known" >&2; return 1; }
  echo && ssh "$host"
}

sshcopy() {
  local selection=$1
  [[ -z $selection ]] && read -p "Please enter sn: " selection
  [[ ! $selection =~ ^[0-9]+$ ]] && { echo "ssh-copy-id: name or service not known" >&2; return 1; }

  local entry=$(awk -v sel="$selection" '/^Host / {c++} c==sel && c && !/^Host / {print; next} c==sel && /^Host / {print; next}' "$config")
  [[ -z $entry ]] && { echo "ssh-copy-id: name or service not known" >&2; return 1; }

  local host=$(echo "$entry" | awk '/^Host / {print $2}')
  local hostname=$(echo "$entry" | awk '/^[[:space:]]+HostName[[:space:]]/ {print $2}')
  local port=$(echo "$entry" | awk '/^[[:space:]]+Port[[:space:]]/ {print $2}')
  local user=$(echo "$entry" | awk '/^[[:space:]]+User[[:space:]]/ {print $2}')
  local identity=$(echo "$entry" | awk '/^[[:space:]]+IdentityFile[[:space:]]/ {print $2}')
  local proxyjump=$(echo "$entry" | awk '/^[[:space:]]+ProxyJump[[:space:]]/ {print $2}')

  [[ -z $identity ]] && { echo "ssh-copy-id: no such file or directory" >&2; return 1; }

  local proxy_opts=""

  # 如果有ProxyJump，先复制公钥到跳板机
  if [[ -n $proxyjump ]]; then
    echo -e "\033[32mCopying public key to: $proxyjump\033[0m"
    eval "ssh-copy-id -i $identity $proxyjump" || { return 1; }
    # 设置ProxyJump选项
    proxy_opts="-o ProxyJump=$proxyjump"
  fi

  echo -e "\033[32mCopying public key to: $user@$hostname\033[0m"
  eval "ssh-copy-id -i $identity ${port:+-p $port} $proxy_opts $user@$hostname"
}

main() {
  case $1 in
    "")
      display
      sshconn
      ;;
    edit)
      case "$(uname -s)" in
        Linux*)  vi "$config" ;;
        Darwin*) open "$config" ;;
        CYGWIN*|MINGW*|MSYS*) start "$config" ;;
        *) echo "unsupported: $(uname -s)" ;;
      esac
      ;;
    ssh-copy)
      display
      sshcopy
      ;;
    help|-h)
      help
      ;;
    *)
      echo "$0: '$1' is not a command. See '$0 -h'"
      exit 1
      ;;
  esac
}

# config 文件不存在则创建
[[ ! -f "$config" ]] && example

# 执行主函数
main "$@"
