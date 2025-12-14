# language

## go

### mac

```shell
ver="go1.24.11"
which go > /dev/null 2>&1 && echo "go already exists" || (curl -L https://go.dev/dl/$ver.darwin-arm64.tar.gz -o /tmp/go.tar.gz && sudo tar -C /usr/local -xzf /tmp/go.tar.gz && rm /tmp/go.tar.gz)
```

```shell
cat > $HOME/.profile.d/golang.sh << "EOF"
export GOROOT='/usr/local/go'
export GOPATH='/opt/workspace'
export GOPROXY='https://goproxy.io,direct'
export GOSUMDB='off'
export CGO_ENABLED=0
export GO111MODULE='on'

export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF
source $HOME/.zshrc
```

### windows

## python
