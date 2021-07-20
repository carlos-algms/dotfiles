enableSite() {
  sudo ln -s "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/"
}

disableSite() {
  sudo rm "/etc/nginx/sites-enabled/$1"
}
