FROM trzeci/emscripten-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y &&\
	apt-get install -y build-essential git autopoint automake libtool pkg-config wget unzip xz-utils libsdl1.2-dev

WORKDIR /
RUN mkdir extralibs

WORKDIR /
RUN git clone https://git.tukaani.org/xz.git &&\
	cd xz &&\
	./autogen.sh &&\
	emconfigure ./configure --prefix=/extralibs --disable-threads --enable-assume-ram=32 &&\
	emmake make -j2 &&\
	emmake make install

WORKDIR /
RUN git clone https://git.code.sf.net/p/libtimidity/libtimidity &&\
	cd libtimidity &&\
	autoreconf -fi &&\
	emconfigure ./configure --prefix=/extralibs --with-timidity-cfg="freepats/freepats.cfg" &&\
	emmake make -j2 &&\
	emmake make install

WORKDIR /
COPY zlib.pc /extralibs/lib/pkgconfig/
RUN touch empty.c &&\
	emcc -s USE_ZLIB=1 empty.c -o /dev/null &&\
	rm empty.c &&\
	cp -r /emsdk_portable/data/.cache/asmjs/ports-builds/zlib/z*.h /extralibs/include/

WORKDIR /baseset

RUN wget https://binaries.openttd.org/extra/opengfx/0.5.5/opengfx-0.5.5-all.zip &&\
	unzip opengfx-0.5.5-all.zip &&\
	tar -xvf opengfx-0.5.5.tar &&\
	mv opengfx-0.5.5/* ./ &&\
	rm -rf opengfx-* *.txt

RUN wget https://binaries.openttd.org/extra/opensfx/0.2.3/opensfx-0.2.3-all.zip &&\
	unzip -j opensfx-0.2.3-all.zip &&\
	rm -rf opensfx-* *.txt

RUN wget https://binaries.openttd.org/extra/openmsx/0.3.1/openmsx-0.3.1-all.zip &&\
	unzip -j openmsx-0.3.1-all.zip &&\
	rm -rf openmsx-* *.txt

WORKDIR /
RUN wget http://freepats.zenvoid.org/freepats-20060219.tar.xz &&\
	tar -xvf freepats-20060219.tar.xz &&\
	rm -rf freepats-*

COPY pre.js /files/
COPY shell.html /files/
COPY openttd.cfg /files/

WORKDIR /workdir/source

CMD ./configure --without-zlib --without-lzo2 --without-sse --without-lzma --without-threads --enable-dedicated &&\
	make -j2 &&\
	emconfigure sh -c 'PKG_CONFIG_PATH=/extralibs/lib/pkgconfig ./configure --without-lzo2 --without-sse --without-threads --with-libtimidity' &&\
	emmake make -j2 &&\
	mkdir -p /workdir/output /workdir/content &&\
	cp bin/openttd /workdir/openttd.bc &&\
	cp -r bin/* /workdir/content/ &&\
	rm /workdir/content/openttd &&\
	cp -r /freepats /workdir/content/ &&\
	cp -r /baseset /workdir/content/ &&\
	cp /files/openttd.cfg /workdir/content/ &&\
	emcc /workdir/openttd.bc -o /workdir/output/index.html -O2 -s "BINARYEN_TRAP_MODE='clamp'" -s USE_SDL=1 -s USE_ZLIB=1 -s STB_IMAGE=1 -s ALLOW_MEMORY_GROWTH=1 \
		--preload-file /workdir/content@/ --pre-js /files/pre.js --shell-file /files/shell.html
