#!/bin/bash

# Function to check if a variable is a number
is_number() {
  [[ $1 =~ ^[0-9]+$ ]]
}

# Prompt for FTP details with validation
while true; do
  read -p "Enter FTP host: " FTP_HOST
  if [ -n "$FTP_HOST" ]; then
    break
  else
    echo "FTP host cannot be empty. Please enter a valid FTP host."
  fi
done

while true; do
  read -p "Enter FTP username: " FTP_USER
  if [ -n "$FTP_USER" ]; then
    break
  else
    echo "FTP username cannot be empty. Please enter a valid FTP username."
  fi
done

while true; do
  read -sp "Enter FTP password: " FTP_PASS
  echo
  if [ -n "$FTP_PASS" ]; then
    break
  else
    echo "FTP password cannot be empty. Please enter a valid FTP password."
  fi
done

while true; do
  read -p "Enter FTP port (default 21): " FTP_PORT
  FTP_PORT=${FTP_PORT:-21}
  if is_number "$FTP_PORT"; then
    break
  else
    echo "FTP port must be a number. Please enter a valid port."
  fi
done

while true; do
  read -p "Enter FTP path (e.g., /path/to/ftp/backup/): " FTP_PATH
  if [ -n "$FTP_PATH" ]; then
    break
  else
    echo "FTP path cannot be empty. Please enter a valid FTP path."
  fi
done


