# alma8-standalone-base

スタンドアローン型のコンテナのベースとなるイメージである。以下に Dockerfile 内の設定について説明する。

## 3行目
```
yum update
```
OSを更新する。マイナー番号も最新となるので、注意が必要である。

## ４行目
```
yum -y install unzip wget lsof telnet bind-utils tar tcpdump vim strace less python3
```
ビルドやデバッグに必要となる標準的なツールをインストールする。

## 5-7行目
```
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
```
docker exec でシェルを実行する際に、ログインしたのと近い状態にする。

## 8行目
```
ENV container docker
```
シャットダウン後に systemd のプロセスを終了するように環境変数を設定する。
https://github.com/systemd/systemd/blob/master/src/basic/virt.c
の detect_container でこの環境変数を検知するが、systemd のソースコードで detect_container を検索すると36個ヒットする。様々な処理の判断で使われているが、そのうちの１個でシャットダウン時の挙動の決定にも使われている。

## 9行目
```
STOPSIGNAL SIGRTMIN+3
```
docker stop でシャットダウンプロセスを実行するようにする。

## 10行目

```
RUN rm -f /lib/systemd/system/sysinit.target.wants/sys-fs-fuse-connections.mount
```

前項でコメントアウトした結果 FUSE Control File System (sys-fs-fuse-connections.mount) が有効になってしまい、起動時に以下のエラーが発生するため、無効化している。このコンテナでは FUSE は利用できない。
```
mount[19]: mount: permission denied
systemd[1]: sys-fs-fuse-connections.mount mount process exited, code=exited status=32
```

## 11行目
docker run のときに -v でホストの同じパスをマウントするボリュームを明示している。docker swarm mode では、 --privledged は使えないため、内部で systemctl を利用するためにはこの /sys/fs/cgroup, /run, および /tmp をマウントすることが必須となる。docker-compose.yml のサンプルを示す。
```
version: "3.4"
services:
  test:
    image: "procube/alma8-standalone-base:latest"
    hostname: "test"
    volumes:
    - /sys/fs/cgroup:/sys/fs/cgroup:ro
    tmpfs:
    - /run
    - /tmp
```

## その他

journalctl では、以下のエラーが出力されているが、docker swarm service として起動する場合は、 --privledged が利用できず、これを止める手段が見つかっていない。
```
systemd-journald.service: Couldn't add fd to fd store: Operation not permitted
```
