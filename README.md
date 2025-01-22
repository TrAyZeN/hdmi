# hdmi

## Dependencies
This project uses OSS CAD Suite. You can get a nightly build from
https://github.com/YosysHQ/oss-cad-suite-build.

## Build
```sh
make
openFPGALoader -b tangnano20k build/top.fs
```

## Run tests
```sh
poetry run python tests/test_runner.py
```

## Run formal verification
```sh
make verify
```
