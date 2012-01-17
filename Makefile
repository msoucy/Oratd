all: Oratr

Oratr:
	dmd @build.rf

clean:
	rm -rf ./bin
