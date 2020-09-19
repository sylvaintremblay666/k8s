run binfmt container:

docker run --rm --privileged docker/binfmt:820fdd95a9972a5308930a2bdfb8573dd4447ad3

docker run --rm --privileged docker/binfmt

docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64

this register arm execs to run on x64 machine, to run once

---

create builder instance:

$ docker buildx create --name mybuilder
$ docker buildx use mybuilder
$ docker buildx inspect --bootstrap

---
create the example (look in ./example folder)


