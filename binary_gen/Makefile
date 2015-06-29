all:
	cd .. && make && cd ./binary_gen
	cd ./osx && ./build.sh && cd ..
	cd ./centos6 && ./build.sh && cd ..
	cd ./centos7 && ./build.sh && cd ..
	cd ./ubuntu1404 && ./build.sh && cd ..
	cd ./ubuntu1504 && ./build.sh && cd ..
	python upload.py


clean:
	find . -name "erln8*.tgz" -exec rm "{}" \;
	find . -name "erln8" -exec rm -rf "{}" \;
