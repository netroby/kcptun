#!/bin/bash
if [ ! -d build ];then
    mkdir build
fi
MD5='md5sum'
unamestr=`uname`
if [[ "$unamestr" == 'Darwin' ]]; then
	MD5='md5'
fi

UPX=false
if hash upx 2>/dev/null; then
	UPX=true
fi

VERSION=`date -u +%Y%m%d`
LDFLAGS="-X main.VERSION=$VERSION -s -w"
GCFLAGS=""

OSES=(linux darwin windows freebsd)
ARCHS=(amd64 386)
for os in ${OSES[@]}; do
	for arch in ${ARCHS[@]}; do
		suffix=""
		if [ "$os" == "windows" ]
		then
			suffix=".exe"
		fi
		env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o build/client_${os}_${arch}${suffix} ./client
		env CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o build/server_${os}_${arch}${suffix} ./server
		if $UPX; then upx -9 build/client_${os}_${arch}${suffix} build/server_${os}_${arch}${suffix};fi
		tar -zcf build/kcptun-${os}-${arch}-$VERSION.tar.gz build/client_${os}_${arch}${suffix} build/server_${os}_${arch}${suffix}
		$MD5 build/kcptun-${os}-${arch}-$VERSION.tar.gz
	done
done

# ARM
ARMS=(5 6 7)
for v in ${ARMS[@]}; do
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o build/client_linux_arm$v  ./client
	env CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v go build -ldflags "$LDFLAGS" -gcflags "$GCFLAGS" -o build/server_linux_arm$v  ./server
done
if $UPX; then upx -9 client_linux_arm* server_linux_arm*;fi
tar -zcf build/kcptun-linux-arm-$VERSION.tar.gz build/client_linux_arm* build/server_linux_arm*
$MD5 build/kcptun-linux-arm-$VERSION.tar.gz
