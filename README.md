<h1 align="left">Backup</h1>

###

<p align="left">With this script, you can backup important information such as database from the x-ui, marzban, and hiddify panels and send it to FTP server with so that it is always available!</p>
<p align="left">
  this is a variant of <a href="https://github.com/AC-Lover/backup">Ac-backup</a> script for those who have a panel on iran servers and also have host accessible from iran which helps bypass accessibility limits of telegram bot.
</p>



###

<h1 align="left">How does it work</h1>

###

<p align="left">First you need to create a FTP account on your host and then run this command on your server</p> 


```bash
bash <(curl -Ls https://raw.githubusercontent.com/fng713/backup/main/backup.sh)
```
###

<p align="left">next simply enter your FTP host, username, password, port(if it is default port 21 enter to skip) and path (you must create the path on your server or just enter / to send backup to your FTP acount root path) for cronjob setting and panel selection follow the below instructions.</p>

###
<h3 align="left"> Cronjob setting</h3>

###

<p align="left">The next step asks you to run a cron job to determine when the robot will back up and send<br>whose format is like this:<br>0 1<br>The first value, which is 0, is the minute, and the second value, which is 1, is the hour<br>The minimum number for minutes is 0 and the maximum is 60<br>The minimum number for the hour is 0 and the maximum is 24<br>Enter 0 for both to set backup once every minute<br>In the example above, it is backed up once every hour<br>Note that there is a space between both values</p>

###

<h3 align="left"> Panel selection</h3>

###

<p align="left">The next step will ask you which panel you want to backup<br>You have to choose one from marzbn, x-ui, and hiddify <br>The value of m means marzban, the value of x means x-ui, and the value of h means hiddify <br>Enter an option between x/m/h as per your requirement</p>

###

<h3 align="left"> question of removing previous crown jobs</h3>

###

<p align="left">Then it will ask you if you want to delete the previously defined cron jobs or not?<br>Enter y if you want it to be cleared otherwise enter n</p>

