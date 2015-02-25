## Dockerfile for KLEE-CL

This repository contains the ``DockerFile`` and other associated files
for building a Docker container for [KLEE-CL](http://www.pcc.me.uk/~peter/klee-fp/).

Running
-------

First obtain the image from the DockerHub. If you don't want to do this see "Building"

```
$ docker pull delcypher/klee-cl-docker
```

Now you can gain access to a shell inside the container (note ``--rm`` removes
the container when you exit it).

```
$ docker run -ti --rm delcypher/klee-cl-docker /bin/bash
```

Building
--------

If you'd rather not used the pre-built image from the [DockerHub](https://registry.hub.docker.com/u/delcypher/klee-cl-docker/)
Then you can build it locally on your system by doing the following.

```
$ cd /path/to/this/repository
$ docker build -t "delcypher/klee-cl-docker" .
