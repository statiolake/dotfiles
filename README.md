# dotfiles

設定ファイル用のレポジトリ。

## dockerman

dockerman.py は (環境整備系の) 既存の Dockerfile をビルドするときに一緒に dotfiles も設定してくれるやつ。VSCode の devcontainer がずるいので。

## Dockerfile の使い方

まずは Dockerfile でコンテナをビルドする。

```console
$ docker build . -t dotfiles
```

実行する。例えば Neovim は次のように起動する。

```console
$ docker run -it --rm dotfiles nvim
```

## Docker の Neovim に Neovim-qt から接続する

```console
$ docker run -p 5432:5432 --rm dotfiles nvim --listen 0.0.0.0:5432 --headless
```

として起動しといてから、Windows 側で

```console
> nvim-qt --server 127.0.0.1:5432
```

として勝ち。

## 他の Dockerfile から作成されたコンテナでいい感じに Neovim を使う

この Dockerfile では、`/root/dotfiles` の他、もろもろを VOLUME として公開している。なので、このイメージから作成したコンテナに適当に名前をつけておいて `docker run` や `docker create` コマンドの `--volumes-from` でそのコンテナを指定することで、このコンテナで設定済みの (プラグインや coc extensions がインストールされた) Neovim のディレクトリが見えるようになる。

```console
$ docker create -it \
    --volumes-from dotfiles \
    --name some-container-name \
    image-name
$ docker start -ai some-container-name
```

これで立ち上がったコンテナから Neovim を起動すると (Neovim がインストールされていれば) いい感じに設定されているはず。

ただし Neovim 自体や pynvim はどうしても実行したいコンテナにインストールする必要がある。Dockerfile をそのために編集するのは微妙だし、通常 apt 等のパッケージングソフトウェアがあれば簡単なコマンドですぐインストールできるので、それは `docker run` してから個別にインストールするのがよいかも。
(それでも毎回実行ごとにコマンド打つのは面倒だし、`docker run` でも `--rm` をつけずに実行しといて、なるべくコンテナを維持して使うのがいいかもね。)

.zshrc などはエイリアスなのでボリュームマウントでは自動的にできない。欲しくなる場合はそのコンテナでもう一度 install.py を実行すべし。既に行われているダウンロードやインストール作業はスキップされるので、数秒程度で終わるはず。
