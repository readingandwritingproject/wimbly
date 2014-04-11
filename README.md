wimbly
======

- create user wimbly

        $ sudo useradd wimbly


- add your user accounts to the wimbly group in /etc/group

- create wimbly path

        $ subo mkdir [/var/www]
        $ sudo chown wimbly:wimbly [/var/www]
        $ sudo chmod g+s [/var/www]


- setup SSH keys with github
- test with github connectivity with

        $ ssh -T git@github.com

- clone the wimbly repo to your path

        $ git clone git@github.com:cdrubin/wimbly.git [/var/www]

- follow the instructions in install/ to setup required components
- at a minimum openresty will be needed to host static content and to run wimbly applications luarocks will be required too


