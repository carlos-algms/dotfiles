alias to-www="cd /var/www"

alias to-ng-sites-available="cd /etc/nginx/sites-available"
alias ng-restart="sudo systemctl restart nginx.service"
alias ng-stop="sudo service nginx stop"

alias to-a2-sites-available="cd /etc/apache2/sites-available"
alias a2-restart="sudo service apache2 restart"
alias a2-stop="sudo service apache2 stop"

alias php5-restart="sudo systemctl restart php5.6-fpm.service"
alias php7-restart="sudo systemctl restart php7.1-fpm.service"
alias php-restart="sudo systemctl restart php5.6-fpm.service php7.1-fpm.service"

alias restart-http-server="sudo systemctl restart nginx.service php7.0-fpm.service php5.6-fpm.service"