# Cronjob
# تعیین زمانی برای اجرای این اسکریپت به صورت دوره‌ای
while true; do
    echo "Cronjob (minutes and hours) (e.g : 30 6 or 0 12) : "
    read -r minute hour
    if [[ $minute == 0 ]] && [[ $hour == 0 ]]; then
        cron_time="* * * * *"
        break
    elif [[ $minute == 0 ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]]; then
        cron_time="0 */${hour} * * *"
        break
    elif [[ $hour == 0 ]] && [[ $minute =~ ^[0-9]+$ ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} * * * *"
        break
    elif [[ $minute =~ ^[0-9]+$ ]] && [[ $hour =~ ^[0-9]+$ ]] && [[ $hour -lt 24 ]] && [[ $minute -lt 60 ]]; then
        cron_time="*/${minute} */${hour} * * *"
        break
    else
        echo "Invalid input, please enter a valid cronjob format (minutes and hours, e.g: 0 6 or 30 12)"
    fi
done


# x-ui or marzban or hiddify
# گرفتن نوع نرم افزاری که می‌خواهیم پشتیبانی از آن بگیریم و ذخیره آن در متغیر xmh
while [[ -z "$xmh" ]]; do
    echo "x-ui or marzban or hiddify? [x/m/h] : "
    read -r xmh
    if [[ $xmh == $'\0' ]]; then
        echo "Invalid input. Please choose x, m or h."
        unset xmh
    elif [[ ! $xmh =~ ^[xmh]$ ]]; then
        echo "${xmh} is not a valid option. Please choose x, m or h."
        unset xmh
    fi
done

while [[ -z "$crontabs" ]]; do
    echo "Would you like the previous crontabs to be cleared? [y/n] : "
    read -r crontabs
    if [[ $crontabs == $'\0' ]]; then
        echo "Invalid input. Please choose y or n."
        unset crontabs
    elif [[ ! $crontabs =~ ^[yn]$ ]]; then
        echo "${crontabs} is not a valid option. Please choose y or n."
        unset crontabs
    fi
done

if [[ "$crontabs" == "y" ]]; then
# remove cronjobs
sudo crontab -l | grep -vE '/root/backup.+\.sh' | crontab -
fi


# m backup
# ساخت فایل پشتیبانی برای نرم‌افزار Marzban و ذخیره آن در فایل backup.zip
if [[ "$xmh" == "m" ]]; then

if dir=$(find /opt /root -type d -iname "marzban" -print -quit); then
  echo "The folder exists at $dir"
else
  echo "The folder does not exist."
  exit 1
fi

if [ -d "/var/lib/marzban/mysql" ]; then

  sed -i -e 's/\s*=\s*/=/' -e 's/\s*:\s*/:/' -e 's/^\s*//' /opt/marzban/.env

  docker exec marzban-mysql-1 bash -c "mkdir -p /var/lib/mysql/db-backup"
  source /opt/marzban/.env

    cat > "/var/lib/marzban/mysql/backup.sh" <<EOL
#!/bin/bash

USER="root"
PASSWORD="$MYSQL_ROOT_PASSWORD"


databases=\$(mysql -h 127.0.0.1 --user=\$USER --password=\$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database)

for db in \$databases; do
    if [[ "\$db" != "information_schema" ]] && [[ "\$db" != "mysql" ]] && [[ "\$db" != "performance_schema" ]] && [[ "\$db" != "sys" ]] ; then
        echo "Dumping database: \$db"
		mysqldump -h 127.0.0.1 --force --opt --user=\$USER --password=\$PASSWORD --databases \$db > /var/lib/mysql/db-backup/\$db.sql

    fi
done

EOL
chmod +x /var/lib/marzban/mysql/backup.sh

ZIP=$(cat <<EOF
docker exec marzban-mysql-1 bash -c "/var/lib/mysql/backup.sh"
zip -r /root/backup-m.zip /opt/marzban/* /var/lib/marzban/* /opt/marzban/.env -x /var/lib/marzban/mysql/\*
zip -r /root/backup-m.zip /var/lib/marzban/mysql/db-backup/*
rm -rf /var/lib/marzban/mysql/db-backup/*
EOF
)

    else
      ZIP="zip -r /root/backup-m.zip ${dir}/* /var/lib/marzban/* /opt/marzban/.env"
fi


# x-ui backup
# ساخت فایل پشتیبانی برای نرم‌افزار X-UI و ذخیره آن در فایل backup.zip
elif [[ "$xmh" == "x" ]]; then

if dbDir=$(find /etc /opt/freedom -type d -iname "x-ui*" -print -quit); then
  echo "The folder exists at $dbDir"
  if [[ $dbDir == *"/opt/freedom/x-ui"* ]]; then
     dbDir="${dbDir}/db/"
  fi
else
  echo "The folder does not exist."
  exit 1
fi

if configDir=$(find /usr/local -type d -iname "x-ui*" -print -quit); then
  echo "The folder exists at $configDir"
else
  echo "The folder does not exist."
  exit 1
fi

ZIP="zip /root/backup-x.zip ${dbDir}/x-ui.db ${configDir}/config.json"

# hiddify backup
# ساخت فایل پشتیبانی برای نرم‌افزار Hiddify و ذخیره آن در فایل backup.zip
elif [[ "$xmh" == "h" ]]; then

if ! find /opt/hiddify-manager/hiddify-panel/ -type d -iname "backup" -print -quit; then
  echo "The folder does not exist."
  exit 1
fi

ZIP=$(cat <<EOF
cd /opt/hiddify-manager/hiddify-panel/
if [ $(find /opt/hiddify-manager/hiddify-panel/backup -type f | wc -l) -gt 100 ]; then
  find /opt/hiddify-manager/hiddify-panel/backup -type f -delete
fi
python3 -m hiddifypanel backup
cd /opt/hiddify-manager/hiddify-panel/backup
latest_file=\$(ls -t *.json | head -n1)
rm -f /root/backup-h.zip
zip /root/backup-h.zip /opt/hiddify-manager/hiddify-panel/backup/\$latest_file

EOF
)
else
echo "Please choose m or x or h only !"
exit 1
fi


trim() {
    # remove leading and trailing whitespace/lines
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

COMMENT="Backup created on $(date +'%Y-%m-%d_%H-%M-%S') for server with ${IP} address"
comment=$(trim "$comment")

# install zip
sudo apt install zip -y

#install lftp
sudo apt install lftp

# send backup to ftp server
cat > "/root/backup-${xmh}.sh" <<EOL
rm -rf /root/backup-${xmh}.zip
$ZIP
echo -e "$comment" | zip -z /root/backup-${xmh}.zip
lftp -u $FTP_USER,$FTP_PASS -e "set ftp:ssl-allow no;lcd /root;cd $FTP_PATH;put backup-${xmh}.zip;bye;" $FTP_HOST
EOL


# Add cronjob
# افزودن کرانجاب جدید برای اجرای دوره‌ای این اسکریپت
{ crontab -l -u root; echo "${cron_time} /bin/bash /root/backup-${xmh}.sh >/dev/null 2>&1"; } | crontab -u root -

# run the script
# اجرای این اسکریپت
bash "/root/backup-${xmh}.sh"

# Done
# پایان اجرای اسکریپت
echo -e "\nBackup created, uploaded to FTP successfully!\n"
