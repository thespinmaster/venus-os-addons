#!/bin/bash

declare log_path=/var/log/opkg-manager/
declare log=$log_path/blind-install.log

if [[ ! -d "$log_path" ]]; then
	mkdir -p "$log_path"
fi

exec > "$log" 2>&1
echo "blind-install opkg-manager"

#if opkg list-installed opkg-manager; then
#  echo "Already installed, nothing to do"
#  exit 0
#fi

echo "Running opkg-manager bind install"

mount -o remount,rw /
/opt/victronenergy/swupdate-scripts/resize2fs.sh

declare opkg_url="https://thespinmaster.github.io/venus-os-addons/feeds/release/opkg-manager/opkg-manager-latest.ipk"

echo "installing- opkg-manager"

opkg install "$opkg_url" && {
  if [[ -f "/data/opkg-manager/source-common" ]]; then
    source "/data/opkg-manager/source-common"
    addsource opkg-common
  else
    echo "opkg-manager shared helpers not found"
    exit 1
  fi

  declare install_conf
  install_conf=$(find /run/media -mindepth 2 -maxdepth 2 -type f \
    -name 'venus-data-opkg-manager-blind-install.conf' -print -quit)

  if [[ -f "$install_conf" ]]; then
    declare -a feed_commands=()
    declare -a package_commands=()

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]]; then
        continue
      fi

      read -r -a tokens <<< "$line"

      case "${tokens[0]}" in
        feed)
          if [[ ${#tokens[@]} -ne 3 ]]; then
            echo "Invalid feed command: $line"
            exit 1
          fi

          feed_commands+=("${tokens[1]}|${tokens[2]}")
          ;;
        package)
          if [[ ${#tokens[@]} -lt 3 ]]; then
            echo "Invalid package command: $line"
            exit 1
          fi

          package_commands+=("$line")
          ;;
        *)
          echo "Unsupported command: $line"
          exit 1
          ;;
      esac
    done < "$install_conf"

    for command in "${feed_commands[@]}"; do
      IFS='|' read -r command_name command_url <<< "$command"

      feed_editor "add" "$command_name" "$command_url"
    done

    opkg update

    for command in "${package_commands[@]}"; do
      read -r -a package_tokens <<< "$command"

      declare package_action="${package_tokens[1]}"
      declare package_name="${package_tokens[$((${#package_tokens[@]} - 1))]}"
      declare -a package_args=()

      if [[ ${#package_tokens[@]} -gt 3 ]]; then
        package_args=("${package_tokens[@]:2:$((${#package_tokens[@]} - 3))}")
      fi

      opkg "$package_action" "${package_args[@]}" "$package_name"
    done
  fi
}


rm -f "${BASH_SOURCE[0]}"
echo "Done"