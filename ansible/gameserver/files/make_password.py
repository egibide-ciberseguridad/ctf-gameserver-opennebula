import sys

from django.contrib.auth.hashers import make_password

password = make_password(sys.argv[1])
pgsql_password = password.replace('$', '\$')

print(pgsql_password, end='')
