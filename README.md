# Ian's dot files

## CentOS, etc

```
sudo yum install -y git docker
sudo docker start
sudo usermod -aG docker <user>
```

Logout and login again

```
git clone https://github.com/ianfinch/dotfiles
cd dotfiles
sudo ./setup.sh
exec bash -l
```

## Debian, etc

```
sudo apt-get git docker
```

## Alpine

```
sudo apk add docker
```
