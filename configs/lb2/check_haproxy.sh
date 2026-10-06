STATE=$(systemctl is-active haproxy)
echo "$(date +%T) - check_haproxy: state=$STATE" >> /var/log/check_haproxy.log
systemctl is-active --quiet haproxy
exit $?
