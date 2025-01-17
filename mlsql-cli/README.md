## Byzer Cli

Command line interface of Byzer-lang

## Build

```
make all
```

## Run

You can run Byzer-lang script like this:

```
byzer run  test.by
```

By default ,it will search config file `.mlsql.config` in current path.

You can also specify the file path with flag `-conf /tmp/.byzer.config`

## .mlsql.config

```
# Engine memory
engine.memory=6048m

# Byzer config
engine.streaming.spark.service=false

# Runtime config
engine.spark.shuffle.spill.batchSize=1000
```



